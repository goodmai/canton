#!/bin/bash
set -e
source "$(dirname "$0")/common.sh"

# ==========================================
# Скрипт запуска приватной сети Daml (Canton)
# Запускает только инфраструктуру (без инициализации данных)
# ==========================================

CANTON_CMD=$(get_canton_cmd)

if [ -z "$CANTON_CMD" ]; then
    echo "Ошибка: Canton не найден."
    exit 1
fi

CONFIG_FILE="$PROJECT_ROOT/configs/private-devnet.canton"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/canton.log"

mkdir -p "$LOG_DIR"

echo "Запуск приватной сети..."
echo "Команда запуска: $CANTON_CMD"
echo "Конфигурация: $CONFIG_FILE"
echo "Логи записываются в: $LOG_FILE"

# Запуск Canton (блокирующий режим, для работы в фоне используйте run-all.sh или &)
eval "$CANTON_CMD" -c "$CONFIG_FILE" > "$LOG_FILE" 2>&1
