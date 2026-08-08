import { useState } from "react";
import { ArrowRightLeft } from "lucide-react";
import { Card } from "./ui/Card";
import { Badge } from "./ui/Badge";
import { shuffle } from "../lib/shuffle";
import type { Option } from "../types";

interface Props {
  readonly options: Option[];
  readonly initialPairs?: Record<string, string>;
  readonly onPairsChange: (pairs: [string, string][]) => void;
  readonly questionIndex: number;
  readonly totalQuestions: number;
}

export default function MatchingQuestion({ options, initialPairs, onPairsChange, questionIndex, totalQuestions }: Props) {
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
        <span className="text-xs text-muted-foreground font-mono">MATCHING</span>
      </div>
      <div className="flex items-center gap-2 mb-4 text-sm text-muted-foreground">
        <ArrowRightLeft className="h-4 w-4" />
        Match each item with the correct value
      </div>
      <div className="space-y-2">
        {leftItems.map((item) => (
          <div key={item.id} className="flex items-center gap-3">
            <div className="flex-1 p-3 rounded-lg border border-border bg-muted/30 text-sm font-medium">
              {item.text}
            </div>
            <span className="text-muted-foreground text-sm">→</span>
            <select
              value={pairs[item.id] || ""}
              onChange={(e) => handleMatch(item.id, e.target.value)}
              className="flex-1 h-11 rounded-lg border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
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
