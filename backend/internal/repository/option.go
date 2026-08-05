package repository

import (
	"context"

	"quiz-backend/internal/model"

	"github.com/jmoiron/sqlx"
)

type OptionRepo struct {
	db *sqlx.DB
}

func NewOptionRepo(db *sqlx.DB) *OptionRepo {
	return &OptionRepo{db: db}
}

func (r *OptionRepo) FindByQuestionID(ctx context.Context, questionID string) ([]model.Option, error) {
	var options []model.Option
	err := r.db.SelectContext(ctx, &options, `SELECT id, question_id, text, is_correct, sort_order FROM options WHERE question_id=$1 ORDER BY sort_order`, questionID)
	return options, err
}

func (r *OptionRepo) Create(ctx context.Context, o *model.Option) error {
	return r.create(ctx, r.db, o)
}

func (r *OptionRepo) CreateTx(ctx context.Context, tx *sqlx.Tx, o *model.Option) error {
	return r.create(ctx, tx, o)
}

func (r *OptionRepo) create(ctx context.Context, queryer sqlx.ExtContext, o *model.Option) error {
	query := `INSERT INTO options (question_id, text, is_correct, sort_order) VALUES ($1, $2, $3, $4) RETURNING id`
	return queryer.QueryRowxContext(ctx, query, o.QuestionID, o.Text, o.IsCorrect, o.SortOrder).Scan(&o.ID)
}

func (r *OptionRepo) Update(ctx context.Context, o *model.Option) error {
	query := `UPDATE options SET text=$1, is_correct=$2, sort_order=$3 WHERE id=$4`
	_, err := r.db.ExecContext(ctx, query, o.Text, o.IsCorrect, o.SortOrder, o.ID)
	return err
}

func (r *OptionRepo) Delete(ctx context.Context, id string) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM options WHERE id=$1`, id)
	return err
}

func (r *OptionRepo) DeleteByQuestionID(ctx context.Context, questionID string) error {
	return r.deleteByQuestionID(ctx, r.db, questionID)
}

func (r *OptionRepo) DeleteByQuestionIDTx(ctx context.Context, tx *sqlx.Tx, questionID string) error {
	return r.deleteByQuestionID(ctx, tx, questionID)
}

func (r *OptionRepo) deleteByQuestionID(ctx context.Context, execer sqlx.ExtContext, questionID string) error {
	_, err := execer.ExecContext(ctx, `DELETE FROM options WHERE question_id=$1`, questionID)
	return err
}
