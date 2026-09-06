import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// The renderer is a standalone web app that Electron loads in the menubar
// popover window. Running `vite` alone serves the same UI in a browser, which
// is handy for development and for verifying the environment without Electron.
export default defineConfig({
  plugins: [react()],
  base: "./",
  build: {
    outDir: "dist",
    emptyOutDir: true,
  },
  server: {
    host: "127.0.0.1",
    port: 5173,
    strictPort: true,
  },
});
