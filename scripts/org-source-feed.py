#!/usr/bin/env python3

import os
import argparse
import re
import json
import logging
import sys
import itertools
from abc import ABC, abstractmethod
from typing import Generator

SOURCE_CODE_BLOCK_REGEX = (
    r"#\+NAME: *(?P<name>.*?) *\n"
    r"#\+begin_src *(?P<source_type>\w*) *.*?\n"
    r"(?P<source_code>.*?)\n"
    r"#\+end_src"
)

SOURCE_TYPES = {
    "source-code": lambda filepaths: EntryCodeGenerator(filepaths),
    "links": lambda filepaths: EntryLinkGenerator(filepaths),
}

logging.basicConfig(filename="/tmp/org-source-feed.log", level=logging.DEBUG)


class GeneratorRunner(object):
    def __init__(self):
        self.parser = self.build_parser()
        self.args, self.remain = self.parser.parse_known_args()
        logging.debug(
            "Main parse arguments result: args={} remain={}".format(
                self.args, self.remain
            )
        )

    def build_parser(self):
        parser = argparse.ArgumentParser()
        parser.add_argument(
            "--sourcetype",
            "-t",
            required=True,
            help="source type",
            choices=SOURCE_TYPES.keys(),
        )
        parser.add_argument(
            "--filepaths", "-f", required=True, help="file path list", nargs="*"
        )

        return parser

    @staticmethod
    def run() -> list[dict]:
        runner = GeneratorRunner()
        return [
            entry
            for entry in SOURCE_TYPES[runner.args.sourcetype](
                runner.args.filepaths
            ).get_sources()
        ]


class EntryGenerator(ABC):
    def __init__(self, filepaths: list[str]):
        self.filepaths = filepaths

    # file: file descriptor
    # filepath: the full path of file
    @abstractmethod
    def generate(self, filehandler, filepath) -> Generator[dict, None, None]:
        pass

    def get_sources(self):
        results = []
        for filepath in self.filepaths:
            filepath = os.path.expanduser(filepath)
            if not os.path.isfile(filepath):
                continue

            with open(filepath, "r") as f:
                for result in self.generate(f, filepath):
                    results.append(result)
        return results


class EntryLinkGenerator(EntryGenerator):
    # override
    def generate(self, filehandler, filepath) -> Generator[dict, None, None]:
        for line in filehandler.readlines():
            for matched_result in re.finditer(
                r"\[(?P<link_desc>.*?)\]\((?P<link>.*?)\)", line, re.M | re.I
            ):
                logging.debug(
                    "Find a link link_desc=[{link_desc}], link=[{link}]".format(
                        link_desc=matched_result["link_desc"],
                        link=matched_result["link"],
                    )
                )
                yield {
                    "source_file": os.path.basename(filepath),
                    "name": matched_result["link_desc"],
                    "type": "link",
                    "code": matched_result["link"],
                }


class EntryCodeGenerator(EntryGenerator):
    def generate(self, filehandler, filepath) -> Generator[dict, None, None]:
        content = filehandler.read()
        for matched_result in re.finditer(
            SOURCE_CODE_BLOCK_REGEX, content, re.M | re.I | re.S | re.MULTILINE
        ):
            logging.debug("Find a match {}".format(matched_result["name"]))
            yield {
                "source_file": os.path.basename(filepath),
                "name": matched_result["name"],
                "type": matched_result["source_type"],
                "code": EntryCodeGenerator.remove_prefix_ws(
                    matched_result["source_code"]
                ),
            }

    @staticmethod
    def remove_prefix_ws(content):
        lines = list(map(lambda s: s.rstrip(), content.split("\n")))
        n = EntryCodeGenerator.count_prefix_ws(lines)
        # logging.debug(f"lines: {*lines,}, n: {n}")
        if n > 0:
            return "\n".join(map(lambda s: s[n:] if len(s) >= n else s, lines))
        return "\n".join(lines)

    @staticmethod
    def count_prefix_ws(lines):
        n = sys.maxsize
        for line in lines:
            if line == "":
                continue
            num_prefix_ws = sum(1 for _ in itertools.takewhile(str.isspace, line))
            if num_prefix_ws < n:
                n = num_prefix_ws
        if n == sys.maxsize:
            return 0
        return n


def main():
    print(json.dumps(GeneratorRunner.run()))


if __name__ == "__main__":
    main()
