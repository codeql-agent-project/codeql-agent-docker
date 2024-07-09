#!/bin/bash
SupportedLanguage=("go", "java", "cpp", "csharp", "python", "javascript", "ruby")

print_green() {
    echo -e "${GREEN}${1}${RESET}"
}

print_red() {
    echo -e "${RED}${1}${RESET}"
}

# Set SRC
SRC=/opt/src

# Check if JAVA_HOME is set and not empty
if [ -n "$JAVA_HOME" ]; then
    echo "JAVA_HOME is set to $JAVA_HOME"
    # Check and add JAVA_HOME/jre/bin to PATH if it exists
    if [ -d "$JAVA_HOME/jre/bin" ]; then
        export PATH="$JAVA_HOME/jre/bin:$PATH"
    fi
    # Check and add JAVA_HOME/bin to PATH if it exists
    if [ -d "$JAVA_HOME/bin" ]; then
        export PATH="$JAVA_HOME/bin:$PATH"
    fi
else
    echo "JAVA_HOME is not set or empty. Use default."
fi

# Check if MAVEN_HOME is set and not empty
if [ -n "$MAVEN_HOME" ]; then
    echo "MAVEN_HOME is set to $MAVEN_HOME"
    # Check and add MAVEN_HOME/bin to PATH if it exists
    if [ -d "$MAVEN_HOME/bin" ]; then
        export PATH="$MAVEN_HOME/bin:$PATH"
    fi
else
    echo "MAVEN_HOME is not set or empty. Use default."
fi

if [[ -z "${CI_PROJECT_DIR}" ]]; then
    SRC=/opt/src
else
    SRC="${CI_PROJECT_DIR}"
    # OUTPUT=$SRC
    RED="\033[31m"
    YELLOW="\033[33m"
    GREEN="\033[32m"
    RESET="\033[0m"
fi

if [ ! -d "$SRC" ]; then
    print_red "[Error]: ${SRC} not found. Can not continue."
    # finalize
    exit 3
fi

if [ -z $LANGUAGE ]; then
    if [ ! -z $CI_PROJECT_REPOSITORY_LANGUAGES ]; then
        ListLanguages=(${CI_PROJECT_REPOSITORY_LANGUAGES//,/ })
    else
        chown -R $(id -u):$(id -g) $SRC
        mapfile -t ListLanguages <<<$(github-linguist $SRC)
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
        # finalize
        exit 4
    fi
fi

# Set options
LANGUAGE=${LANGUAGE,,}
if [[ "$LANGUAGE" == "python" || "$LANGUAGE" == "javascript" || "$LANGUAGE" == "cpp" || "$LANGUAGE" == "csharp" || "$LANGUAGE" == "java" || "$LANGUAGE" == "go" || "$LANGUAGE" == "typescript" || "$LANGUAGE" == "c" || "$LANGUAGE" == "ruby" ]]; then
    if [[ "$LANGUAGE" == "typescript" ]]; then
        LANGUAGE="javascript"
    fi
    if [[ "$LANGUAGE" == "c" ]]; then
        LANGUAGE="cpp"
    fi

else
    echo "[!] Invalid language: $LANGUAGE"
    # finalize
    exit 5
fi

if [ -z $FORMAT ]; then
    FORMAT="sarif-latest"
fi

if [ -z $QS ]; then
    QS="$LANGUAGE-security-experimental.qls"
fi

if [ -z $OUTPUT ]; then
    OUTPUT="/opt/results"
fi

if [ -z $THREADS ]; then
    THREADS="0"
fi

if [ -z $CUSTOM_QUERY_ONLY ]; then
    CUSTOM_QUERY_ONLY="true"
fi

# if [ -z $CODEQL_HOME ]; then
#     CODEQL_HOME="/root/codeql-home"
# fi

DB="$OUTPUT/codeql-db"

# Set THREADS

# Show execution information
echo "----------------"
print_green " [+] Language: $LANGUAGE"
print_green " [+] CodeQL Home: $CODEQL_HOME"
print_green " [+] Build: $BUILD"
print_green " [+] Query-suites: $QS"
print_green " [+] Custom queries: $CQ"
print_green " [+] Custom queries only: $CQ_ONLY"
print_green " [+] Database: $DB"
print_green " [+] Source: $SRC"
print_green " [+] Output: $OUTPUT"
print_green " [+] Format: $FORMAT"
echo "----------------"

# Check action
if [ -z $ACTION ]; then
    ACTION='all'
fi

# Functions
# create_database() {
#     # TODO: Check to create or skip database init
#     if [[ "$OVERWRITE" == "true" ]]; then
#         if [[ "$BUILD" == "true" ]]; then
#             print_green "[Running] Creating DB: $CODEQL_HOME/codeql database create --threads=$THREADS --language=$LANGUAGE --command=\"$COMMAND\" $DB -s $SRC --overwrite"
#             $CODEQL_HOME/codeql database create --threads=$THREADS --language=$LANGUAGE --command="$COMMAND" $DB -s $SRC --overwrite
#         else
#             print_green "[Running] Creating DB: $CODEQL_HOME/codeql database create --threads=$THREADS --language=$LANGUAGE $DB -s $SRC --build-mode=none --overwrite"
#             $CODEQL_HOME/codeql database create --threads=$THREADS --language=$LANGUAGE $DB -s $SRC --build-mode=none --overwrite
#         fi

#     else
#         if [ -d "$DB" ] && [ -z "$DB/*" ]; then
#             ls -lia $DB
#             exit 0
#         else
#             if [[ "$BUILD" == "true" ]]; then
#                 print_green "[Running] Creating DB: $CODEQL_HOME/codeql database create --threads=$THREADS --language=$LANGUAGE --command=\"$COMMAND\" $DB -s $SRC --overwrite"
#                 $CODEQL_HOME/codeql database create --threads=$THREADS --language=$LANGUAGE --command="$COMMAND" $DB -s $SRC --overwrite
#             else
#                 print_green "[Running] Creating DB: $CODEQL_HOME/codeql database create --threads=$THREADS --language=$LANGUAGE $DB -s $SRC --build-mode=none --overwrite"
#                 $CODEQL_HOME/codeql database create --threads=$THREADS --language=$LANGUAGE $DB -s $SRC --build-mode=none --overwrite
#             fi
#         fi

#     fi

#     if [[ $? -ne 0 && $? -ne 2 ]]; then # ignore unempty database
#         print_red "[Error]: Codeql create database failed."
#         # finalize
#         exit 6
#     fi

# }

create_database() {
    # Determine the appropriate command based on BUILD and OVERWRITE variables
    CMD="$CODEQL_HOME/codeql database create --threads=$THREADS --language=$LANGUAGE"
    if [[ "$BUILD" == "true" && "$COMMAND" != "" ]]; then
        CMD="$CMD --command=\"$COMMAND\""
    else
        CMD="$CMD --build-mode=none"
    fi

    if [[ "$OVERWRITE" == "true" ]]; then
        print_green "[Running] Creating DB with overwrite: $CMD"
        CMD="$CMD $DB -s $SRC --overwrite"
        eval $CMD
    else
        # Check if the database directory exists and is empty
        if [ -d "$DB" ] && [ -z "$(ls -A $DB)" ]; then
            exit 0
        else
            print_green "[Running] Creating DB with command: $CMD"
            CMD="$CMD $DB -s $SRC"
            eval $CMD
        fi
    fi

    # Check the exit status of the command
    if [[ $? -ne 0 && $? -ne 2 ]]; then
        print_red "[Error]: CodeQL create database failed."
        exit 6
    fi
}

scan() {
    if [[ -n "$CQ" ]]; then
        if check_valid_codeql_pack "$CQ"; then
            if [[ "$CQ_ONLY" == "true" ]]; then
                print_green "[Running] Start Scanning: $CODEQL_HOME/codeql database analyze --format=$FORMAT --threads=$THREADS $SAVE_CACHE_FLAG --output=$OUTPUT/issues.$FORMAT $DB $CQ"
                codeql database analyze --rerun --off-heap-ram=0 --format=$FORMAT --threads=$THREADS $SAVE_CACHE_FLAG --output=$OUTPUT/issues.$FORMAT $DB $CQ
            else
                print_green "[Running] Start Scanning: $CODEQL_HOME/codeql database analyze --format=$FORMAT --threads=$THREADS $SAVE_CACHE_FLAG --output=$OUTPUT/issues.$FORMAT $DB $QS path:$CQ"
                codeql database analyze --rerun --off-heap-ram=0 --format=$FORMAT --threads=$THREADS $SAVE_CACHE_FLAG --output=$OUTPUT/issues.$FORMAT $DB $QS path:$CQ
            fi
        else
            print_red "[!] Invalid Custom Query directory"
        fi
    else
        print_green "[Running] Start Scanning: codeql database analyze --format=$FORMAT --threads=$THREADS $SAVE_CACHE_FLAG --output=$OUTPUT/issues.$FORMAT $DB $QS"
        codeql database analyze --rerun --off-heap-ram=0 --format=$FORMAT --threads=$THREADS $SAVE_CACHE_FLAG --output=$OUTPUT/issues.$FORMAT $DB $QS
    fi

    if [ $? -ne 0 ]; then
        print_red "[!] CodeQL analyze failed."
        # finalize
        exit 7
    fi
}

convert_sarif_to_sast() {
    print_green "[Running] Convert SARIF to SAST: python3 /opt/codeql-scripts/sarif2sast.py $OUTPUT/issues.$FORMAT -o $OUTPUT/gl-sast-report.json"
    python3 /opt/codeql-scripts/sarif2sast.py $OUTPUT/issues.$FORMAT -o $OUTPUT/gl-sast-report.json
    if [[ "$FORMAT" == "sarif"* ]]; then
        mv $OUTPUT/issues.$FORMAT $OUTPUT/issues.sarif
        python3 /opt/codeql-scripts/fix-sarifviewer-schema-mismatch.py $OUTPUT/issues.sarif
    fi
}

# finalize() {
#     if [[ $USERID && $GROUPID ]]; then
#         chown -R $USERID:$GROUPID $OUTPUT
#         chown -R $USERID:$GROUPID $SRC
#     fi
# }

main() {
    if [[ "$ACTION" == "create-database-only" ]]; then
        create_database
        echo "[Complete]"
        exit 0
    elif [[ "$ACTION" == "scan-only" ]]; then
        scan
        convert_sarif_to_sast
    else
        create_database
        scan
        convert_sarif_to_sast
    fi

    if [[ "$CLEAR_DB" == "true" ]]; then
        echo "[Running] Clear DB"
        rm -rf $OUTPUT/codeql-db
    fi

    # finalize
    echo "[Complete]"
}

check_valid_codeql_pack() {
    local directory_path="$1"
    # Check if directory exists
    if [[ ! -d "$directory_path" ]]; then
        return 1
    fi

    if [[ ! -f "$directory_path/qlpack.yml" ]]; then
        return 1
    fi

    if [[ $(find "$directory_path" -name "*.ql" | wc -l) -eq 0 ]]; then
        return 1
    fi

    return 0
}

# Main
main
