package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"

	"quiz-backend/internal/model"
	"quiz-backend/internal/repository"
)

var ErrUsernameExists = errors.New("username already exists")

type AuthService struct {
	userRepo  *repository.UserRepo
	jwtSecret []byte
}

func NewAuthService(userRepo *repository.UserRepo, jwtSecret string) *AuthService {
	return &AuthService{
		userRepo:  userRepo,
		jwtSecret: []byte(jwtSecret),
	}
}

func (s *AuthService) Register(ctx context.Context, username, password string) (*model.AuthResponse, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	user := &model.User{
		Username:     username,
		PasswordHash: string(hash),
	}

	if err := s.userRepo.Create(ctx, user); err != nil {
		var pqErr *pq.Error
		if errors.As(err, &pqErr) && pqErr.Code == "23505" {
			return nil, ErrUsernameExists
		}

		return nil, fmt.Errorf("create user: %w", err)
	}

	token, err := s.generateToken(user.ID, user.Username)
	if err != nil {
		return nil, err
	}

	return &model.AuthResponse{Token: token}, nil
}

func (s *AuthService) Login(ctx context.Context, username, password string) (*model.AuthResponse, error) {
	user, err := s.userRepo.FindByUsername(ctx, username)
	if err != nil {
		return nil, errors.New("invalid credentials")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return nil, errors.New("invalid credentials")
	}

	token, err := s.generateToken(user.ID, user.Username)
	if err != nil {
		return nil, err
	}

	return &model.AuthResponse{Token: token}, nil
}

func (s *AuthService) generateToken(userID, username string) (string, error) {
	claims := jwt.MapClaims{
		"sub":      userID,
		"username": username,
		"iat":      time.Now().Unix(),
		"exp":      time.Now().Add(24 * time.Hour).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtSecret)
}
