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
    local json_test_codes={}
    for key in "${!test_codes[@]}"; do
        json_test_codes=$(
            jq -cn \
               --argjson json "$json_test_codes" \
               --arg key "$key" \
               --arg val "${test_codes["$key"]}" \
               '$json + {$key: $val}'
            )
    done
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
        local -i i=0
        local extra=''
        local -a json_arrays
        while IFS= read -r line; do
            if jq -e '.[0] == "extra"' <<< "$line" &>/dev/null; then
                extra+=$(jq -r '.[1]' <<< "$line")
                extra+=$'\n'
            elif jq -e '.[0] == "assert"' <<< "$line" &>/dev/null; then
                if (( ${#extra} > 500 )); then
                    extra="${extra:0:451}[Output was truncated. Please limit to 500 chars]"
                fi
                (( i++ ))
                json_arrays+=("$(
                  jq -r --arg extra "$extra" \
                    '[.[0],
                     (.[1] +
                     { "output":
                       if $extra == "" then null else $extra end })]' \
                      <<< "$line"
                  )")
                extra=''
            else
                json_arrays+=("$line")
            fi
        done < <(jq -c '.[]' <<< "${tap_content[0]}")
        printf '%s\n' "${json_arrays[@]}" |
        jq --slurp \
           --arg status "$status" \
           --argjson test_codes "$json_test_codes" \
           '
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
        '
    fi
}

extract_test_codes
tap_parser
