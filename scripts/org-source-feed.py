#!/usr/bin/env python3

import os
import argparse
import re
import json
import logging
import sys
import itertools

ORG_SOURCE_DIR = os.path.expanduser("~/org/database")
SOURCE_CODE_BLOCK_REGEX = (
    r"#\+NAME: *(?P<name>.*?) *\n"
    r"#\+begin_src *(?P<source_type>\w*) *.*?\n"
    r"(?P<source_code>.*?)\n"
    r"#\+end_src"
)
TARGET_ORG_FILE_REGEX = r"[a-zA-z_-]*\.org"

SOURCE_TYPES = ["source-code", "links"]

logging.basicConfig(filename="/tmp/org-source-feed.log", level=logging.DEBUG)
class EntryOfLinks(object):
    def __init__(self, source_type, remain_args):
        self.source_type = source_type
        self.remain_args = remain_args
        self.args = None

    def get_sources(self):
        useful_link_file = os.path.join(ORG_SOURCE_DIR, "useful-links.md")
        if not os.path.exists(useful_link_file):
            return []

        result = []
        with open(useful_link_file, "r") as f:
            for line in f.readlines():
                for matched_result in re.finditer(r"\[(?P<link_desc>.*?)\]\((?P<link>.*?)\)", line, re.M | re.I):
                    logging.debug("Find a link link_desc=[{link_desc}], link=[{link}]".format(
                        link_desc=matched_result["link_desc"],
                        link=matched_result["link"],
                    ))
                    result.append({
                        "source_file": "useful-links",
                        "name": matched_result["link_desc"],
                        "type": "link",
                        "code": matched_result["link"],
                    })
            return result

    def run(self):
        parser = argparse.ArgumentParser()
        parser.add_argument(
            "--operation",
            "-o",
            required=True,
            help="operation type"
        )
        self.args = parser.parse_args(self.remain_args)
        logging.debug("EntryOfLinks get args: {}".format(self.args))
        return EntryOfLinks.__dict__[self.args.operation.replace('-', '_')](self)

class EntryOfSourceCode(object):
    def __init__(self, source_type, remain_args):
        self.source_type = source_type
        self.remain_args = remain_args
        self.args = None

    def get_sources(self):
        result = []
        for file_name in filter(lambda s: re.match(TARGET_ORG_FILE_REGEX, s), os.listdir(ORG_SOURCE_DIR)):
            file_full_path = os.path.join(ORG_SOURCE_DIR, file_name)
            with open(file_full_path, "r") as f:
                content = f.read()
                for matched_result in re.finditer(SOURCE_CODE_BLOCK_REGEX, content, re.M | re.I | re.S | re.MULTILINE):
                    logging.debug("Find a match {}".format(matched_result["name"]))
                    result.append({
                        "source_file": file_name,
                        "name": matched_result["name"],
                        "type": matched_result["source_type"],
                        "code": EntryOfSourceCode.remove_prefix_ws(matched_result["source_code"]),
                    })
        return result

    @staticmethod
    def remove_prefix_ws(content):
        lines = list(map(lambda s: s.rstrip(), content.split("\n")))
        n = EntryOfSourceCode.count_prefix_ws(lines)
        # logging.debug(f"lines: {*lines,}, n: {n}")
        if n > 0:
            return "\n".join(map(lambda s: s[n:] if len(s) >= n else s, lines))
        return "\n".join(lines)

    @staticmethod
    def count_prefix_ws(lines):
        n = sys.maxsize
        for line in lines:
            if line == '':
                continue
            num_prefix_ws = sum(1 for _ in itertools.takewhile(str.isspace, line))
            if num_prefix_ws < n:
                n = num_prefix_ws
        if n == sys.maxsize:
            return 0
        return n

    def run(self):
        parser = argparse.ArgumentParser()
        parser.add_argument(
            "--operation",
            "-o",
            required=True,
            help="operation type"
        )
        self.args = parser.parse_args(self.remain_args)
        logging.debug("EntryOfSourceCode get args: {}".format(self.args))
        return EntryOfSourceCode.__dict__[self.args.operation.replace('-', '_')](self)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--sourceType",
        "-t",
        required=True,
        help="source type",
        choices=SOURCE_TYPES,
    )
    args, remain = parser.parse_known_args()
    logging.debug("Main parse arguments result: args={} remain={}".format(args, remain))
    entry_name = 'EntryOf' + ''.join(
        map(lambda s: s[:1].upper() + s[1:],
            args.sourceType.split('-'))
    )
    print(json.dumps(globals()[entry_name](args, remain).run()))

if __name__ == "__main__":
    main()
