#!/bin/sh

#  CodeCov_Conversion.sh
#  ArcXPContent
#
#  Created by Cassandra Balbuena on 1/19/22.
#

PRODUCT_NAME=ArcXP

echo "Clone codecov conversion project"
git clone https://github.com/codecov/xcode-poc.git

cd xcode-poc
npm install || exit

# Debug: Ensure the XCRESULT_PATH is passed correctly
echo "XCRESULT_PATH is set to: $XCRESULT_PATH"

# Verify the xcresult zip path exists
if [ ! -d "$XCRESULT_PATH" ]; then
    echo "Error: xcresult file not found at $XCRESULT_PATH"
    exit 1
fi

# Debug: Verify the unzipped contents
echo "Contents of $XCRESULT_PATH:"
ls -R "$XCRESULT_PATH"

# Debug: Verify the integrity of the .xcresult file
echo "Verify the integrity of the .xcresult file"
xcrun xcresulttool get --path "$XCRESULT_PATH" --format json || {
    echo "Error: Failed to verify the .xcresult file"
    exit 1
}

echo "Convert the xcresult into CodeCov supported js file"
node generate-codecov-json.js --archive-path "$XCRESULT_PATH" || {
    echo "Error: Failed to run generate-codecov-json.js"
    exit 1
}
echo "Move JSON file to artifacts directory"
mkdir -p "$GITHUB_WORKSPACE/artifacts"
mv "coverage-report-Test-${PRODUCT_NAME}.json" "$GITHUB_WORKSPACE/artifacts/"
