import { Navigate, Outlet, Link, useLocation } from "react-router-dom";

const adminLinks = [
  { to: "/admin", label: "Dashboard", exact: true },
  { to: "/admin/categories", label: "Categories" },
  { to: "/admin/quizzes", label: "Quizzes" },
];

export default function AdminLayout() {
  const token = localStorage.getItem("token");
  const location = useLocation();

  if (!token) {
    return <Navigate to="/admin/login" replace />;
  }

  return (
    <div className="flex min-h-[calc(100vh-56px)]">
      <aside className="w-56 bg-white border-r border-gray-200 p-4 shrink-0">
        <nav className="flex flex-col gap-1">
          {adminLinks.map((link) => {
            const active =
              link.exact
                ? location.pathname === link.to
                : location.pathname.startsWith(link.to);
            return (
              <Link
                key={link.to}
                to={link.to}
                className={`px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                  active
                    ? "bg-indigo-50 text-indigo-700"
                    : "text-gray-600 hover:bg-gray-100"
                }`}
              >
                {link.label}
              </Link>
            );
          })}
        </nav>
      </aside>
      <main className="flex-1 p-6">
        <Outlet />
      </main>
    </div>
  );
}
