import { useEffect, useRef, useState } from "react";
import { useParams, Link } from "react-router-dom";
import Editor from "@monaco-editor/react";
import { motion } from "framer-motion";
import { ArrowLeft, Play, CheckCircle2, XCircle } from "lucide-react";
import api from "../api/client";
import { Card, CardContent } from "../components/ui/Card";
import { Badge } from "../components/ui/Badge";
import { Button } from "../components/ui/Button";
import type { CodingProblem, TestCaseResult } from "../types";

const difficultyColors: Record<string, "default" | "success" | "destructive"> = {
  easy: "success",
  medium: "default",
  hard: "destructive",
};

export default function CodingProblemPage() {
  const { id } = useParams<{ id: string }>();
  const [problem, setProblem] = useState<CodingProblem | null>(null);
  const [loading, setLoading] = useState(true);
  const [code, setCode] = useState("");
  const [running, setRunning] = useState(false);
  const [results, setResults] = useState<(TestCaseResult & { _key: string })[] | null>(null);
  const keyCounter = useRef(0);

  useEffect(() => {
    api.get<CodingProblem>(`/coding/${id}`)
      .then((res) => {
        setProblem(res.data);
        setCode(res.data.starter_code);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [id]);

  const language = problem?.language || "javascript";

  const handleRun = async () => {
    setRunning(true);
    setResults(null);
    try {
      const res = await api.post(`/coding/${id}/run`, { code, language });
      setResults(res.data.results.map((r: TestCaseResult) => ({ ...r, _key: `tr-${++keyCounter.current}` })));
    } catch {
      // ignore
    } finally {
      setRunning(false);
    }
  };

  if (loading || !problem) {
    return <div className="max-w-5xl mx-auto"><div className="animate-pulse h-96 bg-card rounded-xl" /></div>;
  }

  const passedCount = results?.filter((r) => r.passed).length ?? 0;
  const totalCount = results?.length ?? 0;

  return (
    <div className="max-w-5xl mx-auto">
      <Link to={`/category/${problem.category_id}`}>
        <Button variant="ghost" size="sm" className="mb-4 gap-1.5">
          <ArrowLeft className="h-4 w-4" /> Back
        </Button>
      </Link>

      <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }}>
        <div className="flex items-center gap-3 mb-4">
          <h1 className="text-2xl font-bold text-foreground">{problem.title}</h1>
          <Badge variant={difficultyColors[problem.difficulty] || "default"}>
            {problem.difficulty}
          </Badge>
          <span className="text-xs text-muted-foreground capitalize">{language}</span>
        </div>

        <Card className="mb-6">
          <CardContent className="p-6 prose prose-sm dark:prose-invert max-w-none">
            <div className="text-foreground whitespace-pre-wrap font-mono text-sm leading-relaxed">
              {problem.description}
            </div>
          </CardContent>
        </Card>
      </motion.div>

      <div className="mb-4 flex items-center justify-between">
        <span className="text-sm text-muted-foreground">
          Language: <span className="text-foreground font-medium capitalize">{language}</span>
        </span>
        <Button onClick={handleRun} disabled={running} className="gap-1.5">
          <Play className="h-4 w-4" />
          {running ? "Running..." : "Run Code"}
        </Button>
      </div>

      <Card className="overflow-hidden border-border mb-6">
        <Editor
          height="400px"
          language={language}
          value={code}
          onChange={(v) => setCode(v || "")}
          theme="vs-dark"
          options={{
            minimap: { enabled: false },
            fontSize: 14,
            fontFamily: "'JetBrains Mono', monospace",
            padding: { top: 16 },
            scrollBeyondLastLine: false,
          }}
        />
      </Card>

      {results && (
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
          <Card className={`border-2 ${passedCount === totalCount ? "border-success/30 bg-success/5" : "border-destructive/30 bg-destructive/5"}`}>
            <CardContent className="p-5">
              <div className="flex items-center gap-2 mb-4">
                {passedCount === totalCount ? (
                  <CheckCircle2 className="h-5 w-5 text-success" />
                ) : (
                  <XCircle className="h-5 w-5 text-destructive" />
                )}
                <span className="font-semibold text-foreground">
                  {passedCount}/{totalCount} test cases passed
                </span>
              </div>

              <div className="space-y-2">
                {results.map((r, i) => (
                  <div
                    key={r._key}
                    className={`flex items-center justify-between p-3 rounded-lg text-sm border ${
                      r.passed
                        ? "border-success/20 bg-success/5"
                        : "border-destructive/20 bg-destructive/5"
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      {r.passed ? (
                        <CheckCircle2 className="h-4 w-4 text-success" />
                      ) : (
                        <XCircle className="h-4 w-4 text-destructive" />
                      )}
                      <span className="text-muted-foreground">
                        Test {i + 1}
                        {r.is_hidden ? " (hidden)" : ""}
                      </span>
                    </div>
                    {!r.passed && !r.is_hidden && (
                      <div className="text-xs text-muted-foreground max-w-md truncate">
                        expected: {r.expected_output} | got: {r.actual_output}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </motion.div>
      )}
    </div>
  );
}
