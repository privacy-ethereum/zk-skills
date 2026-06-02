#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
codex_home="${CODEX_HOME:-"$HOME/.codex"}"
target_dir="$codex_home/skills"
skills=(rln semaphore tlsnotary)

for skill in "${skills[@]}"; do
  target="$target_dir/$skill"
  expected="$repo_root/skills/$skill"

  if [[ ! -e "$target" && ! -L "$target" ]]; then
    echo "not installed: $skill"
    continue
  fi

  if [[ ! -L "$target" ]]; then
    echo "skipping non-symlink: $target" >&2
    continue
  fi

  actual="$(readlink "$target")"
  if [[ "$actual" != "$expected" ]]; then
    echo "skipping symlink with unexpected target: $target -> $actual" >&2
    continue
  fi

  rm "$target"
  echo "removed: $skill"
done

echo "uninstalled local zk-skills from $target_dir"
