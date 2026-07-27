import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { dirname } from "node:path";

const run = promisify(execFile);
const watched = new Set(["edit", "write"]);

export default (pi) => {
  pi.on("tool_result", async (event) => {
    if (!watched.has(event.toolName)) return;
    const path = event.input?.path;
    if (!path?.startsWith(process.env.HOME + "/agents/")) return;
    try {
      await run("@jj@", ["status"], { cwd: dirname(path) });
    } catch {}
  });
};
