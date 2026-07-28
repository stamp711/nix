import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { dirname } from "node:path";
import { statSync } from "node:fs";

const run = promisify(execFile);
const watched = new Set(["read", "edit", "write"]);
const reason = "@reason@";

export const JjStaleGuard = async () => ({
  "tool.execute.before": async (input, output) => {
    if (!watched.has(input.tool)) return;
    const path = output.args?.filePath;
    if (!path?.startsWith(process.env.HOME + "/agents/")) return;
    let dir = path;
    try {
      if (!statSync(dir).isDirectory()) dir = dirname(dir);
    } catch {
      dir = dirname(dir);
    }
    try {
      await run("@jj@", ["workspace", "list"], { cwd: dir });
    } catch (err) {
      if (!String(err.stderr).includes("working copy is stale")) return;
      throw new Error(reason.replace("%s", dir));
    }
  },
});
