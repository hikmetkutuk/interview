package repository

import (
	"context"
	"fmt"
	"strings"

	"quiz-backend/internal/model"

	"github.com/jmoiron/sqlx"
)

type CodingRepo struct {
	db *sqlx.DB
}

func NewCodingRepo(db *sqlx.DB) *CodingRepo {
	return &CodingRepo{db: db}
}

func (r *CodingRepo) FindAll(ctx context.Context) ([]model.CodingProblem, error) {
	var problems []model.CodingProblem
	err := r.db.SelectContext(ctx, &problems, `SELECT id, title, description, COALESCE(category_id::text, '') AS category_id, difficulty, language, starter_code, solution_code, created_at FROM coding_problems ORDER BY created_at DESC`)
	return problems, err
}

func (r *CodingRepo) FindByCategory(ctx context.Context, categoryID string) ([]model.CodingProblem, error) {
	var problems []model.CodingProblem
	err := r.db.SelectContext(ctx, &problems, `SELECT id, title, description, COALESCE(category_id::text, '') AS category_id, difficulty, language, starter_code, solution_code, created_at FROM coding_problems WHERE category_id=$1 ORDER BY created_at DESC`, categoryID)
	return problems, err
}

func (r *CodingRepo) FindByID(ctx context.Context, id string) (*model.CodingProblem, error) {
	var p model.CodingProblem
	err := r.db.GetContext(ctx, &p, `SELECT id, title, description, COALESCE(category_id::text, '') AS category_id, difficulty, language, starter_code, solution_code, created_at FROM coding_problems WHERE id=$1`, id)
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *CodingRepo) Create(ctx context.Context, p *model.CodingProblem) error {
	columns := []string{"title", "description", "difficulty", "language", "starter_code", "solution_code"}
	placeholders := []string{"$1", "$2", "$3", "$4", "$5", "$6"}
	args := []any{p.Title, p.Description, p.Difficulty, p.Language, p.StarterCode, p.SolutionCode}

	addColumn := func(column string, value any) {
		args = append(args, value)
		columns = append(columns, column)
		placeholders = append(placeholders, fmt.Sprintf("$%d", len(args)))
	}

	if p.CategoryID != "" {
		addColumn("category_id", p.CategoryID)
	}

	query := fmt.Sprintf(
		`INSERT INTO coding_problems (%s) VALUES (%s) RETURNING id, COALESCE(category_id::text, '') AS category_id, created_at`,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "),
	)
	return r.db.QueryRowxContext(ctx, query, args...).Scan(&p.ID, &p.CategoryID, &p.CreatedAt)
}

func (r *CodingRepo) Update(ctx context.Context, p *model.CodingProblem) error {
	assignments := []string{"title=$1", "description=$2", "difficulty=$3", "language=$4", "starter_code=$5", "solution_code=$6"}
	args := []any{p.Title, p.Description, p.Difficulty, p.Language, p.StarterCode, p.SolutionCode}

	addAssignment := func(column string, value any) {
		args = append(args, value)
		assignments = append(assignments, fmt.Sprintf("%s=$%d", column, len(args)))
	}

	if p.CategoryID != "" {
		addAssignment("category_id", p.CategoryID)
	}

	args = append(args, p.ID)
	query := fmt.Sprintf(`UPDATE coding_problems SET %s WHERE id=$%d`, strings.Join(assignments, ", "), len(args))
	_, err := r.db.ExecContext(ctx, query, args...)
	return err
}

func (r *CodingRepo) Delete(ctx context.Context, id string) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM coding_problems WHERE id=$1`, id)
	return err
}

// Test cases

func (r *CodingRepo) FindTestCases(ctx context.Context, problemID string) ([]model.TestCase, error) {
	var cases []model.TestCase
	err := r.db.SelectContext(ctx, &cases, `SELECT id, coding_problem_id, input, expected_output, is_hidden, sort_order FROM test_cases WHERE coding_problem_id=$1 ORDER BY sort_order`, problemID)
	return cases, err
}

func (r *CodingRepo) CreateTestCase(ctx context.Context, tc *model.TestCase) error {
	query := `INSERT INTO test_cases (coding_problem_id, input, expected_output, is_hidden, sort_order) VALUES ($1,$2,$3,$4,$5) RETURNING id`
	return r.db.QueryRowxContext(ctx, query, tc.CodingProblemID, tc.Input, tc.ExpectedOutput, tc.IsHidden, tc.SortOrder).Scan(&tc.ID)
}

func (r *CodingRepo) UpdateTestCase(ctx context.Context, tc *model.TestCase) error {
	query := `UPDATE test_cases SET input=$1, expected_output=$2, is_hidden=$3, sort_order=$4 WHERE id=$5`
	_, err := r.db.ExecContext(ctx, query, tc.Input, tc.ExpectedOutput, tc.IsHidden, tc.SortOrder, tc.ID)
	return err
}

func (r *CodingRepo) DeleteTestCase(ctx context.Context, id string) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM test_cases WHERE id=$1`, id)
	return err
}
