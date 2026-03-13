#!/bin/bash
set -e
source "$(dirname "$0")/common.sh"

# ==========================================
# Тестовый сценарий: Перевод монет
# ==========================================

DAML_CMD=$(get_daml_cmd)
if [ -z "$DAML_CMD" ]; then echo "Daml SDK не найден."; exit 1; fi

APP_NAME="my-app"
APP_DIR="$PROJECT_ROOT/$APP_NAME/main"
DAR_FILE=$(ls "$APP_DIR/.daml/dist/my-app-main-"*.dar | head -n 1)

# Поиск DAR файла (может быть в .daml/dist или dist)
DAR_FOUND=$(find "$APP_DIR" -name "*.dar" | head -n 1)

if [ -z "$DAR_FOUND" ]; then
    echo "Ошибка: DAR файл не найден. Сначала запустите deploy-app.sh."
    exit 1
fi

echo "Запуск сценария перевода..."
echo "Используется Daml: $DAML_CMD"

# Запуск Daml Script
# Используем переменные окружения или дефолтные значения
LEDGER_HOST="${DAML_LEDGER_HOST:-localhost}"
LEDGER_PORT="${DAML_LEDGER_PORT:-5012}"

# Запуск Daml Script
# Переходим в директорию проекта, чтобы daml подхватил версию из daml.yaml
cd "$APP_DIR" || exit 1

# Ensure log directory exists
mkdir -p "$PROJECT_ROOT/logs"
LOG_FILE="$PROJECT_ROOT/logs/test_transfer.log"

echo "Writing logs to $LOG_FILE"
eval "$DAML_CMD script --dar $DAR_FOUND --script-name Transfer:runTransfer --ledger-host $LEDGER_HOST --ledger-port $LEDGER_PORT --wall-clock-time" | tee "$LOG_FILE"
cd ../..


echo "Тест перевода успешно завершен."
