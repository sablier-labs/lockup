# CI Script Patterns

Templates and patterns for CI automation scripts.

## Script Templates

### ci-test.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

PACKAGE="${1:?Package name required}"

echo "::group::Building ${PACKAGE}"
just build "${PACKAGE}"
echo "::endgroup::"

echo "::group::Running tests"
just test "${PACKAGE}" -vvv
echo "::endgroup::"

echo "::group::Checking BTT alignment"
just test-bulloak "${PACKAGE}"
echo "::endgroup::"
```

### ci-coverage.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

PACKAGE="${1:?Package name required}"
MIN_COVERAGE="${2:-80}"

echo "Running coverage for ${PACKAGE}..."
just coverage "${PACKAGE}" --report summary > coverage-output.txt

# Extract coverage percentage
COVERAGE=$(grep "Total" coverage-output.txt | awk '{print $NF}' | tr -d '%')

if (( $(echo "${COVERAGE} < ${MIN_COVERAGE}" | bc -l) )); then
    echo "::error::Coverage ${COVERAGE}% below threshold ${MIN_COVERAGE}%"
    exit 1
fi

echo "Coverage: ${COVERAGE}% (threshold: ${MIN_COVERAGE}%)"
```

### ci-gas-check.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

PACKAGE="${1:?Package name required}"

cd "${PACKAGE}"

# Check for gas regressions
if ! forge snapshot --check .gas-snapshot; then
    echo "::warning::Gas regression detected"
    forge snapshot --diff .gas-snapshot
    # Don't fail, just warn
fi
```

### ci-lint.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

PACKAGE="${1:?Package name required}"

echo "::group::Forge fmt check"
forge fmt --check "${PACKAGE}/src" "${PACKAGE}/tests"
echo "::endgroup::"

echo "::group::Solhint"
solhint "${PACKAGE}/src/**/*.sol" --max-warnings 0
echo "::endgroup::"

echo "::group::Shellcheck"
shellcheck scripts/bash/*.sh
echo "::endgroup::"
```

---

## GitHub Actions Integration

### Workflow Annotations

| Syntax               | Purpose                 |
| -------------------- | ----------------------- |
| `::group::Title`     | Collapsible section     |
| `::endgroup::`       | End collapsible section |
| `::error::Message`   | Error annotation        |
| `::warning::Message` | Warning annotation      |
| `::notice::Message`  | Info annotation         |

### Setting Output Variables

```bash
# Set output for subsequent steps
echo "coverage=${COVERAGE}" >> "${GITHUB_OUTPUT}"

# Set environment variable
echo "BUILD_VERSION=${VERSION}" >> "${GITHUB_ENV}"
```

### Matrix Strategy Pattern

```bash
#!/usr/bin/env bash
# ci-matrix.sh - Run command for all packages

set -euo pipefail

COMMAND="${1:?Command required}"
PACKAGES=("lockup" "flow" "airdrops" "utils")

for package in "${PACKAGES[@]}"; do
    echo "::group::${package}"
    ${COMMAND} "${package}" || exit 1
    echo "::endgroup::"
done
```

---

## Artifact Preparation

### prepare-artifacts.sh

```bash
#!/usr/bin/env bash
# prepare-artifacts.sh

set -euo pipefail

PACKAGE="${1:?Package name required}"
VERSION="${2:?Version required}"
ARTIFACT_DIR="artifacts/${PACKAGE}-${VERSION}"

mkdir -p "${ARTIFACT_DIR}"

# Build optimized
FOUNDRY_PROFILE=optimized forge build

# Copy ABIs
find "${PACKAGE}/out" -name "*.json" -path "*/src/*" \
    -exec cp {} "${ARTIFACT_DIR}/" \;

# Generate deployment info
cat > "${ARTIFACT_DIR}/deployment-info.json" << EOF
{
    "package": "${PACKAGE}",
    "version": "${VERSION}",
    "commit": "$(git rev-parse HEAD)",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "Artifacts prepared in ${ARTIFACT_DIR}"
```

### Release Workflow

```bash
#!/usr/bin/env bash
# prepare-release.sh

set -euo pipefail

VERSION="${1:?Version required (e.g., v1.2.0)}"

# Validate version format
if [[ ! "${VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "::error::Invalid version format. Use vX.Y.Z"
    exit 1
fi

PACKAGES=("lockup" "flow" "airdrops" "utils")

for package in "${PACKAGES[@]}"; do
    echo "::group::Preparing ${package}"
    ./scripts/bash/prepare-artifacts.sh "${package}" "${VERSION}"
    echo "::endgroup::"
done

# Create combined artifact
mkdir -p "artifacts/all-${VERSION}"
cp -r artifacts/*-"${VERSION}"/* "artifacts/all-${VERSION}/"

echo "Release artifacts ready in artifacts/all-${VERSION}/"
```

---

## Environment Variables

| Variable            | Purpose                          |
| ------------------- | -------------------------------- |
| `FOUNDRY_PROFILE`   | Foundry build profile            |
| `RPC_URL`           | Network RPC endpoint             |
| `PRIVATE_KEY`       | Deployment private key           |
| `ETHERSCAN_API_KEY` | Contract verification            |
| `CI`                | Set to `true` in CI environments |
| `GITHUB_OUTPUT`     | GitHub Actions output file       |
| `GITHUB_ENV`        | GitHub Actions env file          |
