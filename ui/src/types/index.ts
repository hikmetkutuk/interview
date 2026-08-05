export interface Category {
  id: string;
  name: string;
  slug: string;
  description: string;
  created_at: string;
}

export interface Quiz {
  id: string;
  title: string;
  description: string;
  category_id: string;
  time_limit_seconds: number;
  passing_score: number;
  created_at: string;
}

export interface Option {
  id: string;
  question_id: string;
  text: string;
  is_correct: boolean;
  sort_order: number;
}

export interface Question {
  id: string;
  quiz_id: string;
  type: "mcq" | "maq" | "truefalse";
  text: string;
  image_url: string;
  code_snippet: string;
  score: number;
  sort_order: number;
}

export interface QuestionWithOptions extends Question {
  options: Option[];
}

export interface QuizWithQuestions extends Quiz {
  questions: QuestionWithOptions[];
}

export interface Answer {
  question_id: string;
  selected_option_ids: string[];
}

export interface QuestionResult {
  question: Question;
  user_answers: Option[];
  correct_answers: Option[];
  is_correct: boolean;
  score: number;
}

export interface QuizResult {
  score: number;
  total: number;
  passed: boolean;
  details: QuestionResult[];
}
