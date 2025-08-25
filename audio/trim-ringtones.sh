#!/usr/bin/env bash
# Trim trailing near-silence from all MP3s in the current directory
# and save to ./trimmed with 1 second of pad added at the end.
#
# Tunables:
#   THRESH_DB  : silence threshold in dBFS (default: -45)
#   MIN_TAIL   : minimum duration of near-silence to remove (default: 0.10s)
#   HIGHPASS_HZ: if set (e.g., 40), apply high-pass filter before trimming

set -euo pipefail
shopt -s nullglob

out_dir="trimmed"
THRESH_DB="${THRESH_DB:--45}"
MIN_TAIL="${MIN_TAIL:-0.10}"
HIGHPASS_HZ="${HIGHPASS_HZ:-}"

command -v sox >/dev/null 2>&1 || { echo "Error: sox not found"; exit 1; }

mkdir -p "$out_dir"

processed=false
for f in *.mp3 *.MP3; do
  [ -e "$f" ] || continue
  processed=true

  base="$(basename "$f")"
  tmp1="$(mktemp -t sox1.XXXXXX).mp3"
  tmp2="$(mktemp -t sox2.XXXXXX).mp3"

  src="$f"

  # Optional high-pass cleanup
  if [[ -n "$HIGHPASS_HZ" ]]; then
    sox "$src" "$tmp1" highpass "$HIGHPASS_HZ"
    src="$tmp1"
  fi

  # Trim trailing near-silence (reverse → trim → reverse)
  sox "$src" "$tmp2" reverse silence 1 "$MIN_TAIL" "${THRESH_DB}d" reverse

  # Add exactly 1s pad at end
  sox "$tmp2" "$out_dir/$base" pad 0 1

  rm -f "$tmp1" "$tmp2"
  echo "Processed: $base → $out_dir/$base"
done

if ! $processed; then
  echo "No MP3 files found in current directory."
fi