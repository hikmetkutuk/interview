package repository

import (
	"context"

	"quiz-backend/internal/model"

	"github.com/jmoiron/sqlx"
)

type UserRepo struct {
	db *sqlx.DB
}

func NewUserRepo(db *sqlx.DB) *UserRepo {
	return &UserRepo{db: db}
}

func (r *UserRepo) Create(ctx context.Context, user *model.User) error {
	query := `INSERT INTO users (username, password_hash) VALUES ($1, $2) RETURNING id, created_at`
	return r.db.QueryRowxContext(ctx, query, user.Username, user.PasswordHash).Scan(&user.ID, &user.CreatedAt)
}

func (r *UserRepo) FindByUsername(ctx context.Context, username string) (*model.User, error) {
	var user model.User
	query := `SELECT id, username, password_hash, created_at FROM users WHERE username = $1`
	err := r.db.GetContext(ctx, &user, query, username)
	if err != nil {
		return nil, err
	}
	return &user, nil
}
