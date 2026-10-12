#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
deploydir="$workdir/deploy"

pnpm install --frozen-lockfile --ignore-scripts
pnpm --config.inject-workspace-packages=true deploy --prod --filter=repro-service --ignore-scripts "$deploydir"

printf '\n=== Trivy without --include-dev-deps ===\n'
trivy fs "$deploydir/pnpm-lock.yaml" \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --format json \
  --output "$workdir/without-include-dev-deps.json"
jq -r '[.Results[]? | .Vulnerabilities[]?] | "Findings: \(length)", (.[] | "\(.PkgName)@\(.InstalledVersion) \(.VulnerabilityID) \(.Severity)")' \
  "$workdir/without-include-dev-deps.json"

printf '\n=== Trivy with --include-dev-deps ===\n'
trivy fs "$deploydir/pnpm-lock.yaml" \
  --include-dev-deps \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --format json \
  --output "$workdir/with-include-dev-deps.json"
jq -r '[.Results[]? | .Vulnerabilities[]?] | "Findings: \(length)", (.[] | "\(.PkgName)@\(.InstalledVersion) \(.VulnerabilityID) \(.Severity)")' \
  "$workdir/with-include-dev-deps.json"
