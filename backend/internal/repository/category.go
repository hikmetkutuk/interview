package repository

import (
	"context"

	"quiz-backend/internal/model"

	"github.com/jmoiron/sqlx"
)

type CategoryRepo struct {
	db *sqlx.DB
}

func NewCategoryRepo(db *sqlx.DB) *CategoryRepo {
	return &CategoryRepo{db: db}
}

func (r *CategoryRepo) FindAll(ctx context.Context) ([]model.Category, error) {
	var categories []model.Category
	err := r.db.SelectContext(ctx, &categories, `SELECT id, name, slug, description, created_at FROM categories ORDER BY created_at DESC`)
	return categories, err
}

func (r *CategoryRepo) FindByID(ctx context.Context, id string) (*model.Category, error) {
	var c model.Category
	err := r.db.GetContext(ctx, &c, `SELECT id, name, slug, description, created_at FROM categories WHERE id = $1`, id)
	if err != nil {
		return nil, err
	}
	return &c, nil
}

func (r *CategoryRepo) Create(ctx context.Context, c *model.Category) error {
	query := `INSERT INTO categories (name, slug, description) VALUES ($1, $2, $3) RETURNING id, created_at`
	return r.db.QueryRowxContext(ctx, query, c.Name, c.Slug, c.Description).Scan(&c.ID, &c.CreatedAt)
}

func (r *CategoryRepo) Update(ctx context.Context, c *model.Category) error {
	query := `UPDATE categories SET name=$1, slug=$2, description=$3 WHERE id=$4`
	_, err := r.db.ExecContext(ctx, query, c.Name, c.Slug, c.Description, c.ID)
	return err
}

func (r *CategoryRepo) Delete(ctx context.Context, id string) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM categories WHERE id=$1`, id)
	return err
}
