#!/bin/bash

RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
RESET="\033[0m"

print_green() {
    echo -e "${GREEN}${1}${RESET}"
}

SRC=/opt/src

if [ -z $LANGUAGE ]
then
        LANGUAGES=(${CI_PROJECT_REPOSITORY_LANGUAGES//,/ })
        LANGUAGE=${LANGUAGES[0]}
fi

if [[ "$LANGUAGE" == "python" || "$LANGUAGE" == "javascript" || "$LANGUAGE" == "c" || "$LANGUAGE" == "csharp" || "$LANGUAGE" == "java" || "$LANGUAGE" == "go" ]]
then
        echo "$LANGUAGE"
else
        echo "[!] Invalid language: $LANGUAGE"
        exit 3
fi

if [[ -z "${CI_PROJECT_DIR}" ]]; then
    SRC=/opt/src
else
    SRC="${CI_PROJECT_DIR}"
fi

if [ -z $FORMAT ]
then
    FORMAT="sarif-latest"
fi

if [ -z $QS ]
then
    QS="$LANGUAGE-code-scanning.qls"
fi

if [ -z $OUTPUT ]
then
    OUTPUT="$SRC"
fi


DB=$SRC/codeql-db

echo "----------------"
print_green " [+] Language: $LANGUAGE"
print_green " [+] Query-suites: $QS"
print_green " [+] Database: $DB"
print_green " [+] Source: $SRC"
print_green " [+] Output: $OUTPUT"
print_green " [+] Format: $FORMAT"
echo "----------------"

# cp /root/scripts/gl-sast-report.json $OUTPUT/gl-sast-report.json
# cat $OUTPUT/gl-sast-report.json
# ls

print_green "Creating DB: codeql database create --language=$LANGUAGE $DB -s $SRC"
codeql database create --language=$LANGUAGE $DB -s $SRC

print_green "Start Scanning: codeql database analyze --format=$FORMAT --output=$OUTPUT/issues.$FORMAT $DB $QS"
codeql database analyze --format=$FORMAT --output=$OUTPUT/issues.$FORMAT $DB $QS

print_green "Convert SARIF to SAST: python3 /root/scripts/sarif2sast.py $OUTPUT/issues.$FORMAT -o $OUTPUT/gl-sast-report.json"
python3 /root/scripts/sarif2sast.py $OUTPUT/issues.$FORMAT -o $OUTPUT/gl-sast-report.json