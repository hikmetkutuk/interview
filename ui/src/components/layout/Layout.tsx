import { useEffect } from "react";
import { Outlet } from "react-router-dom";
import Navbar from "./Navbar";

export default function Layout() {
  useEffect(() => {
    const root = document.documentElement;
    const stored = localStorage.getItem("theme");
    if (stored === "light") {
      root.classList.remove("dark");
    } else if (!stored) {
      root.classList.add("dark");
    }
  }, []);

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <main className="max-w-6xl mx-auto px-4 py-8">
        <Outlet />
      </main>
    </div>
  );
}
