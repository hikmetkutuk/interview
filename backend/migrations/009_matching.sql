ALTER TABLE options ADD COLUMN IF NOT EXISTS match_text TEXT DEFAULT '';
ALTER TABLE questions DROP CONSTRAINT IF EXISTS questions_type_check;
ALTER TABLE questions ADD CONSTRAINT questions_type_check CHECK (type IN ('mcq', 'maq', 'truefalse', 'matching'));
ALTER TABLE questions ADD COLUMN IF NOT EXISTS explanation TEXT DEFAULT '';
