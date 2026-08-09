-- Drop dependent tables
DROP TABLE IF EXISTS options CASCADE;
DROP TABLE IF EXISTS questions CASCADE;

-- Change quizzes PK to VARCHAR (Docker will auto-run this on startup)
-- The quiz UUID becomes a VARCHAR string
ALTER TABLE quizzes ALTER COLUMN id DROP DEFAULT;

-- Recreate questions with VARCHAR id + quiz_id
CREATE TABLE questions (
    id VARCHAR(50) PRIMARY KEY,
    quiz_id VARCHAR(50),
    type VARCHAR(20) NOT NULL CHECK (type IN ('mcq', 'maq', 'truefalse', 'matching')),
    text TEXT NOT NULL,
    image_url TEXT,
    code_snippet TEXT,
    score INT NOT NULL DEFAULT 1,
    sort_order INT NOT NULL DEFAULT 0,
    explanation TEXT DEFAULT ''
);

CREATE TABLE options (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    question_id VARCHAR(50) REFERENCES questions(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL DEFAULT false,
    match_text TEXT DEFAULT '',
    sort_order INT NOT NULL DEFAULT 0
);
