#!/bin/bash
set -e
source common.sh

# ==========================================
# Скрипт настройки ключей (Key Management)
# ==========================================

CANTON_CMD=$(get_canton_cmd)

if [ -z "$CANTON_CMD" ]; then
    echo "Ошибка: Canton не найден."
    exit 1
fi

echo "Запуск генерации/ротации ключей..."
eval "$CANTON_CMD" -c configs/remote.conf --script configs/setup-keys.canton
