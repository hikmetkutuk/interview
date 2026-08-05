package repository

import (
	"context"
	"fmt"
	"strings"

	"quiz-backend/internal/model"

	"github.com/jmoiron/sqlx"
)

type QuizRepo struct {
	db *sqlx.DB
}

func NewQuizRepo(db *sqlx.DB) *QuizRepo {
	return &QuizRepo{db: db}
}

func (r *QuizRepo) FindAll(ctx context.Context) ([]model.Quiz, error) {
	var quizzes []model.Quiz
	err := r.db.SelectContext(ctx, &quizzes, `SELECT id, title, description, COALESCE(category_id::text, '') AS category_id, time_limit_seconds, passing_score, created_at FROM quizzes ORDER BY created_at DESC`)
	return quizzes, err
}

func (r *QuizRepo) FindByCategory(ctx context.Context, categoryID string) ([]model.Quiz, error) {
	var quizzes []model.Quiz
	err := r.db.SelectContext(ctx, &quizzes, `SELECT id, title, description, COALESCE(category_id::text, '') AS category_id, time_limit_seconds, passing_score, created_at FROM quizzes WHERE category_id=$1 ORDER BY created_at DESC`, categoryID)
	return quizzes, err
}

func (r *QuizRepo) FindByID(ctx context.Context, id string) (*model.Quiz, error) {
	var q model.Quiz
	err := r.db.GetContext(ctx, &q, `SELECT id, title, description, COALESCE(category_id::text, '') AS category_id, time_limit_seconds, passing_score, created_at FROM quizzes WHERE id=$1`, id)
	if err != nil {
		return nil, err
	}
	return &q, nil
}

func (r *QuizRepo) Create(ctx context.Context, q *model.Quiz) error {
	columns := []string{"title", "description"}
	placeholders := []string{"$1", "$2"}
	args := []any{q.Title, q.Description}

	addColumn := func(column string, value any) {
		args = append(args, value)
		columns = append(columns, column)
		placeholders = append(placeholders, fmt.Sprintf("$%d", len(args)))
	}

	if q.CategoryID != "" {
		addColumn("category_id", q.CategoryID)
	}
	if q.TimeLimitSeconds != 0 {
		addColumn("time_limit_seconds", q.TimeLimitSeconds)
	}
	if q.PassingScore != 0 {
		addColumn("passing_score", q.PassingScore)
	}

	query := fmt.Sprintf(
		`INSERT INTO quizzes (%s) VALUES (%s) RETURNING id, COALESCE(category_id::text, '') AS category_id, time_limit_seconds, passing_score, created_at`,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "),
	)
	return r.db.QueryRowxContext(ctx, query, args...).Scan(&q.ID, &q.CategoryID, &q.TimeLimitSeconds, &q.PassingScore, &q.CreatedAt)
}

func (r *QuizRepo) Update(ctx context.Context, q *model.Quiz) error {
	query := `UPDATE quizzes SET title=$1, description=$2, category_id=$3, time_limit_seconds=$4, passing_score=$5 WHERE id=$6`
	_, err := r.db.ExecContext(ctx, query, q.Title, q.Description, q.CategoryID, q.TimeLimitSeconds, q.PassingScore, q.ID)
	return err
}

func (r *QuizRepo) Delete(ctx context.Context, id string) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM quizzes WHERE id=$1`, id)
	return err
}
