import { BrowserRouter, Routes, Route } from "react-router-dom";
import Layout from "./components/layout/Layout";
import AdminLayout from "./components/layout/AdminLayout";
import Home from "./pages/Home";
import CategoryQuizzes from "./pages/CategoryQuizzes";
import Quiz from "./pages/Quiz";
import Result from "./pages/Result";
import AdminLogin from "./pages/admin/Login";
import AdminDashboard from "./pages/admin/Dashboard";
import AdminCategories from "./pages/admin/Categories";
import AdminQuizzes from "./pages/admin/Quizzes";
import AdminQuestionEditor from "./pages/admin/QuestionEditor";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<Home />} />
          <Route path="/category/:id" element={<CategoryQuizzes />} />
          <Route path="/quiz/:id" element={<Quiz />} />
          <Route path="/result" element={<Result />} />
        </Route>

        <Route path="/admin/login" element={<AdminLogin />} />
        <Route element={<AdminLayout />}>
          <Route path="/admin" element={<AdminDashboard />} />
          <Route path="/admin/categories" element={<AdminCategories />} />
          <Route path="/admin/quizzes" element={<AdminQuizzes />} />
          <Route path="/admin/quizzes/:id/questions" element={<AdminQuestionEditor />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
