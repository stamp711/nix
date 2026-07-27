# Absolute path of the file codex just touched, or nothing.
# Codex names it only inside the patch, and relative to cwd.
#   {"cwd": "/home/stamp/.slock/agents/<id>",
#    "tool_input": {"command": "*** Begin Patch\n*** Add File: src/main.rs\n…"}}
. as $in
| (first(($in.tool_input.command // "") | scan("\\*\\*\\* (?:Add|Update|Delete) File: ([^\n]+)") | .[0])
   // empty) as $p
| if ($p | startswith("/")) then $p else (($in.cwd // "") + "/" + $p) end
