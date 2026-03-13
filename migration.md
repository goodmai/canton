# DPM Migration Guide

## Overview
Daml Assistant (`daml`) has been deprecated and replaced by the Digital Asset Package Manager (`dpm`). This guide outlines the steps to migrate your project and workflow to `dpm`.

## Prerequisites
- **Install DPM**: Follow the instructions at [https://docs.digitalasset.com/build/3.4/dpm/dpm.html](https://docs.digitalasset.com/build/3.4/dpm/dpm.html).

## Migration Steps

### 1. Update Command Usage
Replace `daml` commands with `dpm` equivalents. Most commands are compatible, but some workflows might change.

- **Build**:
  ```bash
  # Old
  daml build
  # New
  dpm build
  ```

- **Clean**:
  ```bash
  # Old
  daml clean
  # New
  dpm clean
  ```

- **Script / Ledger Interaction**:
  `dpm` typically delegates to the underlying SDK tools. Ensure you are using the correct `sdk-version` in `daml.yaml`.

### 2. Update `daml.yaml`
Ensure your `daml.yaml` specifies a supported SDK version.
```yaml
sdk-version: 3.4.10
name: my-app
source: daml
version: 0.0.2
dependencies:
  - daml-prim
  - daml-stdlib
  - daml-script
```

### 3. Update Scripts
Update your shell scripts (`scripts/*.sh`) to use `dpm` instead of `daml`.
Example (`common.sh`):

```bash
# Detect dpm
if command -v dpm &> /dev/null; then
    DAML_CMD="dpm"
else
    DAML_CMD="daml"
fi
```

### 4. Remove Legacy Warnings
Pass the `--no-legacy-assistant-warning` flag if you must strictly continue using `daml` binary during the transition, but migrating to `dpm` binary is preferred.

## CI/CD and Docker
Update your `Dockerfile` to install `dpm` instead of the legacy SDK installer if you want to switch fully. For now, the existing image uses the legacy installer which provides both.
