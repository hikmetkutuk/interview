import { useEffect, useState } from "react";
import api from "../../api/client";
import type { Category, Quiz } from "../../types";

export default function AdminDashboard() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [quizzes, setQuizzes] = useState<Quiz[]>([]);

  useEffect(() => {
    Promise.all([
      api.get<Category[]>("/admin/categories"),
      api.get<Quiz[]>("/admin/quizzes"),
    ])
      .then(([catRes, quizRes]) => {
        setCategories(catRes.data);
        setQuizzes(quizRes.data);
      })
      .catch(() => {});
  }, []);

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Dashboard</h1>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white border border-gray-200 rounded-lg p-6">
          <div className="text-3xl font-bold text-indigo-600">{categories.length}</div>
          <div className="text-sm text-gray-500 mt-1">Categories</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-6">
          <div className="text-3xl font-bold text-indigo-600">{quizzes.length}</div>
          <div className="text-sm text-gray-500 mt-1">Quizzes</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-6">
          <div className="text-3xl font-bold text-indigo-600">{quizzes.length}</div>
          <div className="text-sm text-gray-500 mt-1">Total Quizzes</div>
        </div>
      </div>
    </div>
  );
}
