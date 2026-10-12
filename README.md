# Trivy pnpm workspace dependency reproduction

This is a minimal reproduction of Trivy misclassifying a production dependency that enters a deployed pnpm lockfile through a workspace package.

**repro-service** has a production dependency on the local workspace package **repro-shared**. **repro-shared** has a production dependency on **@xmldom/xmldom@0.8.13**, which is present in the deployed service. pnpm deploy writes the workspace package as a **file:** dependency in **.deploy/pnpm-lock.yaml**; Trivy treats that path as a development dependency unless **--include-dev-deps** is set.

## Run it

Requirements: Node.js, pnpm 11, Trivy, and jq. The commands need access to the pnpm registry and Trivy vulnerability database.

~~~sh
./repro.sh
~~~

The script runs **pnpm install --frozen-lockfile**, creates a production deployment with **pnpm deploy --prod**, and scans that deployed lockfile twice.

## Expected result

With Trivy 0.74.0 and 0.75.0, using the vulnerability database current on 2026-10-12:

- Without **--include-dev-deps**: **Findings: 0**
- With **--include-dev-deps**: eight HIGH findings for **@xmldom/xmldom@0.8.13** (CVE-2026-83605, CVE-2026-83607, CVE-2026-83608, CVE-2026-83613, CVE-2026-83614, CVE-2026-83615, CVE-2026-83616, CVE-2026-83619)

The CVE list and count can change as Trivy's database is updated. The important check is that the package is declared in production dependencies and present in the production deployment, while Trivy only reports it when **--include-dev-deps** is enabled.
