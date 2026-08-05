import { Link } from "react-router-dom";

export default function Navbar() {
  return (
    <nav className="bg-indigo-600 text-white shadow">
      <div className="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
        <Link to="/" className="text-xl font-bold tracking-tight">
          Quiz App
        </Link>
        <div className="flex items-center gap-4 text-sm">
          <Link to="/" className="hover:text-indigo-200 transition-colors">
            Home
          </Link>
          <Link
            to="/admin"
            className="bg-white text-indigo-600 px-3 py-1 rounded-md font-medium hover:bg-indigo-100 transition-colors"
          >
            Admin
          </Link>
        </div>
      </div>
    </nav>
  );
}
