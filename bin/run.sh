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

# Use the helper units compiled at image build when the solution's copies
# match them exactly. The compiler reuses a compiled unit only when its
# source file has the same modification time as the one it was compiled
# from, so the solution's copies are given the times of the image's copies.
# Any other version of lib/ is compiled as before.
declare -r precompiled_dir="${bin_dir}/../precompiled"
if cmp -s lib/FPCUnitTestUtils.pas "${precompiled_dir}/FPCUnitTestUtils.pas" &&
   cmp -s lib/FPCUnitTAPReporter.pas "${precompiled_dir}/FPCUnitTAPReporter.pas"; then
    touch -r "${precompiled_dir}/FPCUnitTestUtils.pas" lib/FPCUnitTestUtils.pas
    touch -r "${precompiled_dir}/FPCUnitTAPReporter.pas" lib/FPCUnitTAPReporter.pas
    mkdir -p build
    cp "${precompiled_dir}"/*.ppu "${precompiled_dir}"/*.o build/
fi

make test=all 2>&1 | tap-parser -j 0 > "$tap_file"

"${bin_dir}/results-generator.sh" "$test_file" "$tap_file" > "$results_file"

echo "${slug}: done"
