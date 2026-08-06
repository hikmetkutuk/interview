import { Link } from "react-router-dom";
import { Brain, Settings } from "lucide-react";
import { ThemeToggle } from "../ui/ThemeToggle";
import { Button } from "../ui/Button";

export default function Navbar() {
  return (
    <header className="sticky top-0 z-50 border-b border-border bg-background/80 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
        <Link to="/" className="flex items-center gap-2.5 font-semibold text-foreground hover:text-primary transition-colors">
          <Brain className="h-5 w-5 text-primary" />
          <span className="text-base tracking-tight">QuizApp</span>
        </Link>

        <div className="flex items-center gap-1">
          <Link to="/">
            <Button variant="ghost" size="sm">Home</Button>
          </Link>
          <Link to="/admin">
            <Button variant="ghost" size="sm" className="gap-1.5">
              <Settings className="h-3.5 w-3.5" />
              Admin
            </Button>
          </Link>
          <ThemeToggle />
        </div>
      </div>
    </header>
  );
}
