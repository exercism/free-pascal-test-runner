#!/usr/bin/env bash

# Synopsis:
# Run the test runner on a solution.

# Arguments:
# $1: exercise slug
# $2: path to solution folder
# $3: path to output directory

# Output:
# Writes the test results to a results.json file in the passed-in output directory.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Example:
# ./bin/run.sh two-fer path/to/solution/folder/ path/to/output/directory/

# If any required arguments is missing, print the usage and exit
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "usage: ./bin/run.sh exercise-slug path/to/solution/folder/ path/to/output/directory/"
    exit 1
fi

declare -r bin_dir="$(dirname $(realpath "$0"))"
declare -r slug="$1"
declare -r solution_dir="$(realpath "${2%/}")"
declare -r output_dir="$(realpath "${3%/}")"
declare -r tap_file="${output_dir}/tap.json"
declare -r results_file="${output_dir}/results.json"
declare -r test_file="${solution_dir}/TestCases.pas"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

echo "${slug}: testing..."

# Run the tests and generete results
cd "$solution_dir" || exit 1

make test=all 2>&1 | tap-parser -j 0 > "$tap_file"

"${bin_dir}/results-generator.sh" "$test_file" "$tap_file" > "$results_file"

echo "${slug}: done"
