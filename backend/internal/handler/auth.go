package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"quiz-backend/internal/model"
	"quiz-backend/internal/service"
)

type AuthHandler struct {
	authService *service.AuthService
}

func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req model.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid request body"})
		return
	}

	if req.Username == "" || req.Password == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "username and password are required"})
		return
	}

	resp, err := h.authService.Register(r.Context(), req.Username, req.Password)
	if err != nil {
		if errors.Is(err, service.ErrUsernameExists) {
			writeJSON(w, http.StatusConflict, map[string]string{"error": err.Error()})
			return
		}

		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "internal server error"})
		return
	}

	writeJSON(w, http.StatusCreated, resp)
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req model.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid request body"})
		return
	}

	if req.Username == "" || req.Password == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "username and password are required"})
		return
	}

	resp, err := h.authService.Login(r.Context(), req.Username, req.Password)
	if err != nil {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": err.Error()})
		return
	}

	writeJSON(w, http.StatusOK, resp)
}
