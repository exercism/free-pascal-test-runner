#!/usr/bin/env bash

declare -r test_file="$1"
declare -r tap_file="$2"
declare -A test_codes=()

extract_test_codes () {
    local state='out'
    local proc_re='^procedure[[:blank:]]+[0-9A-Za-z_]+\.([0-9A-Za-z_]+);$'
    local end_re='^end;$'
    local name
    local body
    while IFS= read -r line; do
        if [[ "$state" == 'in' ]]; then
            printf -v body $'%s\n%s' "$body" "$line"
            if [[ "$line" =~ $end_re ]]; then
                state='out'
                body="${body#*;$'\n'}"
                body="${body%end;}"
                body="${body#$'\n'}"
                body="${body%$'\n'}"
                test_codes["$name"]="$body"
            fi
        elif [[ "$line" =~ $proc_re ]]; then
            state='in'
            name="${BASH_REMATCH[1]}"
            body="$line"
        fi
    done < "$test_file"
}

tap_parser() {
    # Build the test code lookup with one jq call. Starting jq once per test
    # took a few milliseconds each time, which added up on long test files.
    local -a test_code_args=()
    for key in "${!test_codes[@]}"; do
        test_code_args+=("$key" "${test_codes["$key"]}")
    done
    local json_test_codes
    json_test_codes=$(
        jq -cn '$ARGS.positional as $a |
                [range(0; $a | length; 2) | {($a[.]): $a[. + 1]}] | add // {}' \
           --args "${test_code_args[@]}"
    )
    local -a tap_content
    tap_content=$(< "$tap_file")
    local -r status="$(jq -r '
      map(select(.[0] == "assert")) as $asserts |
      if ($asserts | length) > 0 and all($asserts[] | .[1].ok) then
        "pass"
      else
        "fail"
      end
    ' <<< "${tap_content[0]}"
    )"

    if [[ "$status" != "pass" ]] && \
           jq -e \
              '.[] |
              select(.[0] == "plan" and .[1].comment == "no tests found") |
              length > 0' <<< "${tap_content[0]}" &>/dev/null;
    then
        jq -r '
        {
          "version": 3,
          "status" : "error",
          "message": (map(select(.[0] == "extra") | .[1]) | join("")[0:65535])
        }' <<< "${tap_content[0]}"
    else
        # Attach the output printed before each assert to that assert, in one
        # jq call. This used to start several jq processes for every line of
        # TAP, which took about 2 s for an exercise with 95 tests.
        # Each piece of output loses its trailing newlines and gains one
        # newline. Output over 500 bytes is cut to its first 451 bytes.
        jq --arg status "$status" \
           --argjson test_codes "$json_test_codes" \
           '
        def first_bytes($n):
          reduce explode[] as $c ({s: [], n: 0, full: false};
            if .full then . else
              ([$c] | implode | utf8bytelength) as $b |
              if .n + $b > $n then .full = true
              else .s += [$c] | .n += $b end
            end) | .s | implode;
        reduce .[] as $entry ({extra: "", entries: []};
          if $entry[0] == "extra" then
            .extra += ($entry[1] | if type == "string" then . else tojson end
                       | sub("\n+$"; "")) + "\n"
          elif $entry[0] == "assert" then
            (if (.extra | utf8bytelength) > 500 then
               (.extra | first_bytes(451)) +
                 "[Output was truncated. Please limit to 500 chars]"
             else .extra end) as $output |
            .entries += [[$entry[0],
                          ($entry[1] +
                           { "output":
                             if $output == "" then null else $output end })]] |
            .extra = ""
          else
            .entries += [$entry]
          end) | .entries |
        {
          "version": 3,
          "status" : $status,
          "message": null
        } + {
        "tests": [
            .[] | select(.[0] == "assert") | .[1] |
            if .name == "Please implement your solution." then
              { "name": .name, status: "error", test_code: "", message: .name }
            elif .ok == true then
              { "name": .name, status: "pass" }
            elif .diag.severity == "fail" then
              {
                "name": .diag.message,
                "status": .diag.severity,
                "output": .output,
                "test_code": $test_codes[.name],
                "message": "GOT:"    + (.diag.data.got|tostring) + "\n" +
                           "EXPECT:" + (.diag.data.expect|tostring),
              }
            else
              {
                "name": .name,
                "status": .diag.severity,
                "output": .output,
                "message": .diag.message,
                "test_code": $test_codes[.name]
              }
            end
          ]
        }
        ' <<< "${tap_content[0]}"
    fi
}

extract_test_codes
tap_parser
