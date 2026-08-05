CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_id UUID REFERENCES quizzes(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('mcq', 'maq', 'truefalse')),
    text TEXT NOT NULL,
    image_url TEXT,
    code_snippet TEXT,
    score INT NOT NULL DEFAULT 1,
    sort_order INT NOT NULL DEFAULT 0
);
