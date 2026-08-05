package handler

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"quiz-backend/internal/model"
	"quiz-backend/internal/repository"
)

type CategoryHandler struct {
	repo *repository.CategoryRepo
}

func NewCategoryHandler(repo *repository.CategoryRepo) *CategoryHandler {
	return &CategoryHandler{repo: repo}
}

func (h *CategoryHandler) List(w http.ResponseWriter, r *http.Request) {
	categories, err := h.repo.FindAll(r.Context())
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to fetch categories"})
		return
	}
	if categories == nil {
		categories = []model.Category{}
	}
	writeJSON(w, http.StatusOK, categories)
}

func (h *CategoryHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	c, err := h.repo.FindByID(r.Context(), id)
	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "category not found"})
		return
	}
	writeJSON(w, http.StatusOK, c)
}

func (h *CategoryHandler) Create(w http.ResponseWriter, r *http.Request) {
	var c model.Category
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid request body"})
		return
	}
	if c.Name == "" || c.Slug == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "name and slug are required"})
		return
	}
	if err := h.repo.Create(r.Context(), &c); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to create category"})
		return
	}
	writeJSON(w, http.StatusCreated, c)
}

func (h *CategoryHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var c model.Category
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid request body"})
		return
	}
	c.ID = id
	if err := h.repo.Update(r.Context(), &c); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to update category"})
		return
	}
	writeJSON(w, http.StatusOK, c)
}

func (h *CategoryHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if err := h.repo.Delete(r.Context(), id); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to delete category"})
		return
	}
	writeJSON(w, http.StatusNoContent, nil)
}
