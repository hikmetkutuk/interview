import { useCallback, useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import api from "../api/client";
import Timer from "../components/Timer";
import QuestionCard from "../components/QuestionCard";
import type { QuizWithQuestions, QuizResult } from "../types";

export default function Quiz() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [quiz, setQuiz] = useState<QuizWithQuestions | null>(null);
  const [loading, setLoading] = useState(true);
  const [currentIdx, setCurrentIdx] = useState(0);
  const [answers, setAnswers] = useState<Record<string, string[]>>({});
  const [submitted, setSubmitted] = useState(false);

  useEffect(() => {
    api.get<QuizWithQuestions>(`/quizzes/${id}`)
      .then((res) => setQuiz(res.data))
      .catch(() => navigate("/"))
      .finally(() => setLoading(false));
  }, [id, navigate]);

  const submitQuiz = useCallback(() => {
    if (submitted || !quiz) return;
    setSubmitted(true);

    const payload = {
      answers: Object.entries(answers).map(([questionId, optionIds]) => ({
        question_id: questionId,
        selected_option_ids: optionIds,
      })),
    };

    api.post<QuizResult>(`/quizzes/${id}/submit`, payload)
      .then((res) => navigate("/result", { state: res.data }))
      .catch(() => setSubmitted(false));
  }, [answers, id, navigate, quiz, submitted]);

  const handleSelect = (optionId: string) => {
    if (!quiz) return;
    const q = quiz.questions[currentIdx];
    if (!q) return;

    setAnswers((prev) => {
      const current = prev[q.id] || [];
      if (q.type === "maq") {
        const next = current.includes(optionId)
          ? current.filter((oid) => oid !== optionId)
          : [...current, optionId];
        return { ...prev, [q.id]: next };
      }
      return { ...prev, [q.id]: [optionId] };
    });
  };

  if (loading || !quiz) {
    return <p className="text-gray-500">Loading quiz...</p>;
  }

  if (quiz.questions.length === 0) {
    return (
      <div className="max-w-2xl mx-auto">
        <button
          type="button"
          onClick={() => navigate(-1)}
          className="mb-4 inline-block text-sm font-medium text-indigo-600 hover:underline"
        >
          &larr; Back
        </button>

        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <h1 className="text-2xl font-bold text-gray-900">{quiz.title}</h1>
          <p className="mt-3 text-gray-600">This quiz has no questions yet.</p>
        </div>
      </div>
    );
  }

  const question = quiz.questions[currentIdx];
  const selectedIds = answers[question.id] || [];

  return (
    <div className="max-w-2xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{quiz.title}</h1>
          <p className="text-sm text-gray-500">{quiz.questions.length} questions</p>
        </div>
        <Timer seconds={quiz.time_limit_seconds} onExpire={submitQuiz} />
      </div>

      <QuestionCard
        question={question}
        options={question.options}
        selectedIds={selectedIds}
        onSelect={handleSelect}
        questionIndex={currentIdx}
        totalQuestions={quiz.questions.length}
      />

      <div className="flex justify-between mt-6">
        <button
          type="button"
          onClick={() => setCurrentIdx((i) => i - 1)}
          disabled={currentIdx === 0}
          className="px-4 py-2 text-sm font-medium rounded-md border border-gray-300 text-gray-700 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          Previous
        </button>

        {currentIdx < quiz.questions.length - 1 ? (
          <button
            type="button"
            onClick={() => setCurrentIdx((i) => i + 1)}
            className="px-4 py-2 text-sm font-medium rounded-md bg-indigo-600 text-white hover:bg-indigo-700"
          >
            Next
          </button>
        ) : (
          <button
            type="button"
            onClick={submitQuiz}
            disabled={submitted}
            className="px-6 py-2 text-sm font-medium rounded-md bg-green-600 text-white hover:bg-green-700 disabled:opacity-60"
          >
            {submitted ? "Submitting..." : "Submit Quiz"}
          </button>
        )}
      </div>
    </div>
  );
}
