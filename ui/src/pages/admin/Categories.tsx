import { useCallback, useEffect, useState, type SyntheticEvent } from "react";
import { motion } from "framer-motion";
import { Plus, Pencil, Trash2 } from "lucide-react";
import api from "../../api/client";
import { Button } from "../../components/ui/Button";
import { Input } from "../../components/ui/Input";
import { Card, CardContent } from "../../components/ui/Card";
import { ConfirmDialog } from "../../components/ui/ConfirmDialog";
import type { Category } from "../../types";

export default function AdminCategories() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<{ open: boolean; edit: Category | null }>({ open: false, edit: null });
  const [form, setForm] = useState({ name: "", slug: "", description: "" });
  const [saving, setSaving] = useState(false);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
  const [bulkDeleteOpen, setBulkDeleteOpen] = useState(false);

  const fetchCategories = useCallback(() => {
    api.get<Category[]>("/admin/categories")
      .then((res) => setCategories(res.data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { fetchCategories(); }, [fetchCategories]);

  const openCreate = () => {
    setForm({ name: "", slug: "", description: "" });
    setModal({ open: true, edit: null });
  };

  const openEdit = (cat: Category) => {
    setForm({ name: cat.name, slug: cat.slug, description: cat.description });
    setModal({ open: true, edit: cat });
  };

  const handleSave = async (e: SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    setSaving(true);
    try {
      if (modal.edit) await api.put(`/admin/categories/${modal.edit.id}`, form);
      else await api.post("/admin/categories", form);
      setModal({ open: false, edit: null });
      fetchCategories();
    } catch { /* ignore */ } finally { setSaving(false); }
  };

  const handleDelete = async (id: string) => {
    await api.delete(`/admin/categories/${id}`).catch(() => {});
    setDeleteTarget(null);
    setSelected((prev) => { const next = new Set(prev); next.delete(id); return next; });
    fetchCategories();
  };

  const handleBulkDelete = async () => {
    for (const id of selected) await api.delete(`/admin/categories/${id}`).catch(() => {});
    setSelected(new Set()); setBulkDeleteOpen(false); fetchCategories();
  };

  const toggleSelect = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  };

  const toggleAll = () => {
    if (selected.size === categories.length) setSelected(new Set());
    else setSelected(new Set(categories.map((c) => c.id)));
  };

  if (loading) return <p className="text-muted-foreground">Loading...</p>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Categories</h1>
          <p className="text-sm text-muted-foreground mt-1">{categories.length} total</p>
        </div>
        <div className="flex items-center gap-2">
          {selected.size > 0 && (
            <Button variant="destructive" size="sm" onClick={() => setBulkDeleteOpen(true)} className="gap-1.5">
              <Trash2 className="h-4 w-4" /> Delete ({selected.size})
            </Button>
          )}
          <Button onClick={openCreate} className="gap-1.5">
            <Plus className="h-4 w-4" /> Add Category
          </Button>
        </div>
      </div>

      {categories.length === 0 ? (
        <Card><CardContent className="text-center py-12 text-muted-foreground">No categories yet.</CardContent></Card>
      ) : (
        <Card className="overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-muted/50">
              <tr>
                <th className="w-10 px-4 py-3">
                  <input type="checkbox" checked={selected.size === categories.length && categories.length > 0} onChange={toggleAll} className="accent-primary" />
                </th>
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Name</th>
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Slug</th>
                <th className="text-right px-4 py-3 font-medium text-muted-foreground">Actions</th>
              </tr>
            </thead>
            <tbody>
              {categories.map((cat) => (
                <tr key={cat.id} className="border-t border-border">
                  <td className="px-4 py-3">
                    <input type="checkbox" checked={selected.has(cat.id)} onChange={() => toggleSelect(cat.id)} className="accent-primary" />
                  </td>
                  <td className="px-4 py-3 text-foreground font-medium">{cat.name}</td>
                  <td className="px-4 py-3 text-muted-foreground font-mono text-xs">{cat.slug}</td>
                  <td className="px-4 py-3 text-right">
                    <Button variant="ghost" size="sm" onClick={() => openEdit(cat)}><Pencil className="h-3.5 w-3.5" /></Button>
                    <Button variant="ghost" size="sm" onClick={() => setDeleteTarget(cat.id)}><Trash2 className="h-3.5 w-3.5 text-destructive" /></Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}

      {modal.open && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <motion.div initial={{ scale: 0.95 }} animate={{ scale: 1 }} className="w-full max-w-md">
            <Card>
              <CardContent className="p-6">
                <h2 className="text-lg font-bold mb-4">{modal.edit ? "Edit" : "New"} Category</h2>
                <form onSubmit={handleSave} className="flex flex-col gap-4">
                  <div className="space-y-1.5">
                    <label htmlFor="cat-name" className="text-sm font-medium">Name</label>
                    <Input id="cat-name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
                  </div>
                  <div className="space-y-1.5">
                    <label htmlFor="cat-slug" className="text-sm font-medium">Slug</label>
                    <Input id="cat-slug" value={form.slug} onChange={(e) => setForm({ ...form, slug: e.target.value })} required />
                  </div>
                  <div className="space-y-1.5">
                    <label htmlFor="cat-desc" className="text-sm font-medium">Description</label>
                    <Input id="cat-desc" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
                  </div>
                  <div className="flex justify-end gap-3 mt-2">
                    <Button type="button" variant="outline" onClick={() => setModal({ open: false, edit: null })}>Cancel</Button>
                    <Button type="submit" disabled={saving}>{saving ? "Saving..." : "Save"}</Button>
                  </div>
                </form>
              </CardContent>
            </Card>
          </motion.div>
        </div>
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete Category"
        message="Are you sure? This will also delete all quizzes and questions in this category."
        onConfirm={() => deleteTarget && handleDelete(deleteTarget)}
        onCancel={() => setDeleteTarget(null)}
      />
      <ConfirmDialog
        open={bulkDeleteOpen}
        title={`Delete ${selected.size} Categories`}
        message="This will permanently delete all selected categories and their quizzes. Are you sure?"
        onConfirm={handleBulkDelete}
        onCancel={() => setBulkDeleteOpen(false)}
      />
    </div>
  );
}
