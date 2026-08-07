package handler

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"

	"quiz-backend/internal/model"
	"quiz-backend/internal/repository"
)

const errInvalidBody = "invalid request body"

type CodingHandler struct {
	repo *repository.CodingRepo
}

func NewCodingHandler(repo *repository.CodingRepo) *CodingHandler {
	return &CodingHandler{repo: repo}
}

// Admin CRUD

func (h *CodingHandler) List(w http.ResponseWriter, r *http.Request) {
	problems, err := h.repo.FindAll(r.Context())
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to fetch problems"})
		return
	}
	if problems == nil {
		problems = []model.CodingProblem{}
	}
	writeJSON(w, http.StatusOK, problems)
}

func (h *CodingHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	p, err := h.repo.FindByID(r.Context(), id)
	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "problem not found"})
		return
	}
	testCases, _ := h.repo.FindTestCases(r.Context(), id)
	if testCases == nil {
		testCases = []model.TestCase{}
	}
	result := model.CodingProblemWithTestCases{CodingProblem: *p, TestCases: testCases}
	writeJSON(w, http.StatusOK, result)
}

func (h *CodingHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Title        string          `json:"title"`
		Description  string          `json:"description"`
		CategoryID   string          `json:"category_id"`
		Difficulty   string          `json:"difficulty"`
		StarterCode  string          `json:"starter_code"`
		SolutionCode string          `json:"solution_code"`
		TestCases    []model.TestCase `json:"test_cases"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": errInvalidBody})
		return
	}
	if req.Title == "" || req.Description == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "title and description are required"})
		return
	}

	p := &model.CodingProblem{
		Title:        req.Title,
		Description:  req.Description,
		CategoryID:   req.CategoryID,
		Difficulty:   req.Difficulty,
		StarterCode:  req.StarterCode,
		SolutionCode: req.SolutionCode,
	}
	if p.Difficulty == "" {
		p.Difficulty = "easy"
	}
	if err := h.repo.Create(r.Context(), p); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to create problem"})
		return
	}

	for i := range req.TestCases {
		req.TestCases[i].CodingProblemID = p.ID
		if err := h.repo.CreateTestCase(r.Context(), &req.TestCases[i]); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to create test case"})
			return
		}
	}

	testCases, _ := h.repo.FindTestCases(r.Context(), p.ID)
	result := model.CodingProblemWithTestCases{CodingProblem: *p, TestCases: testCases}
	writeJSON(w, http.StatusCreated, result)
}

func (h *CodingHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var req struct {
		Title        string          `json:"title"`
		Description  string          `json:"description"`
		CategoryID   string          `json:"category_id"`
		Difficulty   string          `json:"difficulty"`
		StarterCode  string          `json:"starter_code"`
		SolutionCode string          `json:"solution_code"`
		TestCases    []model.TestCase `json:"test_cases"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": errInvalidBody})
		return
	}

	p := &model.CodingProblem{
		ID:           id,
		Title:        req.Title,
		Description:  req.Description,
		CategoryID:   req.CategoryID,
		Difficulty:   req.Difficulty,
		StarterCode:  req.StarterCode,
		SolutionCode: req.SolutionCode,
	}
	if err := h.repo.Update(r.Context(), p); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to update problem"})
		return
	}

	// Replace test cases
	existing, _ := h.repo.FindTestCases(r.Context(), id)
	for _, tc := range existing {
		_ = h.repo.DeleteTestCase(r.Context(), tc.ID)
	}
	for i := range req.TestCases {
		req.TestCases[i].CodingProblemID = id
		_ = h.repo.CreateTestCase(r.Context(), &req.TestCases[i])
	}

	testCases, _ := h.repo.FindTestCases(r.Context(), id)
	result := model.CodingProblemWithTestCases{CodingProblem: *p, TestCases: testCases}
	writeJSON(w, http.StatusOK, result)
}

func (h *CodingHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if err := h.repo.Delete(r.Context(), id); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to delete problem"})
		return
	}
	writeJSON(w, http.StatusNoContent, nil)
}

// Public: get problem (without solution code)
func (h *CodingHandler) GetPublic(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	p, err := h.repo.FindByID(r.Context(), id)
	if err != nil {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "problem not found"})
		return
	}
	p.SolutionCode = "" // hide solution
	writeJSON(w, http.StatusOK, p)
}

// Public: list by category (without solution code)
func (h *CodingHandler) ListByCategory(w http.ResponseWriter, r *http.Request) {
	categoryID := r.URL.Query().Get("category_id")
	var problems []model.CodingProblem
	var err error

	if categoryID != "" {
		problems, err = h.repo.FindByCategory(r.Context(), categoryID)
	} else {
		problems, err = h.repo.FindAll(r.Context())
	}
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to fetch problems"})
		return
	}
	if problems == nil {
		problems = []model.CodingProblem{}
	}
	for i := range problems {
		problems[i].SolutionCode = ""
	}
	writeJSON(w, http.StatusOK, problems)
}

// Code execution via Piston API
func (h *CodingHandler) RunCode(w http.ResponseWriter, r *http.Request) {
	problemID := chi.URLParam(r, "id")

	var req model.CodeSubmitRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": errInvalidBody})
		return
	}

	testCases, err := h.repo.FindTestCases(r.Context(), problemID)
	if err != nil || len(testCases) == 0 {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "no test cases found"})
		return
	}

	results := make([]model.TestCaseResult, 0, len(testCases))
	allPassed := true

	for _, tc := range testCases {
		actual, err := executeCode(r.Context(), req.Code, req.Language, tc.Input)
		if err != nil {
			results = append(results, model.TestCaseResult{
				Input:   tc.Input,
				ExpectedOutput: tc.ExpectedOutput,
				ActualOutput:   "Error: " + err.Error(),
				Passed:  false,
				IsHidden: tc.IsHidden,
			})
			allPassed = false
			continue
		}

		passed := strings.TrimSpace(actual) == strings.TrimSpace(tc.ExpectedOutput)
		if !passed {
			allPassed = false
		}

		r := model.TestCaseResult{
			Input:   tc.Input,
			ExpectedOutput: tc.ExpectedOutput,
			ActualOutput:   strings.TrimSpace(actual),
			Passed:  passed,
			IsHidden: tc.IsHidden,
		}
		if tc.IsHidden {
			r.Input = "[hidden]"
			r.ExpectedOutput = "[hidden]"
		}
		results = append(results, r)
	}

	writeJSON(w, http.StatusOK, model.CodeSubmitResponse{Passed: allPassed, Results: results})
}

