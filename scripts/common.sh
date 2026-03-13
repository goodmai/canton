#!/bin/bash

# ==========================================
# Common Utilities for Canton Devnet
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load SDK environment if available
if [ -f "$PROJECT_ROOT/daml/sdk/dev-env/profile_bash.sh" ]; then
    source "$PROJECT_ROOT/daml/sdk/dev-env/profile_bash.sh" > /dev/null 2>&1
fi

# Function to detect Canton command
get_canton_cmd() {
    # 1. SDK Installation (dev-env)
    local SDK_CANTON="$HOME/.daml/sdk/0.0.0/canton/canton.jar"
    local SDK_BIN="$HOME/.daml/sdk/0.0.0/canton/bin/canton"
    
    if [ -f "$SDK_CANTON" ]; then
        if ! command -v java &> /dev/null; then
             # Try sourcing profile again explicitly
             source "daml/sdk/dev-env/profile_bash.sh" > /dev/null 2>&1
        fi
        if command -v java &> /dev/null; then
            echo "java -jar $SDK_CANTON"
            return 0
        fi
    fi

    # 2. Binary in SDK
    if [ -f "$SDK_BIN" ]; then
        echo "$SDK_BIN"
        return 0
    fi

    # 3. Global command
    if command -v canton &> /dev/null; then
        echo "canton"
        return 0
    fi
    
    return 1
}

# Function to detect Daml command
get_daml_cmd() {
    if [ -f "$HOME/.daml/bin/daml-head" ]; then
        echo "$HOME/.daml/bin/daml-head"
    elif command -v daml &> /dev/null; then
        echo "daml"
    elif [ -f "$HOME/.daml/bin/daml" ]; then
        echo "$HOME/.daml/bin/daml"
    else
        return 1
    fi
}
