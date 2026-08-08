package handler

import (
	"database/sql"
	"encoding/json"
	"errors"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"

	"quiz-backend/internal/model"
	"quiz-backend/internal/repository"
)

const errUpdateQuestion = "failed to update question"

type QuestionHandler struct {
	questionRepo *repository.QuestionRepo
	optionRepo   *repository.OptionRepo
}

func NewQuestionHandler(questionRepo *repository.QuestionRepo, optionRepo *repository.OptionRepo) *QuestionHandler {
	return &QuestionHandler{questionRepo: questionRepo, optionRepo: optionRepo}
}

func (h *QuestionHandler) ListByQuiz(w http.ResponseWriter, r *http.Request) {
	quizID := chi.URLParam(r, "quizId")

	questions, err := h.questionRepo.FindByQuizID(r.Context(), quizID)
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
		result = append(result, model.QuestionWithOptions{Question: q, Options: options})
	}

	writeJSON(w, http.StatusOK, result)
}

func (h *QuestionHandler) Create(w http.ResponseWriter, r *http.Request) {
	quizID := chi.URLParam(r, "quizId")

	var req struct {
		Type        string         `json:"type"`
		Text        string         `json:"text"`
		ImageURL    string         `json:"image_url"`
		CodeSnippet string         `json:"code_snippet"`
		Explanation string         `json:"explanation"`
		Score       int            `json:"score"`
		SortOrder   int            `json:"sort_order"`
		Options     []model.Option `json:"options"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid request body"})
		return
	}
	if req.Text == "" || req.Type == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "text and type are required"})
		return
	}

	q := &model.Question{
		QuizID:      quizID,
		Type:        req.Type,
		Text:        req.Text,
		ImageURL:    req.ImageURL,
		CodeSnippet: req.CodeSnippet,
		Explanation: req.Explanation,
		Score:       defaultQuestionScore(req.Score),
		SortOrder:   req.SortOrder,
	}
	if err := h.questionRepo.Create(r.Context(), q); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to create question"})
		return
	}

	for i := range req.Options {
		req.Options[i].QuestionID = q.ID
		if err := h.optionRepo.Create(r.Context(), &req.Options[i]); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to create option"})
			return
		}
	}

	result := model.QuestionWithOptions{Question: *q, Options: req.Options}
	writeJSON(w, http.StatusCreated, result)
}

func (h *QuestionHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var req struct {
		Type        string         `json:"type"`
		Text        string         `json:"text"`
		ImageURL    string         `json:"image_url"`
		CodeSnippet string         `json:"code_snippet"`
		Explanation string         `json:"explanation"`
		Score       int            `json:"score"`
		SortOrder   int            `json:"sort_order"`
		Options     []model.Option `json:"options"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid request body"})
		return
	}

	q := &model.Question{
		ID:          id,
		Type:        req.Type,
		Text:        req.Text,
		ImageURL:    req.ImageURL,
		CodeSnippet: req.CodeSnippet,
		Explanation: req.Explanation,
		Score:       defaultQuestionScore(req.Score),
		SortOrder:   req.SortOrder,
	}

	tx, err := h.questionRepo.BeginTx(r.Context())
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": errUpdateQuestion})
		return
	}

	if err := h.questionRepo.UpdateTx(r.Context(), tx, q); err != nil {
		rollbackTx(tx)
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": errUpdateQuestion})
		return
	}

	// Replace options: delete old, insert new
	if err := h.optionRepo.DeleteByQuestionIDTx(r.Context(), tx, id); err != nil {
		rollbackTx(tx)
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to replace options"})
		return
	}
	for i := range req.Options {
		req.Options[i].QuestionID = id
		if err := h.optionRepo.CreateTx(r.Context(), tx, &req.Options[i]); err != nil {
			rollbackTx(tx)
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to replace options"})
			return
		}
	}

	if err := tx.Commit(); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": errUpdateQuestion})
		return
	}

	options, err := h.optionRepo.FindByQuestionID(r.Context(), id)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to fetch options"})
		return
	}
	if options == nil {
		options = []model.Option{}
	}
	result := model.QuestionWithOptions{Question: *q, Options: options}
	writeJSON(w, http.StatusOK, result)
}

func (h *QuestionHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if err := h.questionRepo.Delete(r.Context(), id); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to delete question"})
		return
	}
	writeJSON(w, http.StatusNoContent, nil)
}

func defaultQuestionScore(score int) int {
	if score == 0 {
		return 1
	}
	return score
}

func rollbackTx(tx interface{ Rollback() error }) {
	if err := tx.Rollback(); err != nil && !errors.Is(err, sql.ErrTxDone) {
		log.Printf("transaction rollback failed: %v", err)
	}
}
