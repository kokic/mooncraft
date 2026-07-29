import { cpSync, existsSync, readFileSync, rmSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";

const webRoot = resolve("web");
const distRoot = resolve(".dist");

const levelPath = resolve("_build/js/release/build/level/level.js");
const runtimePath = resolve("_build/js/release/build/mooncraft.js");
const mooncraftModules = new Map([
  ["virtual:mooncraft-level", levelPath],
  ["virtual:mooncraft-runtime", runtimePath],
]);

const entryPlaceholder = "<!-- mooncraft-entry -->";

function mooncraftReleaseBuild() {
  return {
    name: "mooncraft-release-build",
    buildStart() {
      const result = spawnSync(
        "moon",
        ["build", "--release"],
        { stdio: "inherit" },
      );
      if (result.error) this.error(result.error.message);
      if (result.status !== 0) this.error("MoonBit release build failed.");
    },
  };
}

function copyStaticAssets() {
  return {
    name: "copy-static-assets",
    buildStart() {
      rmSync(resolve(distRoot, "assets"), { recursive: true, force: true });
      cpSync(resolve(webRoot, "assets"), resolve(distRoot, "assets"), {
        recursive: true,
      });
      cpSync(resolve(webRoot, "favicon.ico"), resolve(distRoot, "favicon.ico"));
    },
  };
}

function mooncraftRuntime() {
  return {
    name: "mooncraft-runtime",
    buildStart() {
      for (const [moduleId, modulePath] of mooncraftModules) {
        if (!existsSync(modulePath)) {
          this.error(`${moduleId} is missing after the release build.`);
        }
      }
    },
    resolveId(source) {
      return mooncraftModules.get(source) ?? null;
    },
  };
}

function htmlEntry() {
  return {
    name: "html-entry",
    generateBundle(_options, bundle) {
      const entry = Object.values(bundle).find(
        (output) => output.type === "chunk" && output.isEntry,
      );
      if (!entry) this.error("Rollup did not emit the Web entry module.");
      const template = readFileSync(resolve(webRoot, "index.html"), "utf8");
      if (!template.includes(entryPlaceholder)) {
        this.error("Web HTML entry placeholder is missing.");
      }
      this.emitFile({
        type: "asset",
        fileName: "index.html",
        source: template.replace(
          entryPlaceholder,
          `<script type="module" src="./${entry.fileName}"></script>`,
        ),
      });
    },
  };
}

export default {
  input: resolve(webRoot, "js/app-main.js"),
  output: {
    dir: distRoot,
    format: "es",
    entryFileNames: "assets/[name]-[hash].js",
    chunkFileNames: "assets/[name]-[hash].js",
    assetFileNames: "assets/[name]-[hash][extname]",
  },
  plugins: [
    mooncraftReleaseBuild(),
    copyStaticAssets(),
    mooncraftRuntime(),
    htmlEntry(),
  ],
};
