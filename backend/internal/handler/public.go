package handler

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"fmt"
	"log"
	"math/big"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"

	"quiz-backend/internal/model"
	"quiz-backend/internal/repository"
)

type PublicHandler struct {
	categoryRepo *repository.CategoryRepo
	quizRepo     *repository.QuizRepo
	questionRepo *repository.QuestionRepo
	optionRepo   *repository.OptionRepo
}

func NewPublicHandler(
	categoryRepo *repository.CategoryRepo,
	quizRepo *repository.QuizRepo,
	questionRepo *repository.QuestionRepo,
	optionRepo *repository.OptionRepo,
) *PublicHandler {
	return &PublicHandler{
		categoryRepo: categoryRepo,
		quizRepo:     quizRepo,
		questionRepo: questionRepo,
		optionRepo:   optionRepo,
	}
}

// GET /api/categories
func (h *PublicHandler) ListCategories(w http.ResponseWriter, r *http.Request) {
	categories, err := h.categoryRepo.FindAll(r.Context())
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to fetch categories"})
		return
	}
	if categories == nil {
		categories = []model.Category{}
	}
	writeJSON(w, http.StatusOK, categories)
}

// GET /api/quizzes?category_id=X
func (h *PublicHandler) ListQuizzes(w http.ResponseWriter, r *http.Request) {
	categoryID := r.URL.Query().Get("category_id")

	var quizzes []model.Quiz
	var err error

	if categoryID != "" {
		quizzes, err = h.quizRepo.FindByCategory(r.Context(), categoryID)
	} else {
		quizzes, err = h.quizRepo.FindAll(r.Context())
	}

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to fetch quizzes"})
		return
	}
	if quizzes == nil {
		quizzes = []model.Quiz{}
	}
	writeJSON(w, http.StatusOK, quizzes)
}

// GET /api/quizzes/:id
func (h *PublicHandler) GetQuiz(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	quiz, err := h.quizRepo.FindByID(r.Context(), id)
	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "quiz not found"})
		return
	}

	questions, err := h.questionRepo.FindByQuizID(r.Context(), id)
	if err != nil {
		log.Printf("FindByQuizID error: %v", err)
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to fetch questions"})
		return
	}
	if questions == nil {
		questions = []model.Question{}
	}

	questions = selectPerTopic(questions)

	result := make([]model.QuestionWithOptions, 0, len(questions))
	for _, q := range questions {
		options, err := h.optionRepo.FindByQuestionID(r.Context(), q.ID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to fetch options"})
			return
		}
		if options == nil {
			options = []model.Option{}
		}
		publicOptions := publicOptionsForQuestion(q, options)
		result = append(result, model.QuestionWithOptions{Question: q, Options: publicOptions})
	}

	quizWithQ := model.QuizWithQuestions{Quiz: *quiz, Questions: result}
	writeJSON(w, http.StatusOK, quizWithQ)
}

func publicOptionsForQuestion(q model.Question, options []model.Option) []model.Option {
	if q.Type == "matching" {
		return publicMatchingOptions(options)
	}

	publicOptions := make([]model.Option, len(options))
	for i, o := range options {
		publicOptions[i] = model.Option{
			ID:         o.ID,
			QuestionID: o.QuestionID,
			Text:       o.Text,
			IsCorrect:  false,
			SortOrder:  o.SortOrder,
		}
	}
	return publicOptions
}

func publicMatchingOptions(options []model.Option) []model.Option {
	matchValues := shuffledMatchValues(options)
	publicOptions := make([]model.Option, len(options))
	matchIndex := 0

	for i, o := range options {
		publicOptions[i] = model.Option{
			ID:         o.ID,
			QuestionID: o.QuestionID,
			Text:       o.Text,
			IsCorrect:  false,
			SortOrder:  o.SortOrder,
		}
		if o.MatchText != "" && len(matchValues) > 0 {
			publicOptions[i].MatchText = matchValues[matchIndex%len(matchValues)]
			matchIndex++
		}
	}

	return publicOptions
}

func shuffledMatchValues(options []model.Option) []string {
	seen := make(map[string]bool)
	values := make([]string, 0)
	for _, o := range options {
		if o.MatchText == "" || seen[o.MatchText] {
			continue
		}
		seen[o.MatchText] = true
		values = append(values, o.MatchText)
	}

	if len(values) <= 1 {
		return values
	}

	for i := len(values) - 1; i > 0; i-- {
		j, err := rand.Int(rand.Reader, big.NewInt(int64(i+1)))
		if err != nil {
			return append(values[1:], values[0])
		}
		values[i], values[j.Int64()] = values[j.Int64()], values[i]
	}
	return values
}

func shortID(id string) string {
	if len(id) <= 8 {
		return id
	}
	return id[:8]
}

// POST /api/quizzes/:id/submit
func (h *PublicHandler) SubmitQuiz(w http.ResponseWriter, r *http.Request) {
	quizID := chi.URLParam(r, "id")

	var req model.SubmitRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("SubmitQuiz decode error: %v", err)
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid request body"})
		return
	}
	logSubmitAnswers(req)

	quiz, err := h.quizRepo.FindByID(r.Context(), quizID)
	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "quiz not found"})
		return
	}

	questions, err := h.questionRepo.FindByQuizID(r.Context(), quizID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to fetch questions"})
		return
	}

	// Grade only the questions included in the submission (the set shown to the user).
	answeredIDs := make(map[string]bool)
	for _, a := range req.Answers {
		answeredIDs[a.QuestionID] = true
	}
	gradedQuestions := make([]model.Question, 0, len(questions))
	for _, q := range questions {
		if answeredIDs[q.ID] {
			gradedQuestions = append(gradedQuestions, q)
		}
	}

	userAnswers := buildUserAnswerMap(req.Answers)

	totalScore, maxScore, details, err := h.gradeQuestions(r.Context(), gradedQuestions, userAnswers)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to grade quiz"})
		return
	}

	s, ms, mds := h.gradeMatchingQuestions(r.Context(), gradedQuestions, req.Answers)
	totalScore += s
	maxScore += ms
	details = append(details, mds...)

	result := model.QuizResult{
		Score:   totalScore,
		Total:   maxScore,
		Passed:  quizPassed(totalScore, maxScore, quiz.PassingScore),
		Details: details,
	}

	writeJSON(w, http.StatusOK, result)
}

func logSubmitAnswers(req model.SubmitRequest) {
	log.Printf("SubmitQuiz received %d answers", len(req.Answers))
	for i, a := range req.Answers {
		log.Printf("  answer[%d]: qid=%s oids=%v matching=%v", i, shortID(a.QuestionID), a.SelectedOptionIDs, a.MatchingPairs)
	}
}

func (h *PublicHandler) gradeMatchingQuestions(ctx context.Context, questions []model.Question, answers []model.Answer) (int, int, []model.QuestionResult) {
	matchingPairs := buildMatchingMap(answers)
	totalScore, maxScore := 0, 0
	var details []model.QuestionResult

	for _, q := range questions {
		if q.Type != "matching" {
			continue
		}
		options, _ := h.optionRepo.FindByQuestionID(ctx, q.ID)
		if options == nil {
			options = []model.Option{}
		}
		score := gradeMatching(options, matchingPairs[q.ID], q.Score)
		correctOnly := extractMatchingCorrect(options)
		userOnly := extractMatchingUser(options, matchingPairs[q.ID])
		details = append(details, model.QuestionResult{
			Question: q, UserAnswers: userOnly, CorrectAnswers: correctOnly,
			IsCorrect: score == q.Score, Score: score,
		})
		totalScore += score
		maxScore += q.Score
	}
	return totalScore, maxScore, details
}

func extractMatchingCorrect(options []model.Option) []model.Option {
	result := make([]model.Option, 0)
	for _, o := range options {
		if o.MatchText != "" {
			result = append(result, o)
		}
	}
	return result
}

func extractMatchingUser(options []model.Option, pairs [][]string) []model.Option {
	result := make([]model.Option, 0)
	for _, pair := range pairs {
		for _, o := range options {
			if o.ID == pair[0] {
				c := o
				c.MatchText = pair[1]
				result = append(result, c)
				break
			}
		}
	}
	return result
}

func buildUserAnswerMap(answers []model.Answer) map[string]map[string]bool {
	userAnswers := make(map[string]map[string]bool)
	for _, a := range answers {
		set := make(map[string]bool)
		for _, oid := range a.SelectedOptionIDs {
			set[oid] = true
		}
		userAnswers[a.QuestionID] = set
	}
	return userAnswers
}

func (h *PublicHandler) gradeQuestions(ctx context.Context, questions []model.Question, userAnswers map[string]map[string]bool) (int, int, []model.QuestionResult, error) {
	var details []model.QuestionResult
	totalScore := 0
	maxScore := 0

	for _, q := range questions {
		if q.Type == "matching" {
			continue
		}
		options, err := h.optionRepo.FindByQuestionID(ctx, q.ID)
		if err != nil {
			return 0, 0, nil, fmt.Errorf("find options for question %s: %w", q.ID, err)
		}
		if options == nil {
			options = []model.Option{}
		}

		correctOpts := filterCorrectOptions(options)
		userOpts := filterSelectedOptions(options, userAnswers[q.ID])
		isCorrect := checkAnswer(options, correctOpts, userAnswers[q.ID])

		score := calcScore(q.Type, options, correctOpts, userAnswers[q.ID], q.Score)

		details = append(details, model.QuestionResult{
			Question:       q,
			UserAnswers:    userOpts,
			CorrectAnswers: correctOpts,
			IsCorrect:      isCorrect,
			Score:          score,
		})

		totalScore += score
		maxScore += q.Score
	}

	return totalScore, maxScore, details, nil
}

func quizPassed(totalScore, maxScore, passingScore int) bool {
	if maxScore <= 0 {
		return false
	}
	return (float64(totalScore) / float64(maxScore) * 100) >= float64(passingScore)
}

func filterCorrectOptions(options []model.Option) []model.Option {
	var correct []model.Option
	for _, o := range options {
		if o.IsCorrect {
			correct = append(correct, o)
		}
	}
	return correct
}

func filterSelectedOptions(options []model.Option, selected map[string]bool) []model.Option {
	result := make([]model.Option, 0)
	for _, o := range options {
		if selected != nil && selected[o.ID] {
			result = append(result, o)
		}
	}
	return result
}

func checkAnswer(options []model.Option, correctOpts []model.Option, selected map[string]bool) bool {
	if selected == nil {
		return len(correctOpts) == 0
	}

	// All selected must be correct
	for oid := range selected {
		if !optionIsCorrect(options, oid) {
			return false
		}
	}

	// All correct must be selected
	for _, o := range options {
		if o.IsCorrect && !selected[o.ID] {
			return false
		}
	}

	return true
}

func calcScore(qType string, options []model.Option, correctOpts []model.Option, selected map[string]bool, maxScore int) int {
	if qType == "maq" {
		return calcMAQScore(options, correctOpts, selected, maxScore)
	}
	if checkAnswer(options, correctOpts, selected) {
		return maxScore
	}
	return 0
}

func calcMAQScore(options []model.Option, correctOpts []model.Option, selected map[string]bool, maxScore int) int {
	if len(correctOpts) == 0 {
		return 0
	}
	correctSelected := 0
	wrongSelected := 0
	for _, o := range options {
		if selected == nil || !selected[o.ID] {
			continue
		}
		if o.IsCorrect {
			correctSelected++
		} else {
			wrongSelected++
		}
	}
	raw := correctSelected - wrongSelected
	if raw < 0 {
		raw = 0
	}
	score := (raw * maxScore) / len(correctOpts)
	if score > maxScore {
		score = maxScore
	}
	return score
}

func buildMatchingMap(answers []model.Answer) map[string][][]string {
	m := make(map[string][][]string)
	for _, a := range answers {
		if len(a.MatchingPairs) > 0 {
			m[a.QuestionID] = a.MatchingPairs
		}
	}
	return m
}

func gradeMatching(options []model.Option, pairs [][]string, maxScore int) int {
	if len(options) == 0 || len(pairs) == 0 {
		return 0
	}
	// Build correct pair map: left option ID -> right match_text
	correct := make(map[string]string)
	for _, o := range options {
		if o.MatchText != "" {
			correct[o.ID] = o.MatchText
		}
	}
	correctCount := 0
	for _, pair := range pairs {
		if len(pair) != 2 {
			continue
		}
		leftID, userMatch := pair[0], pair[1]
		expectedRight := correct[leftID]
		if expectedRight == "" {
			continue
		}
		if userMatch == expectedRight {
			correctCount++
		}
	}
	if len(correct) == 0 {
		return 0
	}
	return (correctCount * maxScore) / len(correct)
}

func optionIsCorrect(options []model.Option, optionID string) bool {
	for _, o := range options {
		if o.ID == optionID && o.IsCorrect {
			return true
		}
	}
	return false
}

func selectPerTopic(questions []model.Question) []model.Question {
	topicMap := make(map[string][]model.Question)
	for _, q := range questions {
		t := detectTopic(q)
		topicMap[t] = append(topicMap[t], q)
	}
	var result []model.Question
	for _, qs := range topicMap {
		for i := len(qs) - 1; i > 0; i-- {
			jBig, _ := rand.Int(rand.Reader, big.NewInt(int64(i+1)))
			qs[i], qs[jBig.Int64()] = qs[jBig.Int64()], qs[i]
		}
		if len(qs) > 2 {
			qs = qs[:2]
		}
		result = append(result, qs...)
	}
	for i := len(result) - 1; i > 0; i-- {
		jBig, _ := rand.Int(rand.Reader, big.NewInt(int64(i+1)))
		result[i], result[jBig.Int64()] = result[jBig.Int64()], result[i]
	}
	return result
}

var topicByPrefix = map[string]string{
	"di":            "DI / Lifetime",
	"async":         "async/await",
	"generic":       "Generic",
	"delegate":      "Delegate & Event",
	"ienum":         "IEnumerable / IQueryable / IList",
	"exception":     "Exception Handling",
	"valuetype":     "Value Type / Reference Type",
	"gc":            "GC / IDisposable",
	"abstract":      "Abstract / Interface",
	"lambda":        "Lambda / Expression",
	"linq":          "LINQ",
	"middleware":    "Middleware",
	"efcore":        "EF Core",
	"reflection":    "Reflection",
	"extension":     "Extension Methods",
	"record":        "Records / Pattern Matching",
	"nrt":           "Nullable Reference Types",
	"modifiers":     "Access Modifiers",
	"solid":         "SOLID",
	"pattern":       "Tasarım Kalıpları",
	"microservice":  "Microservice",
	"eventual":      "Eventual Consistency",
	"cleanarch":     "Clean Architecture",
	"cqrs":          "CQRS",
	"ddd":           "DDD",
	"apiver":        "API Versioning",
	"resilience":    "Resilience Patterns",
	"caching":       "Caching Strategies",
	"observability": "Observability",
	"ratelimit":     "Rate Limiting",
	"cap":           "CAP Theorem",
	"idempotent":    "Idempotent API",
	"hexagonal":     "Hexagonal Architecture",
	"gateway":       "API Gateway / BFF",
	"distlock":      "Distributed Systems",
	"strangler":     "Strangler Fig",
	"multitenancy":  "Multi-Tenancy",
	"featureflag":   "Feature Flags",
	"healthcheck":   "Health Checks",
	"deployment":    "Deployment",
	"security":      "Security Architecture",
	"sharding":      "Sharding",
	"verticalslice": "Vertical Slice",
}

func detectTopic(q model.Question) string {
	prefix, _, _ := strings.Cut(q.ID, "-")
	if topic, ok := topicByPrefix[prefix]; ok {
		return topic
	}
	return "DI / Lifetime"
}
