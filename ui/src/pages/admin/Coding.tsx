import { useCallback, useEffect, useState, type SyntheticEvent } from "react";
import { motion } from "framer-motion";
import { Plus, Pencil, Trash2 } from "lucide-react";
import Editor from "@monaco-editor/react";
import api from "../../api/client";
import { Button } from "../../components/ui/Button";
import { Input } from "../../components/ui/Input";
import { Card, CardContent } from "../../components/ui/Card";
import { Badge } from "../../components/ui/Badge";
import type { CodingProblem, Category } from "../../types";

interface TCForm {
  id?: string;
  input: string;
  expected_output: string;
  is_hidden: boolean;
  sort_order: number;
  _key: string;
}

let tcKeyCounter = 0;
function newTC(input = "", expected = "", hidden = false, order = 0): TCForm {
  return { input, expected_output: expected, is_hidden: hidden, sort_order: order, _key: `tc-${++tcKeyCounter}` };
}

function saveBtnLabel(saving: boolean, editing: boolean): string {
  if (saving) return "Saving...";
  if (editing) return "Update";
  return "Create";
}

const diffColors: Record<string, "default" | "success" | "destructive"> = {
  easy: "success",
  medium: "default",
  hard: "destructive",
};

export default function AdminCoding() {
  const [problems, setProblems] = useState<CodingProblem[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState<CodingProblem | null>(null);
  const [form, setForm] = useState({
    title: "", description: "", category_id: "", difficulty: "easy", language: "javascript",
    starter_code: "", solution_code: "",
  });
  const [testCases, setTestCases] = useState<TCForm[]>([newTC()]);
  const [saving, setSaving] = useState(false);

  const fetchData = useCallback(() => {
    Promise.all([
      api.get<CodingProblem[]>("/admin/coding"),
      api.get<Category[]>("/admin/categories"),
    ])
      .then(([pRes, cRes]) => { setProblems(pRes.data); setCategories(cRes.data); })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { fetchData(); }, [fetchData]);

  const resetForm = () => {
    setForm({ title: "", description: "", category_id: "", difficulty: "easy", language: "javascript", starter_code: "", solution_code: "" });
    setTestCases([newTC()]);
    setEditing(null);
    setModal(false);
  };

  const openEdit = async (p: CodingProblem) => {
    setForm({
      title: p.title, description: p.description, category_id: p.category_id,
      difficulty: p.difficulty, language: p.language || "javascript", starter_code: p.starter_code, solution_code: (p as any).solution_code || "",
    });
    try {
      const res = await api.get<any>(`/admin/coding/${p.id}`);
      const tcs = res.data.test_cases || [];
      setTestCases(tcs.length > 0 ? tcs.map((tc: any) => newTC(tc.input, tc.expected_output, tc.is_hidden, tc.sort_order)) : [newTC()]);
    } catch {
      setTestCases([newTC()]);
    }
    setEditing(p);
    setModal(true);
  };

  const handleSave = async (e: SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    setSaving(true);
    const payload = { ...form, test_cases: (testCases || []).filter((tc) => tc.expected_output !== "") };
    try {
      if (editing) {
        await api.put(`/admin/coding/${editing.id}`, payload);
      } else {
        await api.post("/admin/coding", payload);
      }
      resetForm();
      fetchData();
    } catch { /* ignore */ } finally { setSaving(false); }
  };

  const handleDelete = async (id: string) => {
    if (!confirm("Delete this coding problem?")) return;
    await api.delete(`/admin/coding/${id}`).catch(() => {});
    fetchData();
  };

  if (loading) return <p className="text-muted-foreground">Loading...</p>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Coding Problems</h1>
          <p className="text-sm text-muted-foreground mt-1">{problems.length} total</p>
        </div>
        <Button onClick={() => { resetForm(); setModal(true); }} className="gap-1.5">
          <Plus className="h-4 w-4" /> Add Problem
        </Button>
      </div>

      {problems.length === 0 ? (
        <Card><CardContent className="text-center py-12 text-muted-foreground">No coding problems yet.</CardContent></Card>
      ) : (
        <Card className="overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-muted/50">
              <tr>
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Title</th>
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Category</th>
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Difficulty</th>
                <th className="text-right px-4 py-3 font-medium text-muted-foreground">Actions</th>
              </tr>
            </thead>
            <tbody>
              {problems.map((p) => (
                <tr key={p.id} className="border-t border-border">
                  <td className="px-4 py-3 text-foreground font-medium">{p.title}</td>
                  <td className="px-4 py-3"><Badge variant="outline">{categories.find((c) => c.id === p.category_id)?.name || "—"}</Badge></td>
                  <td className="px-4 py-3"><Badge variant={diffColors[p.difficulty] || "default"} className="capitalize">{p.difficulty}</Badge></td>
                  <td className="px-4 py-3 text-right">
                    <Button variant="ghost" size="sm" onClick={() => openEdit(p)} aria-label="Edit problem"><Pencil className="h-3.5 w-3.5" /></Button>
                    <Button variant="ghost" size="sm" onClick={() => handleDelete(p.id)} aria-label="Delete problem"><Trash2 className="h-3.5 w-3.5 text-destructive" /></Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}

      {modal && (
        <div className="fixed inset-0 bg-black/50 flex items-start justify-center z-50 p-4 overflow-y-auto">
          <motion.div initial={{ scale: 0.95 }} animate={{ scale: 1 }} className="w-full max-w-3xl my-8">
            <Card>
              <CardContent className="p-6">
                <h2 className="text-lg font-bold mb-4">{editing ? "Edit" : "New"} Coding Problem</h2>
                <form onSubmit={handleSave} className="flex flex-col gap-4">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div className="space-y-1.5">
                      <label htmlFor="cp-title" className="text-sm font-medium">Title</label>
                      <Input id="cp-title" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} required />
                    </div>
                    <div className="space-y-1.5">
                      <label htmlFor="cp-cat" className="text-sm font-medium">Category</label>
                      <select id="cp-cat" value={form.category_id} onChange={(e) => setForm({ ...form, category_id: e.target.value })} className="flex h-10 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">
                        <option value="">No category</option>
                        {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                      </select>
                    </div>
                    <div className="space-y-1.5">
                      <label htmlFor="cp-diff" className="text-sm font-medium">Difficulty</label>
                      <select id="cp-diff" value={form.difficulty} onChange={(e) => setForm({ ...form, difficulty: e.target.value })} className="flex h-10 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">
                        <option value="easy">Easy</option>
                        <option value="medium">Medium</option>
                        <option value="hard">Hard</option>
                      </select>
                    </div>
                    <div className="space-y-1.5">
                      <label htmlFor="cp-lang" className="text-sm font-medium">Language</label>
                      <select id="cp-lang" value={form.language || "javascript"} onChange={(e) => setForm({ ...form, language: e.target.value })} className="flex h-10 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">
                        <option value="javascript">JavaScript</option>
                        <option value="python">Python</option>
                        <option value="go">Go</option>
                        <option value="typescript">TypeScript</option>
                      </select>
                    </div>
                  </div>

                  <div className="space-y-1.5">
                    <label htmlFor="cp-desc" className="text-sm font-medium">Description</label>
                    <textarea id="cp-desc" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} className="flex w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring min-h-[120px] font-mono" required />
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div className="space-y-1.5">
                      <label htmlFor="starter-editor" className="text-sm font-medium">Starter Code</label>
                      <div id="starter-editor" className="border border-input rounded-lg overflow-hidden">
                        <Editor height="180px" language={form.language || "javascript"} value={form.starter_code} onChange={(v) => setForm({ ...form, starter_code: v || "" })} theme="vs-dark" options={{ minimap: { enabled: false }, fontSize: 13 }} />
                      </div>
                    </div>
                    <div className="space-y-1.5">
                      <label htmlFor="solution-editor" className="text-sm font-medium">Solution Code</label>
                      <div id="solution-editor" className="border border-input rounded-lg overflow-hidden">
                        <Editor height="180px" language={form.language || "javascript"} value={form.solution_code} onChange={(v) => setForm({ ...form, solution_code: v || "" })} theme="vs-dark" options={{ minimap: { enabled: false }, fontSize: 13 }} />
                      </div>
                    </div>
                  </div>

                  {/* Test cases */}
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">Test Cases</span>
                      <Button type="button" variant="ghost" size="sm" onClick={() => setTestCases([...testCases, newTC()])}>
                        + Add Test Case
                      </Button>
                    </div>
                    {testCases.map((tc, i) => (
                      <div key={tc._key} className="grid grid-cols-1 sm:grid-cols-5 gap-2 items-start border border-border rounded-lg p-3">
                        <div className="sm:col-span-2 space-y-1">
                          <label htmlFor={`tc-input-${tc._key}`} className="text-xs text-muted-foreground">Input</label>
                          <Input id={`tc-input-${tc._key}`} value={tc.input} onChange={(e) => { const n = [...testCases]; n[i] = { ...n[i], input: e.target.value }; setTestCases(n); }} placeholder="stdin input" />
                        </div>
                        <div className="sm:col-span-2 space-y-1">
                          <label htmlFor={`tc-output-${tc._key}`} className="text-xs text-muted-foreground">Expected Output</label>
                          <Input id={`tc-output-${tc._key}`} value={tc.expected_output} onChange={(e) => { const n = [...testCases]; n[i] = { ...n[i], expected_output: e.target.value }; setTestCases(n); }} placeholder="expected stdout" />
                        </div>
                        <div className="flex items-center gap-2 pt-5">
                          <label className="flex items-center gap-1 text-xs text-muted-foreground">
                            <input type="checkbox" checked={tc.is_hidden} onChange={(e) => { const n = [...testCases]; n[i] = { ...n[i], is_hidden: e.target.checked }; setTestCases(n); }} className="accent-primary" /> Hidden
                          </label>
                          {testCases.length > 1 && (
                            <Button type="button" variant="ghost" size="sm" onClick={() => setTestCases((testCases || []).filter((_, j) => j !== i))} className="text-destructive">✕</Button>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>

                  <div className="flex justify-end gap-3 mt-2">
                    <Button type="button" variant="outline" onClick={resetForm}>Cancel</Button>
                    <Button type="submit" disabled={saving}>{saveBtnLabel(saving, !!editing)}</Button>
                  </div>
                </form>
              </CardContent>
            </Card>
          </motion.div>
        </div>
      )}
    </div>
  );
}
