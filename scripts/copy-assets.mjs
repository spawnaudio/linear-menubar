import { cp, mkdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(fileURLToPath(import.meta.url));
const src = path.join(root, "..", "electron", "assets");
const dest = path.join(root, "..", "dist-electron", "assets");

await mkdir(dest, { recursive: true });
await cp(src, dest, { recursive: true });
console.log(`Copied assets -> ${dest}`);
