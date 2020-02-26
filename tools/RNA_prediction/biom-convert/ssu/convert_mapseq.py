#!/usr/bin/env python3

import argparse
import sys
import pandas as pd
import numpy as np
import json
import collections
# aliases
OrderedDict = collections.OrderedDict


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Generates json from mapseq.tsv")
    parser.add_argument("-i", "--input", dest="input_file", help="mapseq output", required=True)
    parser.add_argument("-o", "--outname", dest="outname", help="name of output file", default="mseq_json.biom")

    if len(sys.argv) == 1:
        parser.print_help()
    else:
        args = parser.parse_args()
        data = []
        count = 0
        with open(args.input_file, 'r') as file_in:
            for line in file_in:
                if count == 1:
                    header = line.strip().split('\t')
                if count > 1:
                    line_parsed = line.strip().split('\t')
                    data.append(OrderedDict(zip(header, line_parsed)))
                count += 1

        with open('test.json', 'w') as jsonfile:
            json.dump(data, jsonfile, indent=2)
