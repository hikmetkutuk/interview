import { useState } from "react";
import { ArrowRightLeft } from "lucide-react";
import { Card } from "./ui/Card";
import { Badge } from "./ui/Badge";
import { shuffle } from "../lib/shuffle";
import type { Option } from "../types";

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

interface Props {
  readonly options: Option[];
  readonly initialPairs?: Record<string, string>;
  readonly onPairsChange: (pairs: [string, string][]) => void;
  readonly questionIndex: number;
  readonly totalQuestions: number;
  readonly questionId?: string;
  readonly questionText?: string;
}

export default function MatchingQuestion({ options, initialPairs, onPairsChange, questionIndex, totalQuestions, questionId, questionText }: Props) {
  const leftItems = (options || []).filter((o) => o.match_text);
  const rightValues = shuffle([...new Set(leftItems.map((o) => o.match_text))]);

  const [pairs, setPairs] = useState<Record<string, string>>(initialPairs || {});

  const handleMatch = (leftId: string, rightValue: string) => {
    const next = { ...pairs, [leftId]: rightValue };
    setPairs(next);
    const result = Object.entries(next) as [string, string][];
    onPairsChange(result);
  };

  return (
    <Card className="p-6">
      <div className="flex items-center justify-between mb-4">
        <Badge variant="default">Question {questionIndex + 1} of {totalQuestions}</Badge>
        <span className="text-xs text-muted-foreground">
          {questionId ? topicName(questionId) : null}
        </span>
      </div>
      {questionText && (
        <h2 className="text-lg font-semibold text-foreground mb-3 break-words overflow-hidden">{questionText}</h2>
      )}
      <div className="flex items-center gap-2 mb-4 text-sm text-muted-foreground">
        <ArrowRightLeft className="h-4 w-4" />
        Match each item with the correct value
      </div>
      <div className="space-y-2">
        {leftItems.map((item) => (
          <div key={item.id} className="grid grid-cols-[1fr_auto_1fr] gap-2 items-stretch">
            <div className="p-3 rounded-lg border border-border bg-muted/30 text-sm font-medium break-words flex items-center">
              {item.text}
            </div>
            <span className="text-muted-foreground text-sm flex items-center px-1">→</span>
            <select
              value={pairs[item.id] || ""}
              onChange={(e) => handleMatch(item.id, e.target.value)}
              className="h-full min-h-[44px] w-full min-w-0 rounded-lg border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
            >
              <option value="">Select...</option>
              {rightValues.map((rv) => (
                <option key={rv} value={rv}>{rv}</option>
              ))}
            </select>
          </div>
        ))}
      </div>
    </Card>
  );
}
