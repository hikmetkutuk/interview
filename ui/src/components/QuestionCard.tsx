import { Code2 } from "lucide-react";
import type { Question, Option } from "../types";
import { Badge } from "./ui/Badge";
import { Card } from "./ui/Card";
import MatchingQuestion from "./MatchingQuestion";

interface Props {
  readonly question: Question;
  readonly options: Option[];
  readonly selectedIds: string[];
  readonly onSelect: (optionId: string) => void;
  readonly matchingPairs?: Record<string, string>;
  readonly onMatchingPairs?: (pairs: [string, string][]) => void;
  readonly questionIndex: number;
  readonly totalQuestions: number;
}

function topicName(id: string): string {
  const p = id.split("-")[0];
  const m: Record<string, string> = {
    di: "DI / Lifetime", async: "async/await", generic: "Generic",
    delegate: "Delegate & Event", ienum: "IEnumerable / IQueryable / IList",
    exception: "Exception Handling", valuetype: "Value Type / Reference Type",
    gc: "GC / IDisposable", abstract: "Abstract / Interface",
    lambda: "Lambda / Expression", linq: "LINQ", middleware: "Middleware",
    efcore: "EF Core", reflection: "Reflection", extension: "Extension Methods",
    record: "Records / Pattern Matching", nrt: "Nullable Reference Types",
    modifiers: "Access Modifiers",
    solid: "SOLID & Tasarım",
    pattern: "Tasarım Kalıpları",
    microservice: "Microservice",
    eventual: "Eventual Consistency",
    cleanarch: "Clean Architecture",
    cqrs: "CQRS",
    ddd: "DDD",
    apiver: "API Versioning",
    resilience: "Resilience Patterns",
    caching: "Caching Strategies",
    observability: "Observability",
    ratelimit: "Rate Limiting",
    cap: "CAP Theorem",
    idempotent: "Idempotent API",
    hexagonal: "Hexagonal Architecture",
    gateway: "API Gateway / BFF",
    distlock: "Distributed Systems",
    strangler: "Strangler Fig",
    multitenancy: "Multi-Tenancy",
    featureflag: "Feature Flags",
    healthcheck: "Health Checks",
    deployment: "Deployment",
    security: "Security Architecture",
    sharding: "Sharding",
    verticalslice: "Vertical Slice",
  };
  return m[p] || p;
}

export default function QuestionCard({
  question, options, selectedIds, onSelect, matchingPairs, onMatchingPairs, questionIndex, totalQuestions,
}: Props) {
  const isMulti = question.type === "maq";

  if (question.type === "matching" && onMatchingPairs) {
    return <MatchingQuestion options={options || []} initialPairs={matchingPairs} onPairsChange={onMatchingPairs} questionIndex={questionIndex} totalQuestions={totalQuestions} questionId={question.id} questionText={question.text} />;
  }

  return (
    <Card className="p-6">
      <div className="flex items-center justify-between mb-4">
        <Badge variant="default">
          Question {questionIndex + 1} of {totalQuestions}
        </Badge>
        <span className="text-xs text-muted-foreground">
          {topicName(question.id)}
        </span>
      </div>

      <h2 className="text-lg font-semibold text-foreground mb-3 break-words overflow-hidden">{question.text}</h2>

      {question.image_url && (
        <img src={question.image_url} alt="" className="max-w-full rounded-lg mb-3" />
      )}

      {question.code_snippet && (
        <div className="bg-zinc-950 dark:bg-black border border-border rounded-lg mb-3 overflow-hidden">
          <div className="flex items-center gap-1.5 px-3 py-2 border-b border-border bg-zinc-900">
            <Code2 className="h-3 w-3 text-muted-foreground" />
            <span className="text-xs text-muted-foreground font-mono">code</span>
          </div>
          <pre className="text-green-400 text-sm p-4 overflow-x-auto font-mono leading-relaxed">
            <code>{question.code_snippet}</code>
          </pre>
        </div>
      )}

      <div className="flex flex-col gap-2 mt-4">
        {(options || []).map((opt) => {
          const checked = selectedIds.includes(opt.id);
          return (
            <label
              key={opt.id}
              className={`flex items-center gap-3 p-3.5 rounded-lg border cursor-pointer transition-all duration-150 ${
                checked
                  ? "border-primary/50 bg-primary/5 text-foreground"
                  : "border-border hover:border-primary/30 hover:bg-accent"
              }`}
            >
              <input
                type={isMulti ? "checkbox" : "radio"}
                name={`question-${question.id}`}
                checked={checked}
                onChange={() => onSelect(opt.id)}
                className="accent-primary h-4 w-4"
              />
              <span className="text-sm">{opt.text}</span>
            </label>
          );
        })}
      </div>
    </Card>
  );
}
