#!/bin/bash

RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
RESET="\033[0m"

print_green() {
    echo -e "${GREEN}${1}${RESET}"
}

# Set SRC
SRC=/opt/src

if [[ -z "${CI_PROJECT_DIR}" ]]; then
    SRC=/opt/src
else
    SRC="${CI_PROJECT_DIR}"
    OUTPUT=$SRC
fi

if [ -z $LANGUAGE ]
then
        if [ ! -z $CI_PROJECT_REPOSITORY_LANGUAGES ]
        then
            LANGUAGES=(${CI_PROJECT_REPOSITORY_LANGUAGES//,/ })
            LANGUAGE=${LANGUAGES[0]}
        else
            LANGUAGE=$(github-linguist $SRC| awk 'FNR <= 1' | rev | cut -d' ' -f 1 | rev)
        fi
fi

# Set options
LANGUAGE=${LANGUAGE,,}
if [[ "$LANGUAGE" == "python" || "$LANGUAGE" == "javascript" || "$LANGUAGE" == "cpp" || "$LANGUAGE" == "csharp" || "$LANGUAGE" == "java" || "$LANGUAGE" == "go" || "$LANGUAGE" == "typescript" ]]
then
    if [[ "$LANGUAGE" == "typescript" ]]
    then
        LANGUAGE="javascript"
    fi
    echo "$LANGUAGE"
else
        echo "[!] Invalid language: $LANGUAGE"
        exit 3
fi

if [ -z $FORMAT ]
then
    FORMAT="sarif-latest"
fi

if [ -z $QS ]
then
    QS="$LANGUAGE-security-extended.qls"
fi

if [ -z $OUTPUT ]
then
    OUTPUT="/opt/results"
fi

if [ -z $THREADS ]
then
    THREADS="0"
fi

if [[ $COMMAND ]]
then
    COMMAND="--command='${COMMAND}'"
fi

DB=$OUTPUT/codeql-db

# Set THREADS

# Show execution information
echo "----------------"
print_green " [+] Language: $LANGUAGE"
print_green " [+] Query-suites: $QS"
print_green " [+] Database: $DB"
print_green " [+] Source: $SRC"
print_green " [+] Output: $OUTPUT"
print_green " [+] Format: $FORMAT"
echo "----------------"

# Check action
if [ -z $ACTION ]
then
    ACTION='all'
fi

# Functions
create_database() {
    print_green "Creating DB: codeql database create --threads=$THREADS --language=$LANGUAGE $COMMAND $DB -s $SRC $OVERWRITE_FLAG"
    codeql database create --threads=$THREADS --language=$LANGUAGE $COMMAND $DB -s $SRC $OVERWRITE_FLAG
}

scan() {
    print_green "Start Scanning: codeql database analyze --format=$FORMAT --threads=$THREADS $SAVE_CACHE_FLAG --output=$OUTPUT/issues.$FORMAT $DB $QS"
    codeql database analyze --format=$FORMAT --threads=$THREADS $SAVE_CACHE_FLAG --output=$OUTPUT/issues.$FORMAT $DB $QS
}

convert_sarif_to_sast() {
    print_green "Convert SARIF to SAST: python3 /root/scripts/sarif2sast.py $OUTPUT/issues.$FORMAT -o $OUTPUT/gl-sast-report.json"
    python3 /root/scripts/sarif2sast.py $OUTPUT/issues.$FORMAT -o $OUTPUT/gl-sast-report.json
    if [[ "$FORMAT" == "sarif"* ]]; then
        mv $OUTPUT/issues.$FORMAT $OUTPUT/issues.sarif
    fi
}

finalize() {
    if [ ! -z $USERID ]
    then
        chown -R $USERID:$GROUPID $OUTPUT
    fi
}

main() {
    if [ "$ACTION" == 'create-database-only' ]; then
        create_database
    else
        create_database
        scan
        convert_sarif_to_sast
    fi
    finalize
}

# Main
main

