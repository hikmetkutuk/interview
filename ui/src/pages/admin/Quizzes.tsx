import { useCallback, useEffect, useState, type SyntheticEvent } from "react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { Plus, Pencil, Trash2, List } from "lucide-react";
import api from "../../api/client";
import { Button } from "../../components/ui/Button";
import { Input } from "../../components/ui/Input";
import { Card, CardContent } from "../../components/ui/Card";
import { Badge } from "../../components/ui/Badge";
import { ConfirmDialog } from "../../components/ui/ConfirmDialog";
import type { Quiz, Category } from "../../types";

function buildQuizPayload(form: { title: string; description: string; category_id: string; time_limit_seconds: number; passing_score: number }) {
  if (form.category_id !== "") return form;
  const { category_id: _, ...payload } = form;
  return payload;
}

export default function AdminQuizzes() {
  const [quizzes, setQuizzes] = useState<Quiz[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<{ open: boolean; edit: Quiz | null }>({ open: false, edit: null });
  const [form, setForm] = useState({ title: "", description: "", category_id: "", time_limit_seconds: 600, passing_score: 60 });
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [bulkDeleteOpen, setBulkDeleteOpen] = useState(false);

  const fetchData = useCallback(() => {
    Promise.all([api.get<Quiz[]>("/admin/quizzes"), api.get<Category[]>("/admin/categories")])
      .then(([qr, cr]) => { setQuizzes(qr.data); setCategories(cr.data); })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { fetchData(); }, [fetchData]);

  const openCreate = () => {
    setForm({ title: "", description: "", category_id: "", time_limit_seconds: 600, passing_score: 60 });
    setModal({ open: true, edit: null });
  };
  const openEdit = (q: Quiz) => {
    setForm({ title: q.title, description: q.description, category_id: q.category_id, time_limit_seconds: q.time_limit_seconds, passing_score: q.passing_score });
    setModal({ open: true, edit: q });
  };
  const handleSave = async (e: SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault(); setSaving(true);
    try {
      const payload = buildQuizPayload(form);
      if (modal.edit) await api.put(`/admin/quizzes/${modal.edit.id}`, payload);
      else await api.post("/admin/quizzes", payload);
      setModal({ open: false, edit: null }); fetchData();
    } catch { } finally { setSaving(false); }
  };
  const handleDelete = async (id: string) => {
    await api.delete(`/admin/quizzes/${id}`).catch(() => {});
    setDeleteTarget(null); setSelected((p) => { const n = new Set(p); n.delete(id); return n; }); fetchData();
  };
  const handleBulkDelete = async () => {
    for (const id of selected) await api.delete(`/admin/quizzes/${id}`).catch(() => {});
    setSelected(new Set()); setBulkDeleteOpen(false); fetchData();
  };
  const toggleSelect = (id: string) => setSelected((p) => { const n = new Set(p); n.has(id) ? n.delete(id) : n.add(id); return n; });
  const toggleAll = () => setSelected(selected.size === quizzes.length ? new Set() : new Set(quizzes.map((q) => q.id)));

  if (loading) return <p className="text-muted-foreground">Loading...</p>;
  const getCategoryName = (id: string) => categories.find((c) => c.id === id)?.name;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div><h1 className="text-2xl font-bold text-foreground">Quizzes</h1><p className="text-sm text-muted-foreground mt-1">{quizzes.length} total</p></div>
        <div className="flex items-center gap-2">
          {selected.size > 0 && <Button variant="destructive" size="sm" onClick={() => setBulkDeleteOpen(true)} className="gap-1.5"><Trash2 className="h-4 w-4" /> Delete ({selected.size})</Button>}
          <Button onClick={openCreate} className="gap-1.5"><Plus className="h-4 w-4" /> Add Quiz</Button>
        </div>
      </div>
      {quizzes.length === 0 ? (
        <Card><CardContent className="text-center py-12 text-muted-foreground">No quizzes yet.</CardContent></Card>
      ) : (
        <Card className="overflow-hidden">
          <table className="w-full text-sm"><thead className="bg-muted/50"><tr>
            <th className="w-10 px-4 py-3"><input type="checkbox" checked={selected.size === quizzes.length && quizzes.length > 0} onChange={toggleAll} className="accent-primary" /></th>
            <th className="text-left px-4 py-3 font-medium text-muted-foreground">Title</th><th className="text-left px-4 py-3 font-medium text-muted-foreground">Category</th><th className="text-left px-4 py-3 font-medium text-muted-foreground">Time</th><th className="text-left px-4 py-3 font-medium text-muted-foreground">Pass</th><th className="text-right px-4 py-3 font-medium text-muted-foreground">Actions</th>
          </tr></thead><tbody>
            {quizzes.map((q) => (
              <tr key={q.id} className="border-t border-border">
                <td className="px-4 py-3"><input type="checkbox" checked={selected.has(q.id)} onChange={() => toggleSelect(q.id)} className="accent-primary" /></td>
                <td className="px-4 py-3 text-foreground font-medium">{q.title}</td>
                <td className="px-4 py-3">{getCategoryName(q.category_id) ? <Badge variant="outline">{getCategoryName(q.category_id)}</Badge> : <span className="text-muted-foreground">—</span>}</td>
                <td className="px-4 py-3 text-muted-foreground font-mono text-xs">{Math.floor(q.time_limit_seconds / 60)}m</td>
                <td className="px-4 py-3 text-muted-foreground font-mono text-xs">{q.passing_score}%</td>
                <td className="px-4 py-3 text-right">
                  <Link to={`/admin/quizzes/${q.id}/questions`}><Button variant="ghost" size="sm" aria-label="Questions"><List className="h-3.5 w-3.5" /></Button></Link>
                  <Button variant="ghost" size="sm" onClick={() => openEdit(q)} aria-label="Edit quiz"><Pencil className="h-3.5 w-3.5" /></Button>
                  <Button variant="ghost" size="sm" onClick={() => setDeleteTarget(q.id)} aria-label="Delete quiz"><Trash2 className="h-3.5 w-3.5 text-destructive" /></Button>
                </td>
              </tr>
            ))}
          </tbody></table>
        </Card>
      )}
      {modal.open && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <motion.div initial={{ scale: 0.95 }} animate={{ scale: 1 }} className="w-full max-w-md"><Card><CardContent className="p-6">
            <h2 className="text-lg font-bold mb-4">{modal.edit ? "Edit" : "New"} Quiz</h2>
            <form onSubmit={handleSave} className="flex flex-col gap-4">
              <div className="space-y-1.5"><label htmlFor="qz-title" className="text-sm font-medium">Title</label><Input id="qz-title" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} required /></div>
              <div className="space-y-1.5"><label htmlFor="qz-desc" className="text-sm font-medium">Description</label><Input id="qz-desc" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></div>
              <div className="space-y-1.5"><label htmlFor="qz-cat" className="text-sm font-medium">Category</label><select id="qz-cat" value={form.category_id} onChange={(e) => setForm({ ...form, category_id: e.target.value })} className="flex h-10 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"><option value="">No category</option>{categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}</select></div>
              <div className="flex gap-4"><div className="flex-1 space-y-1.5"><label htmlFor="qz-time" className="text-sm font-medium">Time (min)</label><Input id="qz-time" type="number" value={Math.floor(form.time_limit_seconds / 60)} onChange={(e) => setForm({ ...form, time_limit_seconds: Number(e.target.value) * 60 })} /></div><div className="flex-1 space-y-1.5"><label htmlFor="qz-pass" className="text-sm font-medium">Pass %</label><Input id="qz-pass" type="number" value={form.passing_score} onChange={(e) => setForm({ ...form, passing_score: Number(e.target.value) })} /></div></div>
              <div className="flex justify-end gap-3 mt-2"><Button type="button" variant="outline" onClick={() => setModal({ open: false, edit: null })}>Cancel</Button><Button type="submit" disabled={saving}>{saving ? "Saving..." : "Save"}</Button></div>
            </form>
          </CardContent></Card></motion.div>
        </div>
      )}
      <ConfirmDialog open={!!deleteTarget} title="Delete Quiz" message="Are you sure?" onConfirm={() => deleteTarget && handleDelete(deleteTarget)} onCancel={() => setDeleteTarget(null)} />
      <ConfirmDialog open={bulkDeleteOpen} title={`Delete ${selected.size} Quizzes`} message="This will permanently delete all selected quizzes and their questions. Are you sure?" onConfirm={handleBulkDelete} onCancel={() => setBulkDeleteOpen(false)} />
    </div>
  );
}
