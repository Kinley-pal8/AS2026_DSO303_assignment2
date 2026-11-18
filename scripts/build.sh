#!/usr/bin/env bash
# Packages the Lambda code + dependencies into build/lambda (zipped by Terraform).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/lambda"
rm -rf "$OUT" && mkdir -p "$OUT"
python3 -m pip install --quiet --no-compile --target "$OUT" \
  --platform manylinux2014_aarch64 --implementation cp --python-version 3.13 --only-binary=:all: \
  -r "$ROOT/backend/requirements.txt"
cp "$ROOT"/backend/*.py "$OUT"/
# RDS certificate bundle so direct (no-proxy) TLS connections to RDS can be verified.
curl -fsSL --retry 3 -o "$OUT/rds-global-bundle.pem" https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
find "$OUT" -name "__pycache__" -type d -prune -exec rm -rf {} +
echo "Lambda package ready: $OUT"
