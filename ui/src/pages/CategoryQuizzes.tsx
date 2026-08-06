import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import api from "../api/client";
import type { Quiz, Category } from "../types";

export default function CategoryQuizzes() {
  const { id } = useParams<{ id: string }>();
  const [quizzes, setQuizzes] = useState<Quiz[]>([]);
  const [category, setCategory] = useState<Category | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.get<Quiz[]>(`/quizzes?category_id=${id}`),
      api.get<Category[]>("/categories"),
    ])
      .then(([quizRes, catRes]) => {
        setQuizzes(quizRes.data);
        setCategory(catRes.data.find((c) => c.id === id) || null);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) {
    return <p className="text-gray-500">Loading quizzes...</p>;
  }

  return (
    <div>
      <Link to="/" className="text-indigo-600 text-sm hover:underline mb-4 inline-block">
        &larr; Back to Categories
      </Link>
      <h1 className="text-3xl font-bold text-gray-900 mb-2">
        {category?.name || "Quizzes"}
      </h1>

      {quizzes.length === 0 ? (
        <p className="text-gray-500 mt-4">No quizzes in this category yet.</p>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-4">
          {quizzes.map((q) => (
            <Link
              key={q.id}
              to={`/quiz/${q.id}`}
              className="block bg-white border border-gray-200 rounded-lg p-5 hover:shadow-md hover:border-indigo-300 transition-all"
            >
              <h2 className="text-lg font-semibold text-gray-900">{q.title}</h2>
              {q.description && (
                <p className="text-sm text-gray-500 mt-1">{q.description}</p>
              )}
              <div className="flex gap-4 mt-3 text-xs text-gray-400">
                <span>{Math.floor(q.time_limit_seconds / 60)} min</span>
                <span>Pass: {q.passing_score}%</span>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
