package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

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
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to fetch questions"})
		return
	}
	if questions == nil {
		questions = []model.Question{}
	}

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
		// Strip correct answer info for public API
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
		result = append(result, model.QuestionWithOptions{Question: q, Options: publicOptions})
	}

	quizWithQ := model.QuizWithQuestions{Quiz: *quiz, Questions: result}
	writeJSON(w, http.StatusOK, quizWithQ)
}

// POST /api/quizzes/:id/submit
func (h *PublicHandler) SubmitQuiz(w http.ResponseWriter, r *http.Request) {
	quizID := chi.URLParam(r, "id")

	var req model.SubmitRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid request body"})
		return
	}

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

	userAnswers := buildUserAnswerMap(req.Answers)

	totalScore, maxScore, details, err := h.gradeQuestions(r.Context(), questions, userAnswers)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to grade quiz"})
		return
	}

	result := model.QuizResult{
		Score:   totalScore,
		Total:   maxScore,
		Passed:  quizPassed(totalScore, maxScore, quiz.PassingScore),
		Details: details,
	}

	writeJSON(w, http.StatusOK, result)
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

		score := 0
		if isCorrect {
			score = q.Score
		}

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
	var result []model.Option
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

func optionIsCorrect(options []model.Option, optionID string) bool {
	for _, o := range options {
		if o.ID == optionID && o.IsCorrect {
			return true
		}
	}
	return false
}
