#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
codex_home="${CODEX_HOME:-"$HOME/.codex"}"
target_dir="$codex_home/skills"
skills=(rln semaphore tlsnotary)

mkdir -p "$target_dir"

for skill in "${skills[@]}"; do
  source_dir="$repo_root/skills/$skill"
  target="$target_dir/$skill"

  if [[ ! -d "$source_dir" ]]; then
    echo "missing source skill: $source_dir" >&2
    exit 1
  fi

  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "refusing to replace non-symlink: $target" >&2
    exit 1
  fi

  ln -sfn "$source_dir" "$target"
  echo "$skill -> $source_dir"
done

echo "installed local zk-skills into $target_dir"
