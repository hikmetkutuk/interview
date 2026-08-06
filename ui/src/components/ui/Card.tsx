import type { HTMLAttributes } from "react";

interface Props extends HTMLAttributes<HTMLDivElement> {
  readonly variant?: "default" | "glass";
}

export function Card({ className = "", variant = "default", ...props }: Readonly<Props>) {
  const base =
    variant === "glass"
      ? "bg-card/70 backdrop-blur border border-border"
      : "bg-card border border-border";
  return (
    <div
      className={`rounded-xl shadow-sm ${base} ${className}`}
      {...props}
    />
  );
}

export function CardHeader({ className = "", ...props }: Readonly<HTMLAttributes<HTMLDivElement>>) {
  return <div className={`p-6 pb-0 ${className}`} {...props} />;
}

export function CardContent({ className = "", ...props }: Readonly<HTMLAttributes<HTMLDivElement>>) {
  return <div className={`p-6 ${className}`} {...props} />;
}

export function CardFooter({ className = "", ...props }: Readonly<HTMLAttributes<HTMLDivElement>>) {
  return (
    <div className={`flex items-center p-6 pt-0 ${className}`} {...props} />
  );
}
