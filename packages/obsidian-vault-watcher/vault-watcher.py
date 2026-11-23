"""Read-only Obsidian vault watcher that dispatches bare AI tags to an Orca chat."""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import os
import re
import shutil
import signal
import sys
import time
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path

from watchfiles import Change, awatch

log = logging.getLogger("vault-watcher")

IGNORE_DIRS = frozenset(
    {
        ".obsidian",
        ".trash",
        ".git",
        ".jj",
        "attachments",
        ".agents",
    }
)

# Bare `#AI` (case-insensitive): not preceded by word/slash/hash (except `\n` in
# serialized side comments), and not followed by `-`, `/`, or word chars
# (excluding `#AI-running`, `#AI-done`, `#AI/...`).
AI_TAG_RE = re.compile(r"(?:(?<=\\n)|(?<![\w/#]))#AI(?![-\w/])", re.IGNORECASE)
INLINE_CODE_RE = re.compile(r"(`+)(?!`)(.+?)(?<!`)\1")
HEADING_RE = re.compile(r"^[ \t]{0,3}#{1,6}\s+.+")
ANCHOR_RE = re.compile(r"\u200b?<!--/?c:[a-z0-9]+-->")
FENCE_OPEN_RE = re.compile(r"^[ \t]{0,3}(`{3,}|~{3,})")
AI_COMMENT_LINE_RE = re.compile(r"^ai\s*\(")

# Strip caller-identity env vars so `--from <handle>` works identically whether
# invoked from systemd, a standalone shell, or an Orca terminal.
ORCA_CALLER_ENV_VARS = frozenset(
    {
        "ORCA_AGENT_SESSION_ID",
        "ORCA_AGENT_SESSION_SPAWN_TOKEN",
        "ORCA_TERMINAL_HANDLE",
        "ORCA_STRUCTURED_SESSION",
        "ORCA_RUN_ID",
        "ORCA_TASK_ID",
        "ORCA_DISPATCH_ID",
    }
)

ORCA_TARGET_PREFIXES = ("orca_session_id:", "term_", "dispatch:", "run:")


@dataclass(frozen=True)
class Config:
    vault: Path
    target: str
    from_handle: str
    orca_bin: str
    quiet_sec: float
    reconcile_sec: float
    reconcile_max_sec: float
    inflight_ttl: float
    send_timeout: float
    dry_run: bool
    once: bool


@dataclass(frozen=True)
class Match:
    relpath: str
    line_no: int
    nearest_heading: str
    line_stripped: str

    @property
    def key(self) -> tuple[str, str, str]:
        return (self.relpath, self.nearest_heading, self.line_stripped)

    def format_line(self, max_len: int = 240) -> str:
        text = self.line_stripped
        if len(text) > max_len:
            m = AI_TAG_RE.search(text)
            if m:
                start = max(0, m.start() - max_len // 2)
                end = min(len(text), start + max_len)
                start = max(0, end - max_len)
                prefix = "..." if start > 0 else ""
                suffix = "..." if end < len(text) else ""
                text = f"{prefix}{text[start:end]}{suffix}"
            else:
                text = f"{text[:max_len]}..."
        return f"{self.relpath}:{self.line_no}: {text}"


def is_watched_md(path: Path, vault: Path) -> bool:
    if path.suffix.lower() != ".md":
        return False
    try:
        rel = path.relative_to(vault)
    except ValueError:
        return False
    return not any(part in IGNORE_DIRS for part in rel.parts[:-1])


def iter_vault_md_files(vault: Path) -> Iterator[Path]:
    for root, dirnames, filenames in os.walk(vault):
        dirnames[:] = sorted(d for d in dirnames if d not in IGNORE_DIRS)
        root_path = Path(root)
        for name in sorted(filenames):
            if name.lower().endswith(".md"):
                yield root_path / name


def _frontmatter_end(lines: list[str]) -> int:
    if not lines or lines[0].strip() != "---":
        return 0
    for idx in range(1, len(lines)):
        if lines[idx].strip() in ("---", "..."):
            return idx + 1
    return 0


def scan_text(relpath: str, text: str) -> list[Match]:
    lines = text.splitlines()
    start_idx = _frontmatter_end(lines)

    matches: list[Match] = []
    nearest_heading = ""
    fence_char = ""
    fence_len = 0
    in_co = False
    co_resolved = False

    for idx in range(start_idx, len(lines)):
        line = lines[idx]
        line_no = idx + 1

        if in_co:
            if "-->" in line:
                in_co = False
                co_resolved = False
                continue
            if co_resolved or AI_COMMENT_LINE_RE.match(line):
                continue
            cleaned = INLINE_CODE_RE.sub(" ", line)
            if AI_TAG_RE.search(cleaned):
                matches.append(Match(relpath, line_no, nearest_heading, line.strip()))
            continue

        if fence_char:
            close_re = rf"^[ \t]{{0,3}}{re.escape(fence_char)}{{{fence_len},}}[ \t]*$"
            if re.match(close_re, line):
                fence_char = ""
                fence_len = 0
            continue

        fence_m = FENCE_OPEN_RE.match(line)
        if fence_m:
            token = fence_m.group(1)
            fence_char = token[0]
            fence_len = len(token)
            continue

        if line.lstrip().startswith("<!--co:"):
            if "-->" not in line:
                in_co = True
                co_resolved = "status:resolved" in line
            continue

        if HEADING_RE.match(line):
            nearest_heading = ANCHOR_RE.sub("", line.strip())

        cleaned = INLINE_CODE_RE.sub(" ", line)
        if AI_TAG_RE.search(cleaned):
            matches.append(Match(relpath, line_no, nearest_heading, line.strip()))

    return matches


def scan_file(path: Path, vault: Path) -> list[Match]:
    try:
        relpath = path.relative_to(vault).as_posix()
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        log.debug("skip unreadable %s: %s", path, exc)
        return []
    return scan_text(relpath, text)


def normalize_target(target: str) -> str:
    if not target or target.startswith(ORCA_TARGET_PREFIXES):
        return target
    return f"orca_session_id:{target}"


def default_orca_bin() -> str:
    env_bin = os.environ.get("ORCA_BIN")
    if env_bin:
        return env_bin
    found = shutil.which("orca-ide")
    if found:
        return found
    local_bin = Path.home() / ".local" / "bin" / "orca-ide"
    if local_bin.exists():
        return str(local_bin)
    return "orca-ide"


def _sanitized_env() -> dict[str, str]:
    return {k: v for k, v in os.environ.items() if k not in ORCA_CALLER_ENV_VARS}


def _extract_orca_error(stdout: str, stderr: str) -> str:
    for stream in (stdout, stderr):
        text = stream.strip()
        if not text:
            continue
        try:
            data = json.loads(text.splitlines()[0])
            if isinstance(data, dict) and data.get("ok") is False:
                err = data.get("error") or {}
                code = err.get("code", "error")
                msg = err.get("message", text)
                return f"{code}: {msg}"
        except ValueError:
            pass
    return stderr.strip() or stdout.strip() or "unknown error"


class VaultWatcher:
    def __init__(self, cfg: Config) -> None:
        self.cfg = cfg
        self.pending: dict[Path, float] = {}
        self.inflight: dict[tuple[str, str, str], float] = {}
        self.wake_event = asyncio.Event()
        self.stop_event = asyncio.Event()

    def _prune_inflight(self, now: float) -> None:
        expired = [k for k, exp in self.inflight.items() if exp <= now]
        for k in expired:
            del self.inflight[k]

    def _build_body(self, matches: list[Match]) -> str:
        sop_path = self.cfg.vault / "93 Agents" / "AGENTS.md"
        sop_hint = " (follow 93 Agents/AGENTS.md)" if sop_path.is_file() else ""
        lines = [f"Pending AI tag(s) detected{sop_hint}:"]
        lines.extend(m.format_line() for m in matches)
        return "\n".join(lines)

    async def _dispatch(self, relpath: str, matches: list[Match]) -> bool:
        body = self._build_body(matches)
        cmd = [
            self.cfg.orca_bin,
            "orchestration",
            "send",
            "--from",
            self.cfg.from_handle,
            "--to",
            self.cfg.target,
            "--subject",
            relpath,
            "--body",
            body,
            "--json",
        ]

        if self.cfg.dry_run:
            log.info(
                "[dry-run] dispatch %s (%d match(es)) -> %s",
                relpath,
                len(matches),
                self.cfg.target,
            )
            for m in matches:
                log.info("  %s", m.format_line())
            return True

        try:
            proc = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                env=_sanitized_env(),
            )
        except OSError as exc:
            log.error(
                "dispatch failed (%s): could not execute %s: %s",
                relpath,
                self.cfg.orca_bin,
                exc,
            )
            return False

        try:
            raw_out, raw_err = await asyncio.wait_for(
                proc.communicate(), timeout=self.cfg.send_timeout
            )
        except asyncio.TimeoutError:
            proc.kill()
            await proc.wait()
            log.error(
                "dispatch timed out after %.1fs (%s)", self.cfg.send_timeout, relpath
            )
            return False

        stdout = raw_out.decode("utf-8", errors="replace")
        stderr = raw_err.decode("utf-8", errors="replace")

        parsed: dict | None = None
        first_line = stdout.strip().splitlines()[0] if stdout.strip() else ""
        if first_line:
            try:
                obj = json.loads(first_line)
                if isinstance(obj, dict):
                    parsed = obj
            except ValueError:
                pass

        if proc.returncode != 0 or (parsed is not None and parsed.get("ok") is False):
            detail = _extract_orca_error(stdout, stderr)
            log.error(
                "dispatch failed (%s, rc=%s): %s", relpath, proc.returncode, detail
            )
            return False

        msg_id = ""
        if parsed and isinstance(parsed.get("result"), dict):
            mid = parsed["result"].get("id") or parsed["result"].get("messageId")
            if mid:
                msg_id = f" id={mid}"
        log.info(
            "dispatched %s (%d match(es)) -> %s%s",
            relpath,
            len(matches),
            self.cfg.target,
            msg_id,
        )
        return True

    async def _scan_and_dispatch(self, path: Path, source: str) -> bool:
        matches = scan_file(path, self.cfg.vault)
        if not matches:
            return False

        now = time.monotonic()
        self._prune_inflight(now)
        fresh = [m for m in matches if m.key not in self.inflight]
        if not fresh:
            log.debug(
                "[%s] %s: %d match(es) already inflight",
                source,
                matches[0].relpath,
                len(matches),
            )
            return False

        relpath = fresh[0].relpath
        ok = await self._dispatch(relpath, fresh)
        if ok:
            exp = time.monotonic() + self.cfg.inflight_ttl
            for m in fresh:
                self.inflight[m.key] = exp
        return True

    async def _reconcile(self, respect_pending: bool = True) -> bool:
        now_wall = time.time()
        found = False
        for path in iter_vault_md_files(self.cfg.vault):
            if self.stop_event.is_set():
                return found
            if respect_pending and path in self.pending:
                continue
            if self.cfg.quiet_sec > 0:
                try:
                    mtime = path.stat().st_mtime
                except OSError:
                    continue
                if now_wall - mtime < self.cfg.quiet_sec:
                    continue
            if await self._scan_and_dispatch(path, source="reconcile"):
                found = True
        return found

    async def _watch_task(self) -> None:
        vault = self.cfg.vault

        def _filter(_change: Change, path_str: str) -> bool:
            return is_watched_md(Path(path_str), vault)

        try:
            async for changes in awatch(
                vault,
                watch_filter=_filter,
                debounce=300,
                step=100,
                stop_event=self.stop_event,
            ):
                now = time.monotonic()
                updated = False
                for change, path_str in changes:
                    p = Path(path_str)
                    if change == Change.deleted:
                        self.pending.pop(p, None)
                    elif is_watched_md(p, vault):
                        self.pending[p] = now + self.cfg.quiet_sec
                        updated = True
                if updated:
                    self.wake_event.set()
        finally:
            self.wake_event.set()

    async def run(self) -> None:
        loop = asyncio.get_running_loop()
        for sig in (signal.SIGINT, signal.SIGTERM):
            try:
                loop.add_signal_handler(sig, self._request_stop)
            except NotImplementedError:
                pass

        log.info(
            "starting vault=%s target=%s quiet=%.1fs reconcile=%.1f..%.1fs ttl=%.1fs%s",
            self.cfg.vault,
            self.cfg.target or "<dry-run>",
            self.cfg.quiet_sec,
            self.cfg.reconcile_sec,
            self.cfg.reconcile_max_sec,
            self.cfg.inflight_ttl,
            " [dry-run]" if self.cfg.dry_run else "",
        )

        if self.cfg.once:
            await self._reconcile(respect_pending=False)
            return

        reconcile_delay = self.cfg.reconcile_sec

        def _schedule_reconcile(found: bool) -> float:
            nonlocal reconcile_delay
            if found:
                reconcile_delay = self.cfg.reconcile_sec
                delay = reconcile_delay
            else:
                delay = reconcile_delay
                reconcile_delay = min(reconcile_delay * 2, self.cfg.reconcile_max_sec)
            log.debug("next reconcile in %.1fs", delay)
            return time.monotonic() + delay

        watcher = asyncio.create_task(self._watch_task(), name="watchfiles")
        try:
            next_reconcile = _schedule_reconcile(
                await self._reconcile(respect_pending=True)
            )

            while not self.stop_event.is_set():
                self.wake_event.clear()

                if watcher.done():
                    await watcher
                    break

                now = time.monotonic()
                due = [p for p, dl in list(self.pending.items()) if dl <= now]
                for p in due:
                    if self.stop_event.is_set():
                        break
                    if self.pending.get(p, float("inf")) <= time.monotonic():
                        self.pending.pop(p, None)
                        if await self._scan_and_dispatch(p, source="watch"):
                            reconcile_delay = self.cfg.reconcile_sec
                            next_reconcile = min(
                                next_reconcile, time.monotonic() + reconcile_delay
                            )

                if not self.stop_event.is_set() and time.monotonic() >= next_reconcile:
                    next_reconcile = _schedule_reconcile(
                        await self._reconcile(respect_pending=True)
                    )

                if self.stop_event.is_set():
                    break

                next_wakeup = min([next_reconcile, *self.pending.values()])
                timeout = max(0.05, next_wakeup - time.monotonic())
                try:
                    await asyncio.wait_for(self.wake_event.wait(), timeout=timeout)
                except asyncio.TimeoutError:
                    pass
        finally:
            self.stop_event.set()
            if not watcher.done():
                watcher.cancel()
                try:
                    await watcher
                except asyncio.CancelledError:
                    pass
            log.info("stopped")

    def _request_stop(self) -> None:
        self.stop_event.set()
        self.wake_event.set()


def parse_args(argv: list[str] | None = None) -> Config:
    default_vault = os.environ.get("VAULT_PATH") or str(
        Path.home() / "Documents" / "Obsidian" / "Apricity"
    )
    parser = argparse.ArgumentParser(
        description="Read-only Obsidian vault watcher dispatching bare AI tags to Orca."
    )
    parser.add_argument(
        "--vault",
        default=default_vault,
        help="Path to Obsidian vault (env: VAULT_PATH)",
    )
    parser.add_argument(
        "--to",
        default=os.environ.get("ORCA_TARGET", ""),
        help="Target Orca chat ID (`orca_session_id:<id>` or bare `<id>`, env: ORCA_TARGET)",
    )
    parser.add_argument(
        "--from",
        dest="from_handle",
        default=os.environ.get("ORCA_FROM", "vault-watcher"),
        help="Sender handle passed to `orca-ide orchestration send` (env: ORCA_FROM)",
    )
    parser.add_argument(
        "--orca-bin",
        default=default_orca_bin(),
        help="Path to `orca-ide` binary (env: ORCA_BIN)",
    )
    parser.add_argument(
        "--quiet-sec",
        type=float,
        default=float(os.environ.get("QUIET_SEC", "7")),
        help="Per-file quiet window in seconds before scanning (default: 7)",
    )
    parser.add_argument(
        "--reconcile-sec",
        type=float,
        default=float(os.environ.get("RECONCILE_SEC", "30")),
        help="Base reconcile interval in seconds (default: 30)",
    )
    parser.add_argument(
        "--reconcile-max-sec",
        type=float,
        default=float(os.environ.get("RECONCILE_MAX_SEC", "600")),
        help="Max reconcile interval in seconds when idle scans find nothing (default: 600)",
    )
    parser.add_argument(
        "--inflight-ttl",
        type=float,
        default=float(os.environ.get("INFLIGHT_TTL_SEC", "60")),
        help="In-memory inflight dedup TTL in seconds (default: 60)",
    )
    parser.add_argument(
        "--send-timeout",
        type=float,
        default=float(os.environ.get("ORCA_SEND_TIMEOUT", "30")),
        help="Timeout in seconds for `orca-ide orchestration send` (default: 30)",
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Log matches without calling orca-ide"
    )
    parser.add_argument(
        "--once", action="store_true", help="Run a single reconcile pass and exit"
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable debug logging"
    )

    args = parser.parse_args(argv)
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        stream=sys.stdout,
    )

    vault = Path(args.vault).expanduser().resolve()
    if not vault.is_dir():
        parser.error(f"vault directory does not exist: {vault}")

    target = normalize_target(args.to.strip())
    if not target and not args.dry_run:
        parser.error("--to (or ORCA_TARGET) is required unless --dry-run is set")

    if not args.dry_run and not shutil.which(args.orca_bin):
        log.warning("orca binary not found in PATH yet: %s", args.orca_bin)

    reconcile_sec = max(1.0, args.reconcile_sec)
    reconcile_max_sec = max(reconcile_sec, args.reconcile_max_sec)

    return Config(
        vault=vault,
        target=target,
        from_handle=args.from_handle,
        orca_bin=args.orca_bin,
        quiet_sec=max(0.0, args.quiet_sec),
        reconcile_sec=reconcile_sec,
        reconcile_max_sec=reconcile_max_sec,
        inflight_ttl=max(1.0, args.inflight_ttl),
        send_timeout=max(1.0, args.send_timeout),
        dry_run=args.dry_run,
        once=args.once,
    )


def main(argv: list[str] | None = None) -> int:
    cfg = parse_args(argv)
    asyncio.run(VaultWatcher(cfg).run())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
