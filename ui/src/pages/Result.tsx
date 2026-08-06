import { Link, useLocation, Navigate } from "react-router-dom";
import { motion } from "framer-motion";
import { Trophy, XCircle, CheckCircle2, ArrowLeft, Home, Code2 } from "lucide-react";
import { Card, CardContent } from "../components/ui/Card";
import { Badge } from "../components/ui/Badge";
import { Button } from "../components/ui/Button";
import type { QuizResult } from "../types";

export default function Result() {
  const location = useLocation();
  const result = location.state as QuizResult | null;

  if (!result) return <Navigate to="/" replace />;

  const pct = result.total > 0 ? Math.round((result.score / result.total) * 100) : 0;

  return (
    <div className="max-w-2xl mx-auto">
      {/* Score hero */}
      <motion.div
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ type: "spring", duration: 0.5 }}
      >
        <Card className={`text-center p-8 mb-8 border-2 ${result.passed ? "border-success/30 bg-success/5" : "border-destructive/30 bg-destructive/5"}`}>
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full mb-4 bg-card border-2 border-border">
            {result.passed ? (
              <Trophy className="h-8 w-8 text-primary" />
            ) : (
              <XCircle className="h-8 w-8 text-destructive" />
            )}
          </div>
          <div className={`text-5xl font-bold mb-2 font-mono tracking-tight ${result.passed ? "text-success" : "text-destructive"}`}>
            {pct}%
          </div>
          <Badge variant={result.passed ? "success" : "destructive"} className="text-sm px-3 py-1">
            {result.passed ? "You Passed!" : "You Failed"}
          </Badge>
          <p className="text-muted-foreground mt-3">
            {result.score} / {result.total} points
          </p>
        </Card>
      </motion.div>

      <h2 className="text-xl font-bold text-foreground mb-4">Review Answers</h2>

      <div className="flex flex-col gap-3">
        {result.details.map((d, i) => (
          <motion.div
            key={d.question.id}
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.06 }}
          >
            <Card className={`border-l-4 ${d.is_correct ? "border-l-success" : "border-l-destructive"}`}>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-2">
                  <Badge variant="outline">Q{i + 1}</Badge>
                  <span className={`text-sm font-medium font-mono ${d.is_correct ? "text-success" : "text-destructive"}`}>
                    {d.is_correct ? `+${d.score} pt` : "0 pt"}
                  </span>
                </div>

                <p className="text-foreground font-medium mb-3">{d.question.text}</p>

                {d.question.code_snippet && (
                  <div className="bg-zinc-950 dark:bg-black border border-border rounded-lg mb-3 overflow-hidden">
                    <div className="flex items-center gap-1.5 px-3 py-2 border-b border-border bg-zinc-900">
                      <Code2 className="h-3 w-3 text-muted-foreground" />
                      <span className="text-xs text-muted-foreground font-mono">code</span>
                    </div>
                    <pre className="text-green-400 text-sm p-4 overflow-x-auto font-mono leading-relaxed">
                      <code>{d.question.code_snippet}</code>
                    </pre>
                  </div>
                )}

                <div className="text-sm space-y-1">
                  {d.correct_answers.map((a) => (
                    <div key={a.id} className="flex items-center gap-1.5 text-success">
                      <CheckCircle2 className="h-3.5 w-3.5" />
                      {a.text}
                    </div>
                  ))}
                  {d.user_answers
                    .filter((a) => !d.correct_answers.some((ca) => ca.id === a.id))
                    .map((a) => (
                      <div key={a.id} className="flex items-center gap-1.5 text-destructive line-through">
                        <XCircle className="h-3.5 w-3.5" />
                        {a.text}
                      </div>
                    ))}
                </div>
              </CardContent>
            </Card>
          </motion.div>
        ))}
      </div>

      <div className="flex items-center justify-center gap-3 mt-8">
        <Button variant="outline" onClick={() => window.history.back()} className="gap-1.5">
          <ArrowLeft className="h-4 w-4" /> Back
        </Button>
        <Link to="/">
          <Button className="gap-1.5">
            <Home className="h-4 w-4" /> Home
          </Button>
        </Link>
      </div>
    </div>
  );
}
