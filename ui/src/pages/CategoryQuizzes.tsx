import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowLeft, Clock, Target } from "lucide-react";
import api from "../api/client";
import { Card, CardContent } from "../components/ui/Card";
import { Badge } from "../components/ui/Badge";
import { Button } from "../components/ui/Button";
import type { Quiz, Category } from "../types";

const item = {
  hidden: { opacity: 0, y: 16 },
  show: { opacity: 1, y: 0 },
};

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

  return (
    <div>
      <Link to="/">
        <Button variant="ghost" size="sm" className="mb-6 gap-1.5">
          <ArrowLeft className="h-4 w-4" />
          Back to Categories
        </Button>
      </Link>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
      >
        <h1 className="text-3xl font-bold text-foreground mb-2">
          {category?.name || "Quizzes"}
        </h1>
        <p className="text-muted-foreground mb-8">
          {quizzes.length} quiz{quizzes.length !== 1 ? "zes" : ""} available
        </p>
      </motion.div>

      {loading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {[1, 2].map((i) => (
            <Card key={i} className="animate-pulse">
              <CardContent className="h-32" />
            </Card>
          ))}
        </div>
      ) : quizzes.length === 0 ? (
        <Card>
          <CardContent className="text-center py-12 text-muted-foreground">
            No quizzes in this category yet.
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {quizzes.map((q, i) => (
            <motion.div
              key={q.id}
              variants={item}
              initial="hidden"
              animate="show"
              transition={{ delay: i * 0.05 }}
            >
              <Link to={`/quiz/${q.id}`}>
                <Card className="group h-full hover:border-primary/50 hover:shadow-md transition-all duration-200 cursor-pointer">
                  <CardContent className="flex flex-col justify-between h-full min-h-[130px]">
                    <div>
                      <h2 className="text-lg font-semibold text-foreground group-hover:text-primary transition-colors">
                        {q.title}
                      </h2>
                      {q.description && (
                        <p className="text-sm text-muted-foreground mt-1.5 line-clamp-2">
                          {q.description}
                        </p>
                      )}
                    </div>
                    <div className="flex items-center gap-3 mt-4">
                      <Badge variant="outline" className="gap-1">
                        <Clock className="h-3 w-3" />
                        {Math.floor(q.time_limit_seconds / 60)}m
                      </Badge>
                      <Badge variant="outline" className="gap-1">
                        <Target className="h-3 w-3" />
                        {q.passing_score}%
                      </Badge>
                    </div>
                  </CardContent>
                </Card>
              </Link>
            </motion.div>
          ))}
        </div>
      )}
    </div>
  );
}
