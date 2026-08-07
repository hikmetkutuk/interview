package model

import "time"

// Database models

type User struct {
	ID           string    `db:"id" json:"id"`
	Username     string    `db:"username" json:"username"`
	PasswordHash string    `db:"password_hash" json:"-"`
	CreatedAt    time.Time `db:"created_at" json:"created_at"`
}

type Category struct {
	ID          string    `db:"id" json:"id"`
	Name        string    `db:"name" json:"name"`
	Slug        string    `db:"slug" json:"slug"`
	Description string    `db:"description" json:"description"`
	CreatedAt   time.Time `db:"created_at" json:"created_at"`
}

type Quiz struct {
	ID               string    `db:"id" json:"id"`
	Title            string    `db:"title" json:"title"`
	Description      string    `db:"description" json:"description"`
	CategoryID       string    `db:"category_id" json:"category_id"`
	TimeLimitSeconds int       `db:"time_limit_seconds" json:"time_limit_seconds"`
	PassingScore     int       `db:"passing_score" json:"passing_score"`
	CreatedAt        time.Time `db:"created_at" json:"created_at"`
}

type Question struct {
	ID          string `db:"id" json:"id"`
	QuizID      string `db:"quiz_id" json:"quiz_id"`
	Type        string `db:"type" json:"type"`
	Text        string `db:"text" json:"text"`
	ImageURL    string `db:"image_url" json:"image_url"`
	CodeSnippet string `db:"code_snippet" json:"code_snippet"`
	Score       int    `db:"score" json:"score"`
	SortOrder   int    `db:"sort_order" json:"sort_order"`
}

type Option struct {
	ID         string `db:"id" json:"id"`
	QuestionID string `db:"question_id" json:"question_id"`
	Text       string `db:"text" json:"text"`
	IsCorrect  bool   `db:"is_correct" json:"is_correct"`
	SortOrder  int    `db:"sort_order" json:"sort_order"`
}

// API request/response types

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type AuthResponse struct {
	Token string `json:"token"`
}

type QuestionWithOptions struct {
	Question
	Options []Option `json:"options"`
}

type QuizWithQuestions struct {
	Quiz
	Questions []QuestionWithOptions `json:"questions"`
}

type Answer struct {
	QuestionID        string   `json:"question_id"`
	SelectedOptionIDs []string `json:"selected_option_ids"`
}

type SubmitRequest struct {
	Answers []Answer `json:"answers"`
}

type QuestionResult struct {
	Question       Question `json:"question"`
	UserAnswers    []Option `json:"user_answers"`
	CorrectAnswers []Option `json:"correct_answers"`
	IsCorrect      bool     `json:"is_correct"`
	Score          int      `json:"score"`
}

type QuizResult struct {
	Score   int              `json:"score"`
	Total   int              `json:"total"`
	Passed  bool             `json:"passed"`
	Details []QuestionResult `json:"details"`
}

// Coding problem models

type CodingProblem struct {
	ID           string `db:"id" json:"id"`
	Title        string `db:"title" json:"title"`
	Description  string `db:"description" json:"description"`
	CategoryID   string `db:"category_id" json:"category_id"`
	Difficulty   string `db:"difficulty" json:"difficulty"`
	StarterCode  string `db:"starter_code" json:"starter_code"`
	SolutionCode string `db:"solution_code" json:"solution_code"`
	CreatedAt    string `db:"created_at" json:"created_at"`
}

type TestCase struct {
	ID               string `db:"id" json:"id"`
	CodingProblemID  string `db:"coding_problem_id" json:"coding_problem_id"`
	Input            string `db:"input" json:"input"`
	ExpectedOutput   string `db:"expected_output" json:"expected_output"`
	IsHidden         bool   `db:"is_hidden" json:"is_hidden"`
	SortOrder        int    `db:"sort_order" json:"sort_order"`
}

type CodingProblemWithTestCases struct {
	CodingProblem
	TestCases []TestCase `json:"test_cases"`
}

type CodeSubmitRequest struct {
	Code     string `json:"code"`
	Language string `json:"language"`
}

type TestCaseResult struct {
	Input          string `json:"input"`
	ExpectedOutput string `json:"expected_output"`
	ActualOutput   string `json:"actual_output"`
	Passed         bool   `json:"passed"`
	IsHidden       bool   `json:"is_hidden"`
}

type CodeSubmitResponse struct {
	Passed  bool              `json:"passed"`
	Results []TestCaseResult  `json:"results"`
}
