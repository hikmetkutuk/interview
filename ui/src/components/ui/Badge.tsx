import type { HTMLAttributes } from "react";

interface Props extends HTMLAttributes<HTMLSpanElement> {
  readonly variant?: "default" | "outline" | "success" | "destructive";
}

const variants: Record<string, string> = {
  default: "bg-primary/10 text-primary border-transparent",
  outline: "text-foreground border-border",
  success: "bg-success/10 text-success border-transparent",
  destructive: "bg-destructive/10 text-destructive border-transparent",
};

export function Badge({ className = "", variant = "default", ...props }: Readonly<Props>) {
  return (
    <span
      className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors ${variants[variant]} ${className}`}
      {...props}
    />
  );
}
