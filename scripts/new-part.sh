#!/usr/bin/env sh

# abort if $1 is empty
if [ $# -eq 0 ]; then
    >&2 echo "No arguments provided, expected two digit number for the date!"
    exit 1
fi
if [ $# -eq 1 ]; then
    >&2 echo "Missing argument: expected a one-digit part number!"
    exit 1
fi

SCRIPT_DIR=$(dirname "$0")
ROOT_DIR=$(dirname $SCRIPT_DIR)
SOURCES_DIR="$ROOT_DIR/Sources"
INPUTS_DIR="$SOURCES_DIR/inputs"

# Echo every command
set -x

cp "$INPUTS_DIR/day_$1-1.test.txt" "$INPUTS_DIR/day_$1-$2.test.txt"
cp "$INPUTS_DIR/day_$1-1.txt" "$INPUTS_DIR/day_$1-$2.txt"

CODE_FILE="$SOURCES_DIR/Day $1.swift"

cat "$SOURCES_DIR/DayTemplate.swift" \
  | sed "s/DayTemplate00Part1/Day${1}Part$2/g" \
  | sed "s/import Foundation/ /g" \
  | sed "s/00/$1/g" \
  | sed "s/day: Int = 0/day: Int = $1/g" \
  | sed "s/part: Int = 1/part: Int = $2/g" >> "$CODE_FILE"

set +x
echo "+  >> \"$SOURCES_DIR/Day $1.swift\""