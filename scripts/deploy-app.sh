#!/bin/bash
set -e
source "$(dirname "$0")/common.sh"

# ==========================================
# Скрипт сборки и деплоя приложения Daml
# ==========================================

DAML_CMD=$(get_daml_cmd)

if [ -z "$DAML_CMD" ]; then
    echo "Daml SDK не найден."
    exit 1
fi

echo "Используется Daml: $DAML_CMD"

APP_NAME="my-app"
APP_DIR="$PROJECT_ROOT/$APP_NAME/main"
DAR_FILE="$APP_DIR/.daml/dist/my-app-main-0.0.1.dar"

# 1. Проверка структуры и зависимостей
echo "Копирование исходных файлов в $APP_DIR/daml..."
mkdir -p "$APP_DIR/daml"
cp "$PROJECT_ROOT/configs/"*.daml "$APP_DIR/daml/"
DAML_YAML="$APP_DIR/daml.yaml"

# Update version to match installed SDK
INSTALLED_VER="3.4.10"
if [ -f "$DAML_YAML" ]; then
    echo "Updating sdk-version in daml.yaml to $INSTALLED_VER..."
    sed -i.bak "s/sdk-version: .*/sdk-version: $INSTALLED_VER/" "$DAML_YAML" && rm "$DAML_YAML.bak"
fi
if [ -f "$DAML_YAML" ]; then
    if ! grep -q "daml-script" "$DAML_YAML"; then
        echo "Adding daml-script dependency to daml.yaml..."
        # Добавляем daml-script в конец списка dependencies
        # (Это простой хак, для продакшена лучше использовать yq)
        sed -i.bak '/dependencies:/a \
  - daml-script' "$DAML_YAML" && rm "$DAML_YAML.bak"
    fi
fi

# 2. Сборка (Build)
echo "Сборка проекта в $APP_DIR..."
# Используем eval для запуска
cd "$APP_NAME/main"
rm -rf .daml/dist
eval "$DAML_CMD build"
DAR_FILE=$(ls $(pwd)/.daml/dist/my-app-main-*.dar | head -n 1)
echo "Found DAR file: $DAR_FILE"
cd ../..

# 3. Загрузка (Upload)
echo "Загрузка DAR файла..."
# Используем переменные окружения или дефолтные значения
LEDGER_HOST="${DAML_LEDGER_HOST:-localhost}"
LEDGER_PORT="${DAML_LEDGER_PORT:-5012}"
# Extract package ID
echo "Checking if package check is needed..."
INSPECT_OUT=$($DAML_CMD damlc inspect-dar "$DAR_FILE" 2>&1)
echo "Inspect output (DEBUG): $INSPECT_OUT"
# Parse line like: my-app-main-0.0.2-hash "hash"
# We grep for line containing package name AND having a quoted hash at the end.
# We take tail -n 1 to prefer the final list over earlier warnings.
MAIN_PKG_ID=$(echo "$INSPECT_OUT" | grep "my-app-main" | grep '"$' | tail -n 1 | awk '{print $NF}' | tr -d '"' | tr -d '\r')
echo "Main Package ID: $MAIN_PKG_ID"
mkdir -p "$PROJECT_ROOT/logs"
echo "$MAIN_PKG_ID" > "$PROJECT_ROOT/logs/package_id.txt"

# Check if package already exists
# We capture stderr and stdout to check for the error message.
echo "Uploading DAR file..."

# Wait for domain connection (simple sleep for robustness after bootstrap)
echo "Waiting 10s for domain connection stabilize..."
sleep 10

OUTPUT=$(eval "$DAML_CMD ledger upload-dar --host $LEDGER_HOST --port $LEDGER_PORT --timeout 120 $DAR_FILE" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "$OUTPUT"
    echo "DAR upload succeeded."
else
    if echo "$OUTPUT" | grep -q "KNOWN_PACKAGE_VERSION"; then
       echo "Package already exists (KNOWN_PACKAGE_VERSION). Continuing..."
    elif echo "$OUTPUT" | grep -q "Submission failed: PkgDuplicatePackage"; then
       echo "Package already exists (DuplicatePackage). Continuing..."
    else
       echo "$OUTPUT"
       echo "DAR upload failed with exit code $EXIT_CODE"
       exit $EXIT_CODE
    fi
fi

# 4. Инициализация (Init Script)
echo "Запуск скрипта инициализации (Initialize.daml)..."
eval "$DAML_CMD script --dar $DAR_FILE --script-name Initialize:setup --ledger-host $LEDGER_HOST --ledger-port $LEDGER_PORT --wall-clock-time"

echo "Деплой успешно завершен."
