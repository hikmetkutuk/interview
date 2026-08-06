import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { FolderOpen, FileQuestion, TrendingUp } from "lucide-react";
import api from "../../api/client";
import { Card, CardContent } from "../../components/ui/Card";
import type { Category, Quiz } from "../../types";

const stats = [
  { key: "categories", label: "Categories", icon: FolderOpen },
  { key: "quizzes", label: "Quizzes", icon: FileQuestion },
  { key: "total", label: "Total Quizzes", icon: TrendingUp },
];

const container = {
  hidden: { opacity: 0 },
  show: { opacity: 1, transition: { staggerChildren: 0.08 } },
};

const statItem = {
  hidden: { opacity: 0, y: 16 },
  show: { opacity: 1, y: 0 },
};

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

  const counts: Record<string, number> = {
    categories: categories.length,
    quizzes: quizzes.length,
    total: quizzes.length,
  };

  return (
    <div>
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
      >
        <h1 className="text-2xl font-bold text-foreground mb-2">Dashboard</h1>
        <p className="text-muted-foreground mb-6">Overview of your quiz platform</p>
      </motion.div>

      <motion.div
        variants={container}
        initial="hidden"
        animate="show"
        className="grid grid-cols-1 sm:grid-cols-3 gap-4"
      >
        {stats.map(({ key, label, icon: Icon }) => (
          <motion.div key={key} variants={statItem}>
            <Card className="hover:border-primary/30 transition-colors">
              <CardContent className="flex items-center gap-4 p-5">
                <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center">
                  <Icon className="h-5 w-5 text-primary" />
                </div>
                <div>
                  <div className="text-2xl font-bold text-foreground font-mono">
                    {counts[key]}
                  </div>
                  <div className="text-sm text-muted-foreground">{label}</div>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        ))}
      </motion.div>
    </div>
  );
}
