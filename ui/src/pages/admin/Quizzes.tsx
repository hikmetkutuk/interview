import { useCallback, useEffect, useState, type SyntheticEvent } from "react";
import { Link } from "react-router-dom";
import api from "../../api/client";
import type { Quiz, Category } from "../../types";

function buildQuizPayload(form: {
  title: string;
  description: string;
  category_id: string;
  time_limit_seconds: number;
  passing_score: number;
}) {
  if (form.category_id !== "") {
    return form;
  }

  const { category_id: _categoryId, ...payload } = form;
  return payload;
}

export default function AdminQuizzes() {
  const [quizzes, setQuizzes] = useState<Quiz[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<{ open: boolean; edit: Quiz | null }>({
    open: false,
    edit: null,
  });
  const [form, setForm] = useState({
    title: "",
    description: "",
    category_id: "",
    time_limit_seconds: 600,
    passing_score: 60,
  });
  const [saving, setSaving] = useState(false);

  const fetchData = useCallback(() => {
    Promise.all([
      api.get<Quiz[]>("/admin/quizzes"),
      api.get<Category[]>("/admin/categories"),
    ])
      .then(([quizRes, catRes]) => {
        setQuizzes(quizRes.data);
        setCategories(catRes.data);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const openCreate = () => {
    setForm({ title: "", description: "", category_id: "", time_limit_seconds: 600, passing_score: 60 });
    setModal({ open: true, edit: null });
  };

  const openEdit = (q: Quiz) => {
    setForm({
      title: q.title,
      description: q.description,
      category_id: q.category_id,
      time_limit_seconds: q.time_limit_seconds,
      passing_score: q.passing_score,
    });
    setModal({ open: true, edit: q });
  };

  const handleSave = async (e: SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    setSaving(true);
    try {
      const payload = buildQuizPayload(form);
      if (modal.edit) {
        await api.put(`/admin/quizzes/${modal.edit.id}`, payload);
      } else {
        await api.post("/admin/quizzes", payload);
      }
      setModal({ open: false, edit: null });
      fetchData();
    } catch {
      // ignore
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm("Delete this quiz?")) return;
    await api.delete(`/admin/quizzes/${id}`).catch(() => {});
    fetchData();
  };

  if (loading) return <p className="text-gray-500">Loading...</p>;

  const getCategoryName = (id: string) =>
    categories.find((c) => c.id === id)?.name || "—";

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Quizzes</h1>
        <button
          type="button"
          onClick={openCreate}
          className="bg-indigo-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-indigo-700"
        >
          Add Quiz
        </button>
      </div>

      {quizzes.length === 0 ? (
        <p className="text-gray-500">No quizzes yet.</p>
      ) : (
        <div className="bg-white border border-gray-200 rounded-lg overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="text-left px-4 py-3 font-medium text-gray-600">Title</th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">Category</th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">Time</th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">Pass %</th>
                <th className="text-right px-4 py-3 font-medium text-gray-600">Actions</th>
              </tr>
            </thead>
            <tbody>
              {quizzes.map((q) => (
                <tr key={q.id} className="border-t border-gray-100">
                  <td className="px-4 py-3 text-gray-900">{q.title}</td>
                  <td className="px-4 py-3 text-gray-500">{getCategoryName(q.category_id)}</td>
                  <td className="px-4 py-3 text-gray-500">{Math.floor(q.time_limit_seconds / 60)} min</td>
                  <td className="px-4 py-3 text-gray-500">{q.passing_score}%</td>
                  <td className="px-4 py-3 text-right">
                    <Link
                      to={`/admin/quizzes/${q.id}/questions`}
                      className="text-indigo-600 hover:underline mr-3"
                    >
                      Questions
                    </Link>
                    <button
                      type="button"
                      onClick={() => openEdit(q)}
                      className="text-indigo-600 hover:underline mr-3"
                    >
                      Edit
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDelete(q.id)}
                      className="text-red-600 hover:underline"
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {modal.open && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md shadow-lg">
            <h2 className="text-lg font-bold mb-4">
              {modal.edit ? "Edit Quiz" : "New Quiz"}
            </h2>
            <form onSubmit={handleSave} className="flex flex-col gap-4">
              <div>
                <label htmlFor="quiz-title" className="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input
                  id="quiz-title"
                  type="text"
                  value={form.title}
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  required
                />
              </div>
              <div>
                <label htmlFor="quiz-desc" className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <input
                  id="quiz-desc"
                  type="text"
                  value={form.description}
                  onChange={(e) => setForm({ ...form, description: e.target.value })}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label htmlFor="quiz-cat" className="block text-sm font-medium text-gray-700 mb-1">Category</label>
                <select
                  id="quiz-cat"
                  value={form.category_id}
                  onChange={(e) => setForm({ ...form, category_id: e.target.value })}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="">No category</option>
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>
              <div className="flex gap-4">
                <div className="flex-1">
                  <label htmlFor="quiz-time" className="block text-sm font-medium text-gray-700 mb-1">Time (min)</label>
                  <input
                    id="quiz-time"
                    type="number"
                    value={Math.floor(form.time_limit_seconds / 60)}
                    onChange={(e) =>
                      setForm({ ...form, time_limit_seconds: Number(e.target.value) * 60 })
                    }
                    className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
                <div className="flex-1">
                  <label htmlFor="quiz-pass" className="block text-sm font-medium text-gray-700 mb-1">Pass %</label>
                  <input
                    id="quiz-pass"
                    type="number"
                    value={form.passing_score}
                    onChange={(e) =>
                      setForm({ ...form, passing_score: Number(e.target.value) })
                    }
                    className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
              </div>
              <div className="flex justify-end gap-3 mt-2">
                <button
                  type="button"
                  onClick={() => setModal({ open: false, edit: null })}
                  className="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-md"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="px-4 py-2 text-sm font-medium bg-indigo-600 text-white rounded-md hover:bg-indigo-700 disabled:opacity-60"
                >
                  {saving ? "Saving..." : "Save"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
