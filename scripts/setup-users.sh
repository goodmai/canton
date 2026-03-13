#!/bin/bash
set -e
source common.sh

# ==========================================
# Скрипт настройки пользователей и домена
# ==========================================

CANTON_CMD=$(get_canton_cmd)

if [ -z "$CANTON_CMD" ]; then
    echo "Ошибка: Canton не найден."
    exit 1
fi

echo "Настройка подключения к домену и создания пользователей..."
eval "$CANTON_CMD" -c configs/remote.conf --script configs/setup-users.canton
