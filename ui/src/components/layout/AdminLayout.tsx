import { Navigate, Outlet, Link, useLocation } from "react-router-dom";
import { LayoutDashboard, FolderOpen, FileQuestion, Home } from "lucide-react";

const adminLinks = [
  { to: "/admin", label: "Dashboard", icon: LayoutDashboard, exact: true },
  { to: "/admin/categories", label: "Categories", icon: FolderOpen },
  { to: "/admin/quizzes", label: "Quizzes", icon: FileQuestion },
];

export default function AdminLayout() {
  const token = localStorage.getItem("token");
  const location = useLocation();

  if (!token) return <Navigate to="/admin/login" replace />;

  return (
    <div className="flex min-h-[calc(100vh-56px)]">
      <aside className="w-56 border-r border-border bg-card shrink-0 p-4">
        <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3 px-2">
          Admin Panel
        </p>
        <nav className="flex flex-col gap-1">
          {adminLinks.map((link) => {
            const active = link.exact
              ? location.pathname === link.to
              : location.pathname.startsWith(link.to);
            const Icon = link.icon;
            return (
              <Link
                key={link.to}
                to={link.to}
                className={`flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                  active
                    ? "bg-primary/10 text-primary"
                    : "text-muted-foreground hover:bg-accent hover:text-foreground"
                }`}
              >
                <Icon className="h-4 w-4" />
                {link.label}
              </Link>
            );
          })}
        </nav>

        <div className="mt-4 pt-4 border-t border-border">
          <Link
            to="/"
            className="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm font-medium text-muted-foreground hover:bg-accent hover:text-foreground transition-colors"
          >
            <Home className="h-4 w-4" />
            Home
          </Link>
        </div>
      </aside>
      <main className="flex-1 p-6 bg-background">
        <Outlet />
      </main>
    </div>
  );
}
