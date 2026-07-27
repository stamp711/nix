// Unlike the before hook, opencode's after hook carries args in its first argument.
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { dirname } from "node:path";

const run = promisify(execFile);
const watched = new Set(["edit", "write"]);

export const JjSnapshot = async () => ({
  "tool.execute.after": async (input) => {
    if (!watched.has(input.tool)) return;
    const path = input.args?.filePath;
    if (!path?.startsWith(process.env.HOME + "/agents/")) return;
    try {
      await run("@jj@", ["status"], { cwd: dirname(path) });
    } catch {}
  },
});
