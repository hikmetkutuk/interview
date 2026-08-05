package main

import (
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/cors"

	"quiz-backend/internal/config"
	"quiz-backend/internal/database"
	"quiz-backend/internal/handler"
	"quiz-backend/internal/middleware"
	"quiz-backend/internal/repository"
	"quiz-backend/internal/service"
)

const fallbackJWTSecret = "change-me-in-production"

func main() {
	cfg := config.Load()
	if cfg.JWTSecret == "" || cfg.JWTSecret == fallbackJWTSecret {
		log.Fatal("JWT_SECRET must be set to a non-default value")
	}

	db, err := database.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("database connection failed: %v", err)
	}
	defer db.Close()
	log.Println("connected to database")

	// Repositories
	userRepo := repository.NewUserRepo(db)

	// Services
	authService := service.NewAuthService(userRepo, cfg.JWTSecret)

	// Handlers
	authHandler := handler.NewAuthHandler(authService)

	r := chi.NewRouter()

	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:3000", "http://localhost:5173"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Content-Type", "Authorization"},
		AllowCredentials: true,
	}))

	r.Get("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.Write([]byte("ok"))
	})

	// Auth routes (public)
	r.Route("/api/auth", func(r chi.Router) {
		r.Post("/register", authHandler.Register)
		r.Post("/login", authHandler.Login)
	})

	// Admin routes (protected)
	r.Route("/api/admin", func(r chi.Router) {
		r.Use(middleware.AuthMiddleware(cfg.JWTSecret))
		// Category, Quiz, Question routes will be added in later steps
	})

	log.Printf("listening on :%s", cfg.Port)
	if err := http.ListenAndServe(":"+cfg.Port, r); err != nil {
		log.Fatal(err)
	}
}
