package handler

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"quiz-backend/internal/model"
	"quiz-backend/internal/repository"
)

type QuizHandler struct {
	repo *repository.QuizRepo
}

func NewQuizHandler(repo *repository.QuizRepo) *QuizHandler {
	return &QuizHandler{repo: repo}
}

func (h *QuizHandler) List(w http.ResponseWriter, r *http.Request) {
	quizzes, err := h.repo.FindAll(r.Context())
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to fetch quizzes"})
		return
	}
	if quizzes == nil {
		quizzes = []model.Quiz{}
	}
	writeJSON(w, http.StatusOK, quizzes)
}

func (h *QuizHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	q, err := h.repo.FindByID(r.Context(), id)
	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "quiz not found"})
		return
	}
	writeJSON(w, http.StatusOK, q)
}

func (h *QuizHandler) Create(w http.ResponseWriter, r *http.Request) {
	var q model.Quiz
	if err := json.NewDecoder(r.Body).Decode(&q); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid request body"})
		return
	}
	if q.Title == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "title is required"})
		return
	}
	if err := h.repo.Create(r.Context(), &q); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to create quiz"})
		return
	}
	writeJSON(w, http.StatusCreated, q)
}

func (h *QuizHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var q model.Quiz
	if err := json.NewDecoder(r.Body).Decode(&q); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid request body"})
		return
	}
	q.ID = id
	if err := h.repo.Update(r.Context(), &q); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to update quiz"})
		return
	}
	writeJSON(w, http.StatusOK, q)
}

func (h *QuizHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if err := h.repo.Delete(r.Context(), id); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to delete quiz"})
		return
	}
	writeJSON(w, http.StatusNoContent, nil)
}
