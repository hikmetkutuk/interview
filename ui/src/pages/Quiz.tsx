import { useCallback, useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { ArrowLeft, ArrowRight, CheckCircle } from "lucide-react";
import api from "../api/client";
import Timer from "../components/Timer";
import QuestionCard from "../components/QuestionCard";
import { Button } from "../components/ui/Button";
import { shuffle } from "../lib/shuffle";
import type { QuizWithQuestions, QuizResult } from "../types";

function toRecord(pairs: [string, string][]): Record<string, string> {
  const r: Record<string, string> = {};
  for (const [k, v] of pairs) r[k] = v;
  return r;
}

export default function Quiz() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [quiz, setQuiz] = useState<QuizWithQuestions | null>(null);
  const [loading, setLoading] = useState(true);
  const [currentIdx, setCurrentIdx] = useState(0);
  const [answers, setAnswers] = useState<Record<string, string[]>>({});
  const [matchingPairs, setMatchingPairs] = useState<Record<string, [string, string][]>>(() => {
    try { return JSON.parse(localStorage.getItem("quiz-matching") || "{}"); } catch { return {}; }
  });
  const [submitted, setSubmitted] = useState(false);
  const [direction, setDirection] = useState(1);

  useEffect(() => {
    api.get<QuizWithQuestions>(`/quizzes/${id}`)
      .then((res) => {
        const q = res.data;
        q.questions = shuffle(q.questions).map((question) => ({
          ...question,
          options: shuffle(question.options || []),
        }));
        setQuiz(q);
      })
      .catch(() => navigate("/"))
      .finally(() => setLoading(false));
  }, [id, navigate]);

  const submitQuiz = useCallback(() => {
    if (submitted || !quiz) return;
    setSubmitted(true);
    const payload = {
      answers: [
        ...Object.entries(answers).map(([qid, oids]) => ({ question_id: qid, selected_option_ids: oids })),
        ...Object.entries(matchingPairs).map(([qid, pairs]) => ({ question_id: qid, selected_option_ids: [], matching_pairs: pairs })),
      ],
    };
    api.post<QuizResult>(`/quizzes/${id}/submit`, payload)
      .then((res) => { localStorage.removeItem("quiz-matching"); navigate("/result", { state: { ...res.data, order: quiz.questions.map((q) => q.id) } }); })
      .catch(() => setSubmitted(false));
  }, [answers, matchingPairs, id, navigate, quiz, submitted]);

  const handleSelect = (optionId: string) => {
    if (!quiz) return;
    const q = quiz.questions[currentIdx];
    if (!q) return;
    setAnswers((prev) => {
      const current = prev[q.id] || [];
      if (q.type === "maq") {
        const next = current.includes(optionId)
          ? current.filter((oid) => oid !== optionId)
          : [...current, optionId];
        return { ...prev, [q.id]: next };
      }
      return { ...prev, [q.id]: [optionId] };
    });
  };

  const goTo = (idx: number) => {
    setDirection(idx > currentIdx ? 1 : -1);
    setCurrentIdx(idx);
  };

  if (loading || !quiz) {
    return (
      <div className="max-w-2xl mx-auto">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-card rounded-lg w-1/3" />
          <div className="h-64 bg-card rounded-xl" />
        </div>
      </div>
    );
  }

  if (quiz.questions.length === 0) {
    return (
      <div className="max-w-2xl mx-auto text-center py-16">
        <h1 className="text-2xl font-bold text-foreground">{quiz.title}</h1>
        <p className="text-muted-foreground mt-3">This quiz has no questions yet.</p>
        <Button className="mt-6" variant="outline" onClick={() => navigate(-1)}>
          <ArrowLeft className="h-4 w-4" /> Go Back
        </Button>
      </div>
    );
  }

  const question = quiz.questions[currentIdx];
  if (!question) return <div className="text-muted-foreground">Question not found.</div>;
  const selectedIds = answers[question.id] || [];
  const isLast = currentIdx === quiz.questions.length - 1;

  return (
    <div className="max-w-2xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-foreground">{quiz.title}</h1>
          <p className="text-sm text-muted-foreground mt-0.5">
            {quiz.questions.length} questions
          </p>
        </div>
        <Timer seconds={quiz.time_limit_seconds} onExpire={submitQuiz} />
      </div>

      {/* Progress bar */}
      <div className="h-1 bg-border rounded-full mb-6 overflow-hidden">
        <div
          className="h-full bg-primary rounded-full transition-all duration-300"
          style={{ width: `${((currentIdx + 1) / quiz.questions.length) * 100}%` }}
        />
      </div>

      <AnimatePresence mode="wait" custom={direction}>
        <motion.div
          key={currentIdx}
          custom={direction}
          initial={{ opacity: 0, x: 50 * direction }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -50 * direction }}
          transition={{ duration: 0.2 }}
        >
          <QuestionCard
            question={question}
            options={question.options}
            selectedIds={selectedIds}
            onSelect={handleSelect}
            matchingPairs={toRecord(matchingPairs[question.id] || [])}
            onMatchingPairs={(pairs) => {
              setMatchingPairs((prev) => {
                const next = { ...prev, [question.id]: pairs };
                localStorage.setItem("quiz-matching", JSON.stringify(next));
                return next;
              });
            }}
            questionIndex={currentIdx}
            totalQuestions={quiz.questions.length}
          />
        </motion.div>
      </AnimatePresence>

      <div className="flex justify-between mt-6">
        <Button
          variant="outline"
          onClick={() => goTo(currentIdx - 1)}
          disabled={currentIdx === 0}
          className="gap-1.5"
        >
          <ArrowLeft className="h-4 w-4" /> Previous
        </Button>

        {!isLast ? (
          <Button onClick={() => goTo(currentIdx + 1)} className="gap-1.5">
            Next <ArrowRight className="h-4 w-4" />
          </Button>
        ) : (
          <Button onClick={submitQuiz} disabled={submitted} className="gap-1.5 bg-success text-success-foreground hover:brightness-110">
            <CheckCircle className="h-4 w-4" />
            {submitted ? "Submitting..." : "Submit Quiz"}
          </Button>
        )}
      </div>
    </div>
  );
}
