#!/usr/bin/env bash
# dl -- download any video/audio from any site via yt-dlp
# Usage: dl <URL> [OPTIONS]
#        dl --batch <FILE> [OPTIONS]

set -euo pipefail

# -- Defaults -----------------------------------------------------------------
FORMAT="mp4"
OUTPUT_DIR="${DL_DIR:-$HOME/Downloads}"
COPY_PATH=false
NOTIFY=false
ANY_CODEC=false
BATCH_FILE=""
URL=""

# -- Help ---------------------------------------------------------------------
usage() {
  cat <<EOF
Usage:
  dl <URL> [OPTIONS]
  dl --batch <FILE> [OPTIONS]

Video formats:
  --mp4             H.264/MP4 (default, widest compat)
  --mkv             Best quality MKV, any codec (remux, no re-encode)
  --webm            WebM (remux)
  --avi             AVI (remux)
  --mov             MOV (remux)
  --flv             FLV (remux)
  --ts              MPEG-TS (remux)
  --any-codec       With --mp4: allow HEVC/AV1 instead of forcing H.264

Audio formats:
  --mp3             MP3
  --ogg             OGG Vorbis
  --opus            Opus
  --flac            FLAC
  --wav             WAV
  --m4a             M4A (AAC)
  --aac             AAC

Options:
  --batch FILE      Read URLs from file (one per line, invalid lines skipped)
  -o, --output DIR  Output directory (default: \$DL_DIR or ~/Downloads)
  -c, --copy        Copy final file path to clipboard (requires wl-copy/xclip)
  -n, --notify      Send desktop notification when done (requires notify-send)
  -h, --help        Show this help

Environment:
  DL_DIR            Default download directory (overridden by -o)

Examples:
  dl 'https://youtu.be/dQw4w9WgXcQ' --mp3
  dl 'https://youtu.be/dQw4w9WgXcQ' --mkv -o ~/Videos
  dl 'https://youtu.be/dQw4w9WgXcQ' --mp4 --any-codec
  dl --batch urls.txt --mp3 -o ~/Music
EOF
  exit 0
}

# -- Arg parsing --------------------------------------------------------------
[[ $# -eq 0 ]] && usage

while [[ $# -gt 0 ]]; do
  case "$1" in
    http://*|https://*)   URL="$1" ;;
    --mp4)                FORMAT="mp4" ;;
    --mkv)                FORMAT="mkv" ;;
    --webm)               FORMAT="webm" ;;
    --avi)                FORMAT="avi" ;;
    --mov)                FORMAT="mov" ;;
    --flv)                FORMAT="flv" ;;
    --ts)                 FORMAT="ts" ;;
    --mp3)                FORMAT="mp3" ;;
    --ogg)                FORMAT="ogg" ;;
    --opus)               FORMAT="opus" ;;
    --flac)               FORMAT="flac" ;;
    --wav)                FORMAT="wav" ;;
    --m4a)                FORMAT="m4a" ;;
    --aac)                FORMAT="aac" ;;
    --any-codec)          ANY_CODEC=true ;;
    --batch)              shift; BATCH_FILE="$1" ;;
    -o|--output)          shift; OUTPUT_DIR="$1" ;;
    -c|--copy)            COPY_PATH=true ;;
    -n|--notify)          NOTIFY=true ;;
    -h|--help)            usage ;;
    *)                    echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
  shift
done

# -- Validation ---------------------------------------------------------------
if ! command -v yt-dlp &>/dev/null; then
  echo "Error: yt-dlp is not installed." >&2
  echo "Install: sudo pacman -S yt-dlp" >&2
  exit 1
fi

if [[ -n "$BATCH_FILE" && -n "$URL" ]]; then
  echo "Error: cannot use --batch and a URL at the same time." >&2
  exit 1
fi

if [[ -z "$BATCH_FILE" && -z "$URL" ]]; then
  echo "Error: no URL or --batch file provided." >&2
  echo "Run: dl --help" >&2
  exit 1
fi

if [[ -n "$BATCH_FILE" && ! -f "$BATCH_FILE" ]]; then
  echo "Error: batch file not found: $BATCH_FILE" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# -- Build yt-dlp args --------------------------------------------------------
build_args() {
  local -n _args=$1   # nameref to the caller's array

  _args=(
    --newline
    -o "${OUTPUT_DIR}/%(title)s.%(ext)s"
  )

  case "$FORMAT" in
    mp3|ogg|opus|flac|wav|m4a|aac)
      _args+=(
        -x
        --audio-format "$FORMAT"
        --audio-quality 0
      )
      ;;
    mp4)
      # Grab best streams then remux; force H.264 unless --any-codec
      if $ANY_CODEC; then
        _args+=(
          -f "bestvideo+bestaudio/best"
          --remux-video mp4
        )
      else
        _args+=(
          -f "bestvideo[vcodec^=avc]+bestaudio/bestvideo[vcodec^=avc]+bestaudio[ext=m4a]/best[vcodec^=avc]/best"
          --remux-video mp4
        )
      fi
      ;;
    mkv|webm|avi|mov|flv|ts)
      # Best quality, remux into target container (no re-encode)
      _args+=(
        -f "bestvideo+bestaudio/best"
        --remux-video "$FORMAT"
      )
      ;;
  esac
}

# -- Single download ----------------------------------------------------------
download_one() {
  local url="$1"
  local label
  label=$(basename "$url")

  echo "  Downloading ${label} as ${FORMAT^^} -> ${OUTPUT_DIR}"
  echo ""

  local YTDLP_ARGS=()
  build_args YTDLP_ARGS

  local TMPFILE
  TMPFILE=$(mktemp)
  yt-dlp "${YTDLP_ARGS[@]}" --print-to-file after_move:filepath "$TMPFILE" "$url"
  local FINAL_FILE
  FINAL_FILE=$(tail -n1 "$TMPFILE")
  rm -f "$TMPFILE"

  echo ""

  if [[ -z "$FINAL_FILE" || ! -f "$FINAL_FILE" ]]; then
    echo "  Warning: could not determine output path." >&2
    FINAL_FILE="$OUTPUT_DIR"
  fi

  echo "  Done: $FINAL_FILE"

  if $COPY_PATH; then
    if command -v wl-copy &>/dev/null; then
      echo -n "$FINAL_FILE" | wl-copy
      echo "  Path copied to clipboard (wl-copy)"
    elif command -v xclip &>/dev/null; then
      echo -n "$FINAL_FILE" | xclip -selection clipboard
      echo "  Path copied to clipboard (xclip)"
    else
      echo "  Warning: --copy requires wl-copy or xclip" >&2
    fi
  fi

  if $NOTIFY; then
    if command -v notify-send &>/dev/null; then
      notify-send --app-name="dl" --icon=folder-download \
        "Download complete" "$(basename "$FINAL_FILE")"
    else
      echo "  Warning: --notify requires notify-send" >&2
    fi
  fi
}

# -- Batch download -----------------------------------------------------------
download_batch() {
  local file="$1"
  local total=0 ok=0 skipped=0 failed=0
  local line lineno=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    (( lineno++ )) || true
    # Strip leading/trailing whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    # Skip blank lines and comments
    if [[ -z "$line" || "$line" == \#* ]]; then
      continue
    fi

    # Skip non-URLs
    if [[ "$line" != http://* && "$line" != https://* ]]; then
      echo "  [line ${lineno}] Skipping (not a URL): $line"
      (( skipped++ )) || true
      continue
    fi

    (( total++ )) || true
    echo ""
    echo "  [$total] $line"

    if download_one "$line"; then
      (( ok++ )) || true
    else
      echo "  [line ${lineno}] Failed: $line" >&2
      (( failed++ )) || true
    fi

  done < "$file"

  echo ""
  echo "  Batch done: ${ok} downloaded, ${skipped} skipped, ${failed} failed"
}

# -- Entry point --------------------------------------------------------------
if [[ -n "$BATCH_FILE" ]]; then
  echo "  Batch mode: $BATCH_FILE -> ${OUTPUT_DIR} [${FORMAT^^}]"
  download_batch "$BATCH_FILE"
else
  download_one "$URL"
fi
