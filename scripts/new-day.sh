#!/usr/bin/env sh

# abort if $1 is empty
if [ $# -eq 0 ]; then
    >&2 echo "No arguments provided, expected two digit number for the date!"
    exit 1
fi

SCRIPT_DIR=$(dirname "$0")
ROOT_DIR=$(dirname $SCRIPT_DIR)
SOURCES_DIR="$ROOT_DIR/Sources"
INPUTS_DIR="$SOURCES_DIR/inputs"

cp "$INPUTS_DIR/day_00-1.test.txt" "$INPUTS_DIR/day_$1-1.test.txt"
cp "$INPUTS_DIR/day_00-1.txt" "$INPUTS_DIR/day_$1-1.txt"

cat "$SOURCES_DIR/DayTemplate.swift" \
  | sed "s/DayTemplate00Part1/Day${1}Part1/g" \
  | sed "s/00/$1/g" \
  | sed "s/day: Int = 0/day: Int = $1/g" > "$SOURCES_DIR/Day $1.swift"
