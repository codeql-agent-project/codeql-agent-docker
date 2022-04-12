#!/usr/bin/env python3

from genericpath import samestat
import os
import sys
import argparse
import json
import uuid
import re
import datetime

def get_nested_dict(element, *keys, required=False, defaultValue=None):
    """
    Return value if *keys (nested) exists in `element`, else if required == False - return defaultValue, else raise exception.
    """
    if not (isinstance(element, dict) or isinstance(element, list)):
        raise AttributeError("Expects dict as first argument.")
    if len(keys) == 0:
        raise AttributeError("Expects at least two arguments, one given.")

    _element = element
    isExist = True
    for key in keys:
        try:
            _element = _element[key]
        except KeyError as err:
            isExist = False
            if required:
                print(err)
                raise

    return _element if isExist else defaultValue


def convert_precision(precision):
    result = "Unknown"
    if precision.lower() == "very-high" or precision.lower() == "critical":
        result = "Critical"
    if precision.lower() == "high":
        result = "High"
    if precision.lower() == "medium":
        result = "Medium"
    if precision.lower() == "low":
        result = "Low"
    if precision.lower() == "info":
        result = "Info"
    return result


def parse_tags(tags):
    return [
        {
            "type": "cwe" if "cwe" in tag.lower() else tag,
            "name": tag,
            "value": re.search(r"\d ", tag).group() if re.search(r"\d ", tag) else "",
        }
        for tag in tags
    ]


def sarif2sast(data):
    rules = get_nested_dict(data, "runs", 0, "tool", "driver", "rules", required=True)
    results = get_nested_dict(data, "runs", 0, "results", required=True)
    scanner_name = get_nested_dict(
        data, "runs", 0, "tool", "driver", "name", defaultValue=""
    )
    scanner_id = scanner_name.replace(" ", "_").lower()
    scanner_version = get_nested_dict(
        data, "runs", 0, "tool", "driver", "semanticVersion"
    )
    vendor = get_nested_dict(data, "runs", 0, "tool", "driver", "organization")
    out = {}
    out = {
        "version": "14.0.0",
        "vulnerabilities": [],
        "remediations": [],
        "scan": {
            "messages": [],
            "scanner": {
                "id": scanner_id,
                "name": scanner_name,
                "version": scanner_version,
                "vendor": {"name": vendor},
            },
            "status": "success",
            "type": "sast",
            "start_time": datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S'),
            "end_time": datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S'),
        },
    }
    for item in results:
        rule_index = get_nested_dict(item, "rule", "index", required=True)
        message = get_nested_dict(
            get_nested_dict(rules, rule_index, required=True),
            "shortDescription",
            "text",
            defaultValue="",
        )
        description = get_nested_dict(
            get_nested_dict(rules, rule_index, required=True),
            "fullDescription",
            "text",
            defaultValue="",
        )
        severity = convert_precision(
            get_nested_dict(
                get_nested_dict(rules, rule_index, required=True),
                "properties",
                "precision",
                defaultValue="",
            )
        )
        uri = get_nested_dict(
            item, "locations", 0, "physicalLocation", "artifactLocation", "uri"
        )
        start_line = get_nested_dict(
            item, "locations", 0, "physicalLocation", "region", "startLine"
        )
        end_line = get_nested_dict(
            item,
            "locations",
            0,
            "physicalLocation",
            "region",
            "endLine",
            defaultValue=start_line,
        )
        # identifiers = parse_tags(
        #     rules[item["rule"]["index"]]["properties"]["tags"]
        #     if rules[item["rule"]["index"]]["properties"]["tags"]
        #     else []
        # )
        identifiers = [{
            "type": "codeql_query_id",
            "name": item["ruleId"],
            "value": item["ruleId"]
        }]
        item_id = uuid.uuid4().hex;
        item_obj = {
            "id": item_id,
            "category": "sast",
            "cve": item_id,
            "message": message,
            "description": description,
            "severity": severity,
            "scanner": {"id": scanner_id, "name": scanner_name},
            "location": {"file": uri, "start_line": start_line, "end_line": end_line},
            "identifiers": identifiers,
        }
        out["vulnerabilities"].append(item_obj)
    return out


def main():
    parser = argparse.ArgumentParser(
        description="Script to convert SARIF (sarifv2.1.0) to SAST format"
    )
    parser.add_argument(
        "file", metavar="FILE_PATH", type=str, help="Path to SARIF file"
    )
    parser.add_argument(
        "-o",
        "--output",
        nargs="?",
        type=str,
        default="sast.json",
        help="Output folder to store result",
    )

    args = parser.parse_args()
    if len(sys.argv) == 1:
        sys.exit(0)
    OUTPUT = os.path.abspath(args.output)
    SRC = args.file
    if not os.path.isfile(SRC):
        print(f"[-] File not found: {SRC}")
        sys.exit(-1)
    f = open(
        SRC,
    )
    try:
        data = json.load(f)
    except:
        print(f"[-] Invalid json format")
        sys.exit(-1)
    f.close()
    out = sarif2sast(data)
    with open(OUTPUT, "w") as outfile:
        json.dump(out, outfile, indent=4)
    print(f"[+] Output: {OUTPUT}")


if __name__ == "__main__":
    main()
