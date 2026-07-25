import { cp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { dirname, extname, join } from "node:path";

const outputDirectory = "dist";
const publicFiles = [
  "index.html",
  "modern-off.css",
  "site.webmanifest",
  "assets/supabase.min.js",
  "assets/app-icon.svg",
  "assets/apple-touch-icon.png",
  "assets/icon-192.png",
  "assets/icon-512.png"
];

const contentTypes = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".webmanifest": "application/manifest+json; charset=utf-8"
};

await rm(outputDirectory, { recursive: true, force: true });
await mkdir(join(outputDirectory, "server"), { recursive: true });

const entries = {};
for (const file of publicFiles) {
  const destination = join(outputDirectory, file);
  await mkdir(dirname(destination), { recursive: true });
  await cp(file, destination);
  entries[`/${file}`] = {
    body: (await readFile(file)).toString("base64"),
    type: contentTypes[extname(file)] ?? "application/octet-stream"
  };
}

const worker = `const files = ${JSON.stringify(entries)};

function decodeBase64(value) {
  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes;
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname === "/" ? "/index.html" : url.pathname;
    const file = files[path];

    if (!file) {
      return new Response("Not found", { status: 404 });
    }

    return new Response(decodeBase64(file.body), {
      headers: {
        "Content-Type": file.type,
        "Cache-Control": path === "/index.html"
          ? "no-cache"
          : "public, max-age=31536000, immutable"
      }
    });
  }
};
`;

await writeFile(join(outputDirectory, "server/index.js"), worker);
