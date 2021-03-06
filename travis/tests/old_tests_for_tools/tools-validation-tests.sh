#!/usr/bin/env bash
export PATH="$HOME/node-v8.11.1:$PATH"

set -e

# run a conformance test for all CWL tool descriptions

for i in $(find tools -name "*.cwl"); do
 echo "Testing: ${i}"
 cwltool --validate ${i}
done