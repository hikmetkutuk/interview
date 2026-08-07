import { useCallback, useEffect, useRef, useState, type SyntheticEvent } from "react";
import { useParams, Link } from "react-router-dom";
import api from "../../api/client";
import type { QuestionWithOptions } from "../../types";

interface OptionForm {
  id: string;
  text: string;
  is_correct: boolean;
  sort_order: number;
}

let optionIdCounter = 0;
function newOption(text = "", isCorrect = false, sortOrder = 0): OptionForm {
  return { id: `opt-${++optionIdCounter}`, text, is_correct: isCorrect, sort_order: sortOrder };
}

function submitButtonLabel(saving: boolean, isEditing: boolean): string {
  if (saving) return "Saving...";
  if (isEditing) return "Update Question";
  return "Add Question";
}

function validateCorrectOptions(questionType: string, options: OptionForm[]): string | null {
  const correctCount = options.filter((o) => o.is_correct).length;

  if ((questionType === "mcq" || questionType === "truefalse") && correctCount !== 1) {
    return "MCQ and true/false questions must have exactly one correct option.";
  }

  if (questionType === "maq" && correctCount < 1) {
    return "MAQ questions must have at least one correct option.";
  }

  return null;
}

export default function AdminQuestionEditor() {
  const { id } = useParams<{ id: string }>();
  const [questions, setQuestions] = useState<QuestionWithOptions[]>([]);
  const [loading, setLoading] = useState(true);

  const [form, setForm] = useState({
    type: "mcq" as string,
    text: "",
    image_url: "",
    code_snippet: "",
    score: 1,
    sort_order: 0,
  });
  const [options, setOptions] = useState<OptionForm[]>([
    newOption("", true, 0),
    newOption("", false, 1),
  ]);
  const [editId, setEditId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const formRef = useRef<HTMLDivElement>(null);

  const fetchQuestions = useCallback(() => {
    api
      .get<QuestionWithOptions[]>(`/admin/quizzes/${id}/questions`)
      .then((res) => setQuestions(res.data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [id]);

  useEffect(() => {
    fetchQuestions();
  }, [fetchQuestions]);

  const resetForm = () => {
    setForm({ type: "mcq", text: "", image_url: "", code_snippet: "", score: 1, sort_order: 0 });
    setOptions([newOption("", true, 0), newOption("", false, 1)]);
    setEditId(null);
  };

  const handleTypeChange = (newType: string) => {
    setForm({ ...form, type: newType });
    if (newType === "truefalse") {
      setOptions([newOption("True", true, 0), newOption("False", false, 1)]);
    } else if (newType === "mcq") {
      setOptions(options.map((o, i) => ({ ...o, is_correct: i === 0 })));
    } else if (options.length < 2) {
      setOptions([newOption("", true, 0), newOption("", false, 1)]);
    }
  };

  const handleCorrectToggle = (idx: number) => {
    if (form.type === "mcq" || form.type === "truefalse") {
      setOptions(options.map((o, i) => ({ ...o, is_correct: i === idx })));
    } else {
      setOptions(options.map((o, i) => (i === idx ? { ...o, is_correct: !o.is_correct } : o)));
    }
  };

  const addOption = () => {
    setOptions([...options, newOption("", false, options.length)]);
  };

  const removeOption = (idx: number) => {
    if (options.length <= 2) return;
    setOptions(options.filter((_, i) => i !== idx));
  };

  const handleEdit = (q: QuestionWithOptions) => {
    setForm({
      type: q.type,
      text: q.text,
      image_url: q.image_url,
      code_snippet: q.code_snippet,
      score: q.score,
      sort_order: q.sort_order,
    });
    setOptions(
      q.options.length > 0
        ? q.options.map((o) => newOption(o.text, o.is_correct, o.sort_order))
        : [newOption("", true, 0), newOption("", false, 1)]
    );
    setEditId(q.id);
    setTimeout(() => formRef.current?.scrollIntoView({ behavior: "smooth" }), 100);
  };

  const handleSave = async (e: SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    const validationError = validateCorrectOptions(form.type, options);
    if (validationError) {
      alert(validationError);
      return;
    }

    setSaving(true);
    try {
      const payload = { ...form, options };
      if (editId) {
        await api.put(`/admin/questions/${editId}`, payload);
      } else {
        await api.post(`/admin/quizzes/${id}/questions`, payload);
      }
      resetForm();
      fetchQuestions();
    } catch {
      // ignore
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (qId: string) => {
    if (!confirm("Delete this question?")) return;
    await api.delete(`/admin/questions/${qId}`).catch(() => {});
    fetchQuestions();
  };

  if (loading) return <p className="text-muted-foreground">Loading...</p>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <Link to="/admin/quizzes" className="text-primary text-sm hover:underline">
            &larr; Back to Quizzes
          </Link>
          <h1 className="text-2xl font-bold text-foreground mt-1">Questions</h1>
        </div>
      </div>

      {/* Existing questions */}
      {questions.length === 0 ? (
        <p className="text-muted-foreground mb-6">No questions yet.</p>
      ) : (
        <div className="space-y-3 mb-8">
          {questions.map((q, i) => (
            <div key={q.id} className="bg-card border border-border rounded-lg p-4">
              <div className="flex items-start justify-between">
                <div>
                  <span className="text-xs text-muted-foreground bg-muted px-2 py-0.5 rounded mr-2">
                    {q.type.toUpperCase()}
                  </span>
                  <span className="text-sm font-medium text-foreground">
                    {i + 1}. {q.text}
                  </span>
                  <div className="text-xs text-muted-foreground mt-1">
                    {q.options.map((o) => (
                      <span key={o.id} className={o.is_correct ? "text-green-600 mr-2" : "mr-2"}>
                        {o.is_correct ? "✓" : "○"} {o.text}
                      </span>
                    ))}
                  </div>
                </div>
                <div className="flex gap-2 shrink-0">
                  <button
                    type="button"
                    onClick={() => handleEdit(q)}
                    className="text-xs text-primary hover:underline"
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDelete(q.id)}
                    className="text-xs text-red-600 hover:underline"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add/edit form */}
      <div ref={formRef} className="bg-card border border-border rounded-lg p-6">
        <h2 className="text-lg font-bold text-foreground mb-4">{editId ? "Edit Question" : "Add Question"}</h2>
        <form onSubmit={handleSave} className="flex flex-col gap-4">
          <div className="flex gap-4">
            <div>
              <label htmlFor="q-type" className="block text-sm font-medium text-foreground mb-1">Type</label>
              <select
                id="q-type"
                value={form.type}
                onChange={(e) => handleTypeChange(e.target.value)}
                className="bg-background border border-input rounded-md px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              >
                <option value="mcq">MCQ (Single)</option>
                <option value="maq">MAQ (Multiple)</option>
                <option value="truefalse">True/False</option>
              </select>
            </div>
            <div>
              <label htmlFor="q-score" className="block text-sm font-medium text-foreground mb-1">Score</label>
              <input
                id="q-score"
                type="number"
                value={form.score}
                onChange={(e) => setForm({ ...form, score: Number(e.target.value) })}
                className="w-20 bg-background border border-input rounded-md px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
          </div>

          <div>
            <label htmlFor="q-text" className="block text-sm font-medium text-foreground mb-1">Question Text</label>
            <textarea
              id="q-text"
              value={form.text}
              onChange={(e) => setForm({ ...form, text: e.target.value })}
              className="w-full bg-background border border-input rounded-md px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              rows={2}
              required
            />
          </div>

          <div className="flex gap-4">
            <div className="flex-1">
              <label htmlFor="q-image" className="block text-sm font-medium text-foreground mb-1">Image URL (optional)</label>
              <input
                id="q-image"
                type="text"
                value={form.image_url}
                onChange={(e) => setForm({ ...form, image_url: e.target.value })}
                className="w-full bg-background border border-input rounded-md px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div className="flex-1">
              <label htmlFor="q-code" className="block text-sm font-medium text-foreground mb-1">Code Snippet (optional)</label>
              <input
                id="q-code"
                type="text"
                value={form.code_snippet}
                onChange={(e) => setForm({ ...form, code_snippet: e.target.value })}
                className="w-full bg-background border border-input rounded-md px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
          </div>

          {/* Options */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="text-sm font-medium text-foreground">
                Options{" "}
                <span className="text-xs text-muted-foreground">
                  {form.type === "maq" ? "(check correct)" : "(select one correct)"}
                </span>
              </label>
              {form.type !== "truefalse" && (
                <button type="button" onClick={addOption} className="text-xs text-primary hover:underline">
                  + Add Option
                </button>
              )}
            </div>
            <div className="space-y-2">
              {options.map((opt, i) => (
                <div key={opt.id} className="flex items-center gap-3">
                  <input
                    type={form.type === "maq" ? "checkbox" : "radio"}
                    name="correct-option"
                    checked={opt.is_correct}
                    onChange={() => handleCorrectToggle(i)}
                    className="accent-primary"
                  />
                  <input
                    type="text"
                    value={opt.text}
                    onChange={(e) => {
                      const next = [...options];
                      next[i] = { ...next[i], text: e.target.value };
                      setOptions(next);
                    }}
                    placeholder={`Option ${i + 1}`}
                    className="flex-1 bg-background border border-input rounded-md px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                    required
                  />
                  {options.length > 2 && (
                    <button
                      type="button"
                      onClick={() => removeOption(i)}
                      className="text-red-500 text-sm hover:underline"
                    >
                      ✕
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>

          <div className="flex justify-end gap-3 mt-2">
            {editId && (
              <button
                type="button"
                onClick={resetForm}
                className="px-4 py-2 text-sm font-medium text-foreground hover:bg-accent rounded-md"
              >
                Cancel Edit
              </button>
            )}
            <button
              type="submit"
              disabled={saving}
              className="px-4 py-2 text-sm font-medium bg-primary text-white rounded-md hover:bg-indigo-700 disabled:opacity-60"
            >
              {submitButtonLabel(saving, !!editId)}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
