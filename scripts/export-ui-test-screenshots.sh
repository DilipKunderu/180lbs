#!/usr/bin/env bash
#
# Export XCUITest screenshot attachments from an .xcresult bundle, e.g. for
# attaching onboarding-walkthrough evidence to a PR.
#
# Usage:
#   bash scripts/export-ui-test-screenshots.sh ios/TestResults.xcresult /tmp/shots

set -euo pipefail

xcresult="${1:?usage: $0 <path.xcresult> <output-dir>}"
outdir="${2:?usage: $0 <path.xcresult> <output-dir>}"

mkdir -p "$outdir"
xcrun xcresulttool export attachments --path "$xcresult" --output-path "$outdir"
echo "Attachments exported to: $outdir"
