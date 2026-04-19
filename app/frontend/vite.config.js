import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    // File watching inside Docker needs polling on most hosts.
    watch: { usePolling: true },
  },
});
