CREATE TABLE IF NOT EXISTS quizzes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(300) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    time_limit_seconds INT NOT NULL DEFAULT 600,
    passing_score INT NOT NULL DEFAULT 60,
    created_at TIMESTAMP DEFAULT NOW()
);
