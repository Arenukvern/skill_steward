#!/usr/bin/env bash
# Prints the next 4-digit ADR number for a decision log directory.
# Usage: next-adr-number.sh [path]
# Example: next-adr-number.sh docs/decisions
set -euo pipefail

DIR="${1:-docs/decisions}"

if [[ ! -d "$DIR" ]]; then
  echo "0001" >&2
  echo "Directory $DIR does not exist; suggesting 0001" >&2
  exit 0
fi

max=0
shopt -s nullglob
for f in "$DIR"/[0-9][0-9][0-9][0-9]-*.md; do
  [[ -f "$f" ]] || continue
  base=$(basename "$f")
  num=${base%%-*}
  if [[ "$num" =~ ^[0-9]+$ ]] && ((10#$num > max)); then
    max=$((10#$num))
  fi
done

next=$((max + 1))
printf '%04d\n' "$next"
