#!/usr/bin/env bash

set -euo pipefail

input_dir='.'
output_file='Kaamelott Livre II - Tome 2.mkv'

usage() {
  cat <<'EOF'
Usage: ./script.sh [--input-dir DIR] [--output-file NAME]

Merges all MKV files in DIR into one MKV and adds one chapter per file.
EOF
}

escape_concat_path() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e "s/'/\\\\'/g"
}

escape_ffmetadata_value() {
  local value=$1
  value=${value//$'\r'/}
  value=${value//$'\n'/ }
  value=${value//\\/\\\\}
  value=${value//=/\=}
  value=${value//;/\;}
  value=${value//#/\#}
  printf '%s' "$value"
}

while (($#)); do
  case "$1" in
    -i|--input-dir)
      [[ $# -ge 2 ]] || { echo 'Missing value for --input-dir' >&2; usage; exit 1; }
      input_dir=$2
      shift 2
      ;;
    -o|--output-file)
      [[ $# -ge 2 ]] || { echo 'Missing value for --output-file' >&2; usage; exit 1; }
      output_file=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

command -v ffmpeg >/dev/null 2>&1 || { echo 'ffmpeg is required but was not found in PATH.' >&2; exit 1; }
command -v ffprobe >/dev/null 2>&1 || { echo 'ffprobe is required but was not found in PATH.' >&2; exit 1; }

if [[ ! -d "$input_dir" ]]; then
  echo "Input directory does not exist: $input_dir" >&2
  exit 1
fi

input_dir=$(cd "$input_dir" && pwd -P)
output_path="$input_dir/$output_file"

shopt -s nullglob
LC_ALL=C
mkv_files=("$input_dir"/*.mkv)

if (( ${#mkv_files[@]} == 0 )); then
  echo "No MKV files were found in: $input_dir" >&2
  exit 1
fi

generate_concat_list() {
  local file
  for file in "${mkv_files[@]}"; do
    printf "file '%s'\n" "$(escape_concat_path "$file")"
  done
}

generate_chapters() {
  local start_time_ms=0
  local file duration_text duration_ms end_time_ms chapter_title

  printf ';FFMETADATA1\n'

  for file in "${mkv_files[@]}"; do
    duration_text=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")

    if [[ ! $duration_text =~ ^[0-9]+([.][0-9]+)?$ ]]; then
      echo "Unable to read duration for: $file" >&2
      exit 1
    fi

    duration_ms=$(awk -v d="$duration_text" 'BEGIN { printf "%.0f", d * 1000 }')
    end_time_ms=$((start_time_ms + duration_ms))
    chapter_title=$(escape_ffmetadata_value "$(basename "${file%.*}")")

    printf '[CHAPTER]\n'
    printf 'TIMEBASE=1/1000\n'
    printf 'START=%s\n' "$start_time_ms"
    printf 'END=%s\n' "$end_time_ms"
    printf 'title=%s\n' "$chapter_title"

    start_time_ms=$end_time_ms
  done
}

ffmpeg -y -f concat -safe 0 -i <(generate_concat_list) -i <(generate_chapters) -map_metadata 1 -c copy "$output_path"