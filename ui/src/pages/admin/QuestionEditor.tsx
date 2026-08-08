import { useCallback, useEffect, useRef, useState, type SyntheticEvent } from "react";
import { useParams, Link } from "react-router-dom";
import { Trash2 } from "lucide-react";
import api from "../../api/client";
import { ConfirmDialog } from "../../components/ui/ConfirmDialog";
import { Button } from "../../components/ui/Button";
import type { QuestionWithOptions } from "../../types";

interface OptionForm {
  id: string;
  text: string;
  is_correct: boolean;
  match_text: string;
  sort_order: number;
}

let optionIdCounter = 0;
function newOption(text = "", isCorrect = false, sortOrder = 0, matchText = ""): OptionForm {
  return { id: `opt-${++optionIdCounter}`, text, is_correct: isCorrect, match_text: matchText, sort_order: sortOrder };
}

function optionHint(t: string): string {
  if (t === "matching") return "(fill match text for each)";
  if (t === "maq") return "(check correct)";
  return "(select one correct)";
}

function submitButtonLabel(saving: boolean, isEditing: boolean): string {
  if (saving) return "Saving...";
  if (isEditing) return "Update Question";
  return "Add Question";
}

function validateCorrectOptions(questionType: string, options: OptionForm[]): string | null {
  const opts = options || [];
  if (questionType === "matching") {
    const hasPairs = opts.filter((o) => o.match_text !== "").length;
    if (hasPairs < 2) return "Matching questions need at least 2 pairs with Match Text.";
    return null;
  }
  const correctCount = opts.filter((o) => o.is_correct).length;

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
    explanation: "",
    score: 1,
    sort_order: 0,
  });
  const [options, setOptions] = useState<OptionForm[]>([
    newOption("", true, 0),
    newOption("", false, 1),
  ]);
  const [editId, setEditId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [bulkDeleteOpen, setBulkDeleteOpen] = useState(false);
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
    setForm({ type: "mcq", text: "", image_url: "", code_snippet: "", explanation: "", score: 1, sort_order: 0 });
    setOptions([newOption("", true, 0), newOption("", false, 1)]);
    setEditId(null);
  };

  const handleTypeChange = (newType: string) => {
    setForm({ ...form, type: newType });
    if (newType === "truefalse") {
      setOptions([newOption("True", true, 0), newOption("False", false, 1)]);
    } else if (newType === "matching") {
      setOptions([newOption("", false, 0, ""), newOption("", false, 1, "")]);
    } else if (newType === "mcq") {
      setOptions(options.map((o, i) => ({ ...o, is_correct: i === 0, match_text: "" })));
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

  const removeOption = (idx: number) => {
    if (options.length <= 2) return;
    setOptions((options || []).filter((_, i) => i !== idx));
  };

  const handleEdit = (q: QuestionWithOptions) => {
    setForm({
      type: q.type,
      text: q.text,
      image_url: q.image_url,
      code_snippet: q.code_snippet,
      explanation: q.explanation || "",
      score: q.score,
      sort_order: q.sort_order,
    });
    setOptions(
      q.options.length > 0
        ? q.options.map((o) => newOption(o.text, o.is_correct, o.sort_order, o.match_text || ""))
        : [newOption("", true, 0), newOption("", false, 1)]
    );
    setEditId(q.id);
    setTimeout(() => formRef.current?.scrollIntoView({ behavior: "smooth" }), 100);
  };

  const handleSave = async (e: SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    const validationError = validateCorrectOptions(form.type, options);
    if (validationError) {
      setError(validationError);
      return;
    }
    setError("");

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

  const handleDelete = async () => {
    if (!deleteId) return;
    await api.delete(`/admin/questions/${deleteId}`).catch(() => {});
    setDeleteId(null); setSelected((p) => { const n = new Set(p); n.delete(deleteId); return n; }); fetchQuestions();
  };
  const handleBulkDelete = async () => {
    for (const qid of selected) await api.delete(`/admin/questions/${qid}`).catch(() => {});
    setSelected(new Set()); setBulkDeleteOpen(false); fetchQuestions();
  };
  const toggleSelect = (qid: string) => setSelected((p) => { const n = new Set(p); n.has(qid) ? n.delete(qid) : n.add(qid); return n; });
  const toggleAll = () => setSelected(selected.size === questions.length ? new Set() : new Set(questions.map((q) => q.id)));

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
          <div className="flex items-center justify-between mb-2">
            <label className="flex items-center gap-2 text-sm text-muted-foreground cursor-pointer">
              <input type="checkbox" checked={selected.size === questions.length && questions.length > 0} onChange={toggleAll} className="accent-primary" /> Select all ({questions.length})
            </label>
            {selected.size > 0 && (
              <Button variant="destructive" size="sm" onClick={() => setBulkDeleteOpen(true)} className="gap-1.5"><Trash2 className="h-4 w-4" /> Delete ({selected.size})</Button>
            )}
          </div>
          {questions.map((q, i) => (
            <div key={q.id} className="bg-card border border-border rounded-lg p-4 flex items-start gap-3">
              <input type="checkbox" checked={selected.has(q.id)} onChange={() => toggleSelect(q.id)} className="accent-primary mt-1" />
              <div className="flex items-start justify-between flex-1">
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
                    onClick={() => setDeleteId(q.id)}
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
          {error && (
            <div className="bg-destructive/10 border border-destructive/30 text-destructive text-sm rounded-lg px-4 py-3">{error}</div>
          )}
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
                <option value="matching">Matching</option>
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

          <div>
            <label htmlFor="q-explanation" className="block text-sm font-medium text-foreground mb-1">Explanation (shown after answer)</label>
            <textarea id="q-explanation" value={form.explanation} onChange={(e) => setForm({ ...form, explanation: e.target.value })} className="w-full bg-background border border-input rounded-md px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring" rows={2} placeholder="Why this answer is correct..." />
          </div>

          {/* Options */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="text-sm font-medium text-foreground">
                {form.type === "matching" ? "Pairs (left = item, right = match)" : "Options"}{" "}
                <span className="text-xs text-muted-foreground">
                  {optionHint(form.type)}
                </span>
              </label>
              {form.type !== "truefalse" && (
                <button type="button" onClick={() => setOptions([...options, newOption("", false, options.length, "")])} className="text-xs text-primary hover:underline">
                  + Add {form.type === "matching" ? "Pair" : "Option"}
                </button>
              )}
            </div>
            <div className="space-y-2">
              {options.map((opt, i) => (
                <div key={opt.id} className="flex items-center gap-3">
                  {form.type !== "matching" && (
                    <input
                      type={form.type === "maq" ? "checkbox" : "radio"}
                      name="correct-option"
                      checked={opt.is_correct}
                      onChange={() => handleCorrectToggle(i)}
                      className="accent-primary"
                    />
                  )}
                  <input
                    type="text"
                    value={opt.text}
                    onChange={(e) => {
                      const next = [...options];
                      next[i] = { ...next[i], text: e.target.value };
                      setOptions(next);
                    }}
                    placeholder={form.type === "matching" ? `Item ${i + 1}` : `Option ${i + 1}`}
                    className="flex-1 bg-background border border-input rounded-md px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                    required
                  />
                  {form.type === "matching" && (
                    <input
                      type="text"
                      value={opt.match_text}
                      onChange={(e) => {
                        const next = [...options];
                        next[i] = { ...next[i], match_text: e.target.value };
                        setOptions(next);
                      }}
                      placeholder="Match to..."
                      className="flex-1 bg-background border border-input rounded-md px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                      required
                    />
                  )}
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
              className="px-4 py-2 text-sm font-medium bg-primary text-white rounded-md hover:brightness-110 disabled:opacity-60"
            >
              {submitButtonLabel(saving, !!editId)}
            </button>
          </div>
        </form>
      </div>

      <ConfirmDialog open={!!deleteId} title="Delete Question" message="Are you sure?" onConfirm={handleDelete} onCancel={() => setDeleteId(null)} />
      <ConfirmDialog open={bulkDeleteOpen} title={`Delete ${selected.size} Questions`} message="Permanently delete all selected questions?" onConfirm={handleBulkDelete} onCancel={() => setBulkDeleteOpen(false)} />
    </div>
  );
}
