package repository

import (
	"context"

	"quiz-backend/internal/model"

	"github.com/jmoiron/sqlx"
)

type QuestionRepo struct {
	db *sqlx.DB
}

func NewQuestionRepo(db *sqlx.DB) *QuestionRepo {
	return &QuestionRepo{db: db}
}

func (r *QuestionRepo) BeginTx(ctx context.Context) (*sqlx.Tx, error) {
	return r.db.BeginTxx(ctx, nil)
}

func (r *QuestionRepo) FindByQuizID(ctx context.Context, quizID string) ([]model.Question, error) {
	var questions []model.Question
	err := r.db.SelectContext(ctx, &questions, `SELECT id, quiz_id, type, text, image_url, code_snippet, explanation, score, sort_order FROM questions WHERE quiz_id=$1 ORDER BY sort_order`, quizID)
	return questions, err
}

func (r *QuestionRepo) FindByID(ctx context.Context, id string) (*model.Question, error) {
	var q model.Question
	err := r.db.GetContext(ctx, &q, `SELECT id, quiz_id, type, text, image_url, code_snippet, explanation, score, sort_order FROM questions WHERE id=$1`, id)
	if err != nil {
		return nil, err
	}
	return &q, nil
}

func (r *QuestionRepo) Create(ctx context.Context, q *model.Question) error {
	query := `INSERT INTO questions (quiz_id, type, text, image_url, code_snippet, explanation, score, sort_order) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id`
	return r.db.QueryRowxContext(ctx, query, q.QuizID, q.Type, q.Text, q.ImageURL, q.CodeSnippet, q.Explanation, q.Score, q.SortOrder).Scan(&q.ID)
}

func (r *QuestionRepo) Update(ctx context.Context, q *model.Question) error {
	return r.update(ctx, r.db, q)
}

func (r *QuestionRepo) UpdateTx(ctx context.Context, tx *sqlx.Tx, q *model.Question) error {
	return r.update(ctx, tx, q)
}

func (r *QuestionRepo) update(ctx context.Context, execer sqlx.ExtContext, q *model.Question) error {
	query := `UPDATE questions SET type=$1, text=$2, image_url=$3, code_snippet=$4, explanation=$5, score=$6, sort_order=$7 WHERE id=$8`
	_, err := execer.ExecContext(ctx, query, q.Type, q.Text, q.ImageURL, q.CodeSnippet, q.Explanation, q.Score, q.SortOrder, q.ID)
	return err
}

func (r *QuestionRepo) Delete(ctx context.Context, id string) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM questions WHERE id=$1`, id)
	return err
}
