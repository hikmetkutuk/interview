import { Link, useLocation, Navigate } from "react-router-dom";
import type { QuizResult } from "../types";

export default function Result() {
  const location = useLocation();
  const result = location.state as QuizResult | null;

  if (!result) {
    return <Navigate to="/" replace />;
  }

  const pct = result.total > 0 ? Math.round((result.score / result.total) * 100) : 0;

  return (
    <div className="max-w-2xl mx-auto">
      <div className={`text-center p-8 rounded-lg mb-8 ${result.passed ? "bg-green-50" : "bg-red-50"}`}>
        <div className={`text-5xl font-bold mb-2 ${result.passed ? "text-green-600" : "text-red-600"}`}>
          {pct}%
        </div>
        <div className={`text-xl font-semibold ${result.passed ? "text-green-700" : "text-red-700"}`}>
          {result.passed ? "You Passed!" : "You Failed"}
        </div>
        <p className="text-gray-600 mt-2">
          {result.score} / {result.total} points
        </p>
      </div>

      <h2 className="text-xl font-bold text-gray-900 mb-4">Review Answers</h2>

      <div className="flex flex-col gap-4">
        {result.details.map((d, i) => (
          <div
            key={d.question.id}
            className={`bg-white border rounded-lg p-5 ${d.is_correct ? "border-green-200" : "border-red-200"}`}
          >
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-gray-500">Question {i + 1}</span>
              <span className={`text-sm font-medium ${d.is_correct ? "text-green-600" : "text-red-600"}`}>
                {d.is_correct ? `+${d.score} pts` : "0 pts"}
              </span>
            </div>

            <p className="text-gray-900 font-medium mb-3">{d.question.text}</p>

            {d.question.code_snippet && (
              <pre className="bg-gray-900 text-green-300 text-sm p-3 rounded-md overflow-x-auto mb-3">
                <code>{d.question.code_snippet}</code>
              </pre>
            )}

            <div className="text-sm space-y-1">
              {d.correct_answers.map((a) => (
                <p key={a.id} className="text-green-700">
                  ✓ {a.text}
                </p>
              ))}
              {d.user_answers
                .filter((a) => !d.correct_answers.some((ca) => ca.id === a.id))
                .map((a) => (
                  <p key={a.id} className="text-red-600 line-through">
                    ✗ {a.text}
                  </p>
                ))}
            </div>
          </div>
        ))}
      </div>

      <div className="text-center mt-8">
        <Link
          to="/"
          className="inline-block px-6 py-2 bg-indigo-600 text-white font-medium rounded-md hover:bg-indigo-700"
        >
          Back to Home
        </Link>
      </div>
    </div>
  );
}
