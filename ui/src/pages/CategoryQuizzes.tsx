import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowLeft, Clock, Target, Code2, FileQuestion } from "lucide-react";
import api from "../api/client";
import { Card, CardContent } from "../components/ui/Card";
import { Badge } from "../components/ui/Badge";
import { Button } from "../components/ui/Button";
import type { Quiz, Category, CodingProblem } from "../types";

const item = {
  hidden: { opacity: 0, y: 16 },
  show: { opacity: 1, y: 0 },
};

function diffVariant(d: string): "default" | "success" | "destructive" {
  if (d === "easy") return "success";
  if (d === "medium") return "default";
  return "destructive";
}

function SkeletonList() {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
      {[1, 2].map((i) => (<Card key={i} className="animate-pulse"><CardContent className="h-32" /></Card>))}
    </div>
  );
}

function EmptyList() {
  return <Card><CardContent className="text-center py-12 text-muted-foreground">Nothing in this category yet.</CardContent></Card>;
}

function QuizSection({ quizzes }: { readonly quizzes: Quiz[] }) {
  return (
    <section>
      <h2 className="text-lg font-semibold text-foreground mb-3 flex items-center gap-2">
        <FileQuestion className="h-5 w-5 text-primary" /> Quizzes
      </h2>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        {quizzes.map((q, i) => (
          <motion.div key={q.id} variants={item} initial="hidden" animate="show" transition={{ delay: i * 0.05 }}>
            <Link to={`/quiz/${q.id}`}>
              <Card className="group h-full hover:border-primary/50 hover:shadow-md transition-all duration-200 cursor-pointer">
                <CardContent className="flex flex-col justify-between h-full min-h-[130px]">
                  <div>
                    <h3 className="text-lg font-semibold text-foreground group-hover:text-primary transition-colors">{q.title}</h3>
                    {q.description && <p className="text-sm text-muted-foreground mt-1.5 line-clamp-2">{q.description}</p>}
                  </div>
                  <div className="flex items-center gap-3 mt-4">
                    <Badge variant="outline" className="gap-1"><Clock className="h-3 w-3" />{Math.floor(q.time_limit_seconds / 60)}m</Badge>
                    <Badge variant="outline" className="gap-1"><Target className="h-3 w-3" />{q.passing_score}%</Badge>
                  </div>
                </CardContent>
              </Card>
            </Link>
          </motion.div>
        ))}
      </div>
    </section>
  );
}

function CodingSection({ problems }: { readonly problems: CodingProblem[] }) {
  return (
    <section>
      <h2 className="text-lg font-semibold text-foreground mb-3 flex items-center gap-2">
        <Code2 className="h-5 w-5 text-primary" /> Coding Challenges
      </h2>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        {problems.map((p, i) => (
          <motion.div key={p.id} variants={item} initial="hidden" animate="show" transition={{ delay: i * 0.05 }}>
            <Link to={`/coding/${p.id}`}>
              <Card className="group h-full hover:border-primary/50 hover:shadow-md transition-all duration-200 cursor-pointer">
                <CardContent className="flex flex-col justify-between h-full min-h-[110px]">
                  <div>
                    <div className="flex items-center gap-2 mb-1.5">
                      <Badge variant={diffVariant(p.difficulty)} className="text-xs capitalize">{p.difficulty}</Badge>
                    </div>
                    <h3 className="text-lg font-semibold text-foreground group-hover:text-primary transition-colors">{p.title}</h3>
                  </div>
                  <p className="text-xs text-muted-foreground mt-2 flex items-center gap-1"><Code2 className="h-3 w-3" /> Coding problem</p>
                </CardContent>
              </Card>
            </Link>
          </motion.div>
        ))}
      </div>
    </section>
  );
}

export default function CategoryQuizzes() {
  const { id } = useParams<{ id: string }>();
  const [quizzes, setQuizzes] = useState<Quiz[]>([]);
  const [codingProblems, setCodingProblems] = useState<CodingProblem[]>([]);
  const [category, setCategory] = useState<Category | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.get<Quiz[]>(`/quizzes?category_id=${id}`),
      api.get<CodingProblem[]>(`/coding?category_id=${id}`),
      api.get<Category[]>("/categories"),
    ])
      .then(([quizRes, codingRes, catRes]) => {
        setQuizzes(quizRes.data);
        setCodingProblems(codingRes.data);
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
          {quizzes.length + codingProblems.length} item{quizzes.length + codingProblems.length !== 1 ? "s" : ""} available
        </p>
      </motion.div>

      {loading && <SkeletonList />}
      {!loading && quizzes.length === 0 && codingProblems.length === 0 && <EmptyList />}
      {!loading && (quizzes.length > 0 || codingProblems.length > 0) && (
        <div className="flex flex-col gap-8">
          {quizzes.length > 0 && <QuizSection quizzes={quizzes} />}
          {codingProblems.length > 0 && <CodingSection problems={codingProblems} />}
        </div>
      )}
    </div>
  );
}
