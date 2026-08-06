import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowRight, Code2, Globe, Database, Cpu, type LucideIcon } from "lucide-react";
import api from "../api/client";
import { Card, CardContent } from "../components/ui/Card";
import { Badge } from "../components/ui/Badge";
import { Button } from "../components/ui/Button";
import type { Category } from "../types";

const iconMap: Record<string, LucideIcon> = {
  javascript: Code2,
  typescript: Code2,
  python: Cpu,
  go: Cpu,
  sql: Database,
  default: Globe,
};

const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.08 },
  },
};

const item = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0 },
};

export default function Home() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .get<Category[]>("/categories")
      .then((res) => setCategories(res.data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      {/* Hero */}
      <motion.section
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="text-center py-16 md:py-20"
      >
        <Badge variant="default" className="mb-4 text-xs">
          Test your knowledge
        </Badge>
        <h1 className="text-4xl md:text-6xl font-bold tracking-tight text-foreground mb-4">
          Any topic,
          <br />
          <span className="text-primary">one quiz away.</span>
        </h1>
        <p className="text-muted-foreground text-lg max-w-xl mx-auto mb-8">
          Explore curated quizzes across JavaScript, Python, DevOps and more.
          Challenge yourself, track progress, and learn faster.
        </p>
        <div className="flex items-center justify-center gap-3">
          {categories.length > 0 && (
            <Link to={`/category/${categories[0].id}`}>
              <Button size="lg" className="gap-2">
                Start a Quiz
                <ArrowRight className="h-4 w-4" />
              </Button>
            </Link>
          )}
          <Link to="/admin">
            <Button variant="outline" size="lg">
              Create Quiz
            </Button>
          </Link>
        </div>
      </motion.section>

      {/* Categories */}
      <section className="mt-4">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-xl font-semibold text-foreground">
              Categories
            </h2>
            <p className="text-sm text-muted-foreground mt-1">
              Choose a topic to get started
            </p>
          </div>
        </div>

        {loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
            {[1, 2, 3].map((i) => (
              <Card key={i} className="animate-pulse">
                <CardContent className="h-28" />
              </Card>
            ))}
          </div>
        ) : categories.length === 0 ? (
          <Card>
            <CardContent className="text-center py-12">
              <p className="text-muted-foreground">No categories yet. Create one from the admin panel.</p>
            </CardContent>
          </Card>
        ) : (
          <motion.div
            variants={container}
            initial="hidden"
            animate="show"
            className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4"
          >
            {categories.map((cat) => {
              const Icon = iconMap[cat.slug] || iconMap.default;
              return (
                <motion.div key={cat.id} variants={item}>
                  <Link to={`/category/${cat.id}`}>
                    <Card className="group h-full hover:border-primary/50 hover:shadow-md transition-all duration-200 cursor-pointer">
                      <CardContent className="flex flex-col justify-between h-full min-h-[120px]">
                        <div className="flex items-start justify-between">
                          <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center">
                            <Icon className="h-5 w-5 text-primary" />
                          </div>
                          <ArrowRight className="h-4 w-4 text-muted-foreground opacity-0 group-hover:opacity-100 group-hover:translate-x-0.5 transition-all" />
                        </div>
                        <div className="mt-3">
                          <h3 className="font-semibold text-foreground text-base">{cat.name}</h3>
                          {cat.description && (
                            <p className="text-sm text-muted-foreground mt-1 line-clamp-2">
                              {cat.description}
                            </p>
                          )}
                        </div>
                      </CardContent>
                    </Card>
                  </Link>
                </motion.div>
              );
            })}
          </motion.div>
        )}
      </section>
    </div>
  );
}
