import { useEffect, useState } from "react";

// VITE_API_URL is injected at build time. In local dev (via compose) it points
// at the backend on localhost:8000. In prod builds it'll point at the real API.
const API = import.meta.env.VITE_API_URL || "http://localhost:8000";

export default function App() {
  const [tasks, setTasks] = useState([]);
  const [title, setTitle] = useState("");
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  async function load() {
    try {
      const res = await fetch(`${API}/api/tasks`);
      if (!res.ok) throw new Error(`GET /api/tasks -> ${res.status}`);
      setTasks(await res.json());
      setError(null);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function addTask(e) {
    e.preventDefault();
    if (!title.trim()) return;
    const res = await fetch(`${API}/api/tasks`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title }),
    });
    if (res.ok) {
      setTitle("");
      load();
    }
  }

  async function toggle(task) {
    await fetch(`${API}/api/tasks/${task.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ done: !task.done }),
    });
    load();
  }

  async function remove(task) {
    await fetch(`${API}/api/tasks/${task.id}`, { method: "DELETE" });
    load();
  }

  return (
    <div className="container">
      <header>
        <h1>Tasks</h1>
        <p className="subtitle">DevOps Learning Project — Phase 1</p>
      </header>

      <form onSubmit={addTask} className="add-form">
        <input
          type="text"
          placeholder="What needs doing?"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
        />
        <button type="submit">Add</button>
      </form>

      {error && <div className="error">API error: {error}</div>}
      {loading && <div className="muted">Loading…</div>}

      <ul className="task-list">
        {tasks.map((t) => (
          <li key={t.id} className={t.done ? "done" : ""}>
            <label>
              <input
                type="checkbox"
                checked={t.done}
                onChange={() => toggle(t)}
              />
              <span>{t.title}</span>
            </label>
            <button onClick={() => remove(t)} className="delete">
              ×
            </button>
          </li>
        ))}
      </ul>

      {!loading && tasks.length === 0 && !error && (
        <p className="muted">No tasks yet. Add one above.</p>
      )}
    </div>
  );
}
