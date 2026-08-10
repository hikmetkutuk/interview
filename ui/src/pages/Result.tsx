import { Link, useLocation, Navigate } from "react-router-dom";
import { motion } from "framer-motion";
import { Trophy, XCircle, CheckCircle2, ArrowLeft, Home, Code2 } from "lucide-react";
import { Card, CardContent } from "../components/ui/Card";
import { Badge } from "../components/ui/Badge";
import { Button } from "../components/ui/Button";
import type { QuizResult, QuestionResult } from "../types";

function scoreBadgeVariant(score: number, max: number): "default" | "success" | "destructive" {
  if (score === max) return "success";
  if (score > 0) return "default";
  return "destructive";
}

function scoreBadgeLabel(score: number, max: number): string {
  if (score === max) return "✓";
  if (score > 0) return `~ ${score}/${max}`;
  return "✗";
}

function AnswerBreakdown({ d }: { readonly d: QuestionResult }) {
  if (d.question.type === "matching") return <MatchingResults d={d} />;
  if (d.question.type === "mcq" || d.question.type === "truefalse") return <SingleChoiceResults d={d} />;
  return <MultipleChoiceResults d={d} />;
}

function MatchingResults({ d }: { readonly d: QuestionResult }) {
  return (
    <div className="text-sm space-y-2">
      {(d.correct_answers || []).filter((a) => a.match_text).map((a) => {
        const userMatch = (d.user_answers || []).find((ua) => ua.id === a.id);
        const isCorrect = userMatch?.match_text === a.match_text;
        return (
          <div key={a.id} className={`flex items-center gap-2 text-sm p-1.5 rounded ${isCorrect ? "bg-success/5" : "bg-destructive/5"}`}>
            {isCorrect ? <CheckCircle2 className="h-3.5 w-3.5 text-success shrink-0" /> : <XCircle className="h-3.5 w-3.5 text-destructive shrink-0" />}
            <span className="text-foreground font-medium w-[130px] shrink-0">{a.text}</span>
            <span className="text-muted-foreground">→</span>
            {userMatch != null ? (
              <span className={isCorrect ? "text-success font-medium" : "text-destructive line-through"}>You: {userMatch.match_text}</span>
            ) : (
              <span className="text-muted-foreground italic text-xs">No answer</span>
            )}
            {!isCorrect && <span className="text-success ml-1">(Correct: {a.match_text})</span>}
          </div>
        );
      })}
    </div>
  );
}

function SingleChoiceResults({ d }: { readonly d: QuestionResult }) {
  return (
    <div className="text-sm space-y-2">
      <div className="flex items-start gap-2">
        <span className="text-xs text-muted-foreground shrink-0">Your answer:</span>
        {(d.user_answers || []).length === 0 ? (
          <span className="text-muted-foreground italic text-xs">No answer</span>
        ) : d.user_answers.map((a) => {
          const isCorrect = (d.correct_answers || []).some((ca) => ca.id === a.id);
          return (
            <div key={a.id} className={`flex items-center gap-1 ${isCorrect ? "text-success" : "text-destructive"}`}>
              {isCorrect ? <CheckCircle2 className="h-3.5 w-3.5" /> : <XCircle className="h-3.5 w-3.5" />}
              <span>{a.text}</span>
            </div>
          );
        })}
      </div>
      <div className="flex items-start gap-2">
        <span className="text-xs text-muted-foreground shrink-0">Correct:</span>
        <div className="flex items-center gap-1 text-success">
          <CheckCircle2 className="h-3.5 w-3.5 shrink-0" />
          <span>{(d.correct_answers || [])[0]?.text}</span>
        </div>
      </div>
    </div>
  );
}

function MultipleChoiceResults({ d }: { readonly d: QuestionResult }) {
  const missed = (d.correct_answers || []).filter((ca) => !(d.user_answers || []).some((ua) => ua.id === ca.id));
  return (
    <div className="text-sm space-y-1">
      <p className="text-xs text-muted-foreground mb-1">Your answers ({d.score}/{d.question.score} pts):</p>
      {(d.user_answers || []).length === 0 && <p className="text-muted-foreground italic text-xs">No answer</p>}
      {(d.user_answers || []).map((a) => {
        const isCorrect = (d.correct_answers || []).some((ca) => ca.id === a.id);
        return (
          <div key={a.id} className={`flex items-center gap-1.5 ${isCorrect ? "text-success" : "text-destructive"}`}>
            {isCorrect ? <CheckCircle2 className="h-3.5 w-3.5" /> : <XCircle className="h-3.5 w-3.5" />}
            {a.text}
          </div>
        );
      })}
      {missed.length > 0 && (
        <>
          <p className="text-xs text-muted-foreground mt-2 mb-1">You missed:</p>
          {missed.map((a) => (
            <div key={a.id} className="flex items-center gap-1.5 text-muted-foreground">
              <CheckCircle2 className="h-3.5 w-3.5" />
              {a.text}
            </div>
          ))}
        </>
      )}
    </div>
  );
}

export default function Result() {
  const location = useLocation();
  const result = location.state as QuizResult | null;

  if (!result) return <Navigate to="/" replace />;

  const pct = result.total > 0 ? Math.round((result.score / result.total) * 100) : 0;

  return (
    <div className="max-w-3xl mx-auto">
      <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} transition={{ type: "spring", duration: 0.5 }}>
        <Card className={`text-center p-8 mb-8 border-2 ${result.passed ? "border-success/30 bg-success/5" : "border-destructive/30 bg-destructive/5"}`}>
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full mb-4 bg-card border-2 border-border">
            {result.passed ? <Trophy className="h-8 w-8 text-primary" /> : <XCircle className="h-8 w-8 text-destructive" />}
          </div>
          <div className={`text-5xl font-bold mb-2 font-mono tracking-tight ${result.passed ? "text-success" : "text-destructive"}`}>{pct}%</div>
          <Badge variant={result.passed ? "success" : "destructive"} className="text-sm px-3 py-1">{result.passed ? "You Passed!" : "You Failed"}</Badge>
          <p className="text-muted-foreground mt-3">{result.score} / {result.total} points</p>
        </Card>
      </motion.div>

      <h2 className="text-xl font-bold text-foreground mb-4">Review Answers</h2>

      <div className="flex flex-col gap-3">
        {result.details.map((d, i) => (
          <motion.div key={d.question.id} initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.06 }}>
            <Card className={`border-l-4 ${d.is_correct ? "border-l-success" : "border-l-destructive"}`}>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-2">
                  <Badge variant={scoreBadgeVariant(d.score, d.question.score)}>{scoreBadgeLabel(d.score, d.question.score)}</Badge>
                  <span className={`text-sm font-medium font-mono ${d.score > 0 ? "text-success" : "text-destructive"}`}>{d.score > 0 ? `+${d.score} pt` : "0 pt"}</span>
                </div>

                <p className="text-foreground font-medium mb-3">{d.question.text}</p>

                {d.question.code_snippet && (
                  <div className="bg-zinc-950 dark:bg-black border border-border rounded-lg mb-3 overflow-hidden">
                    <div className="flex items-center gap-1.5 px-3 py-2 border-b border-border bg-zinc-900">
                      <Code2 className="h-3 w-3 text-muted-foreground" />
                      <span className="text-xs text-muted-foreground font-mono">code</span>
                    </div>
                    <pre className="text-green-400 text-sm p-4 overflow-x-auto font-mono leading-relaxed"><code>{d.question.code_snippet}</code></pre>
                  </div>
                )}

                <AnswerBreakdown d={d} />

                {d.question.explanation && (
                  <div className="mt-3 pt-3 border-t border-border">
                    <p className="text-xs text-muted-foreground mb-1">Explanation:</p>
                    <p className="text-sm text-foreground">{d.question.explanation}</p>
                  </div>
                )}
              </CardContent>
            </Card>
          </motion.div>
        ))}
      </div>

      <div className="flex items-center justify-center gap-3 mt-8">
        <Button variant="outline" onClick={() => window.history.back()} className="gap-1.5"><ArrowLeft className="h-4 w-4" /> Back</Button>
        <Link to="/"><Button className="gap-1.5"><Home className="h-4 w-4" /> Home</Button></Link>
      </div>
    </div>
  );
}
