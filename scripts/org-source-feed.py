#!/usr/bin/env python

import os
import argparse
import re
import json
import logging

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
        return "\n".join(map(lambda s: s[2:] if len(s) >= 2 else s, content.split("\n")))

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
