import { useEffect, useState } from "react";
import { AlarmClock } from "lucide-react";

interface Props {
  readonly seconds: number;
  readonly onExpire: () => void;
}

export default function Timer({ seconds, onExpire }: Props) {
  const [remaining, setRemaining] = useState(seconds);

  useEffect(() => setRemaining(seconds), [seconds]);

  useEffect(() => {
    if (remaining <= 0) { onExpire(); return; }
    const id = setInterval(() => setRemaining((r) => r - 1), 1000);
    return () => clearInterval(id);
  }, [remaining, onExpire]);

  const pct = Math.max(0, (remaining / seconds) * 100);
  const urgent = remaining <= 30;

  return (
    <div className="flex items-center gap-2">
      <svg className="w-9 h-9 -rotate-90" viewBox="0 0 36 36">
        <circle cx="18" cy="18" r="15" fill="none" className="stroke-border" strokeWidth="3" />
        <circle
          cx="18" cy="18" r="15" fill="none"
          className={urgent ? "stroke-destructive" : "stroke-primary"}
          strokeWidth="3"
          strokeDasharray={`${(pct / 100) * 94.2} 94.2`}
          strokeLinecap="round"
          style={{ transition: "stroke-dasharray 1s linear" }}
        />
      </svg>
      <div className="flex items-center gap-1">
        <AlarmClock className={`h-4 w-4 ${urgent ? "text-destructive animate-pulse" : "text-muted-foreground"}`} />
        <span className={`text-lg font-mono font-bold tabular-nums ${urgent ? "text-destructive" : "text-foreground"}`}>
          {Math.floor(remaining / 60)}:{String(remaining % 60).padStart(2, "0")}
        </span>
      </div>
    </div>
  );
}
