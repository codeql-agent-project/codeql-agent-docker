#!/bin/bash

RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
RESET="\033[0m"

SupportedLanguage=("python" "javascript" "cpp" "csharp" "java" "go" "typescript" "c")

print_green() {
    echo -e "${GREEN}${1}${RESET}"
}

print_red() {
    echo -e "${RED}${1}${RESET}"
}

# Set SRC
SRC=/opt/src

if [[ -z "${CI_PROJECT_DIR}" ]]; then
    SRC=/opt/src
else
    SRC="${CI_PROJECT_DIR}"
    OUTPUT=$SRC
fi

if [ ! -d "$SRC" ]; then
    print_red "Error: ${SRC} not found. Can not continue."
    exit 3
fi

if [ -z $LANGUAGE ]
then
        if [ ! -z $CI_PROJECT_REPOSITORY_LANGUAGES ]
        then
            ListLanguages=(${CI_PROJECT_REPOSITORY_LANGUAGES//,/ })
        else
            mapfile -t ListLanguages <<< $(github-linguist $SRC)
        fi
        for val in "${ListLanguages[@]}"; do
            lang="$(echo $val | rev | cut -d' ' -f 1 | rev)"
            lang=${lang,,}
            if [[ "${SupportedLanguage[*]}" =~ "${lang}" ]]; then
                    LANGUAGE=$lang
                    break
            fi
        done
        if [[ $LANGUAGE == "" ]]; then
            print_red "[!] Can not auto detect language. Please check the source code or specify the LANGUAGE variable."
            exit 4
        fi
fi

# Set options
LANGUAGE=${LANGUAGE,,}
if [[ "$LANGUAGE" == "python" || "$LANGUAGE" == "javascript" || "$LANGUAGE" == "cpp" || "$LANGUAGE" == "csharp" || "$LANGUAGE" == "java" || "$LANGUAGE" == "go" || "$LANGUAGE" == "typescript" || "$LANGUAGE" == "c" ]]
then
    if [[ "$LANGUAGE" == "typescript" ]]
    then
        LANGUAGE="javascript"
    fi
    if [[ "$LANGUAGE" == "c" ]]
    then
        LANGUAGE="cpp"
    fi
    echo "$LANGUAGE"
else
        echo "[!] Invalid language: $LANGUAGE"
        exit 5
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
    if [ $? -ne 0 ]; then
        print_red "[!] Codeql create database failed."
        exit 6
    fi
}

scan() {
    print_green "Start Scanning: codeql database analyze --format=$FORMAT --threads=$THREADS $SAVE_CACHE_FLAG --output=$OUTPUT/issues.$FORMAT $DB $QS"
    codeql database analyze --format=$FORMAT --threads=$THREADS $SAVE_CACHE_FLAG --output=$OUTPUT/issues.$FORMAT $DB $QS
    if [ $? -ne 0 ]; then
        print_red "[!] CodeQL analyze failed."
        exit 7
    fi
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

