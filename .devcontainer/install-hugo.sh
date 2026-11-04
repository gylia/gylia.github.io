#!/usr/bin/env bash
# Pinned to the version used locally and by the deploy workflow, so the
# preview matches what actually ships.
set -euo pipefail
HUGO_VERSION="0.159.1"
cd /tmp
curl -fsSL -o hugo.deb \
  "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb"
sudo dpkg -i hugo.deb
rm -f hugo.deb
hugo version
