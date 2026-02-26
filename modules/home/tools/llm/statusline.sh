#!/usr/bin/env bash
input=$(cat)

user=$(whoami)
host=$(hostname -s)

# Parse JSON without jq
cwd=$(echo "$input" | grep -o '"current_dir":"[^"]*"' | head -1 | sed 's/"current_dir":"//;s/"$//')
model=$(echo "$input" | grep -o '"display_name":"[^"]*"' | head -1 | sed 's/"display_name":"//;s/"$//')
used=$(echo "$input" | grep -o '"used_percentage":[0-9]*' | sed 's/"used_percentage"://')

# Shorten home directory to ~
if [ -n "$cwd" ]; then
  cwd="${cwd/#$HOME/\~}"
fi

# Colors via tput
green=$(tput setaf 2)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

# Build the status line
parts=()
parts+=("${green}${user}@${host}${reset}")
[ -n "$cwd" ] && parts+=("${blue}${cwd}${reset}")
[ -n "$model" ] && parts+=("${magenta}${model}${reset}")
[ -n "$used" ] && parts+=("${yellow}ctx:${used}%${reset}")

printf '%s' "${parts[*]}"
