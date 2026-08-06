import { useEffect, useState } from "react";

interface Props {
  readonly seconds: number;
  readonly onExpire: () => void;
}

export default function Timer({ seconds, onExpire }: Props) {
  const [remaining, setRemaining] = useState(seconds);

  useEffect(() => {
    setRemaining(seconds);
  }, [seconds]);

  useEffect(() => {
    if (remaining <= 0) {
      onExpire();
      return;
    }
    const id = setInterval(() => setRemaining((r) => r - 1), 1000);
    return () => clearInterval(id);
  }, [remaining, onExpire]);

  const minutes = Math.floor(remaining / 60);
  const secs = remaining % 60;
  const pct = (remaining / seconds) * 100;

  return (
    <div className="flex items-center gap-3">
      <svg className="w-10 h-10 -rotate-90" viewBox="0 0 36 36">
        <circle
          cx="18" cy="18" r="15"
          fill="none" stroke="#e5e7eb" strokeWidth="3"
        />
        <circle
          cx="18" cy="18" r="15"
          fill="none"
          stroke={pct > 25 ? "#4f46e5" : "#ef4444"}
          strokeWidth="3"
          strokeDasharray={`${(pct / 100) * 94.2} 94.2`}
          strokeLinecap="round"
        />
      </svg>
      <span className={`text-lg font-mono font-bold ${remaining <= 30 ? "text-red-500" : "text-gray-700"}`}>
        {minutes}:{secs.toString().padStart(2, "0")}
      </span>
    </div>
  );
}
