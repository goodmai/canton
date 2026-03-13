#!/bin/bash
set -e
source common.sh

# ==========================================
# Run All: Единый скрипт запуска и настройки
# ==========================================

echo "=========================================="
echo "Запуск полного цикла инициализации Devnet"
echo "=========================================="

# 1. Запуск инфраструктуры (фоновый процесс)
echo "[1/5] Запуск Canton (Devnet Infrastructure)..."
./start-devnet.sh &
CANTON_PID=$!

# Функция очистки при выходе
cleanup() {
    echo ""
    echo "Остановка Canton (PID: $CANTON_PID)..."
    kill $CANTON_PID
    wait $CANTON_PID 2>/dev/null
    echo "Canton остановлен."
}
trap cleanup EXIT

# 2. Ожидание запуска портов (Wait for Health)
echo "Ожидание доступности портов (Admin: 5011, Ledger: 5012)..."
WAIT_COUNT=0
MAX_WAIT=60

check_port() {
    # cross-platform check (nc -z works on mac/linux usually)
    nc -z localhost $1 > /dev/null 2>&1
}

while ! check_port 5011; do
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT+1))
    if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
        echo "Ошибка: Timeout ожидания Canton."
        exit 1
    fi
    echo -n "."
done
echo " Canton Admin API доступен!"

# 3. Настройка ключей (Key Management)
echo ""
echo "[2/5] Настройка ключей..."
./setup-keys.sh

# 4. Настройка пользователей и топологии
echo ""
echo "[3/5] Настройка пользователей..."
./setup-users.sh

# 5. Деплой приложения
echo ""
echo "[4/5] Деплой приложения..."
./deploy-app.sh

# 6. Тестирование
echo ""
echo "[5/5] Тестирование перевода..."
./test-transfer.sh

echo ""
echo "=========================================="
echo "Все этапы успешно завершены!"
echo "Система продолжит работу. Нажмите Ctrl+C для выхода."
echo "=========================================="

# Ожидание завершения пользователем
wait $CANTON_PID
