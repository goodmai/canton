#!/bin/bash
set -e

# Очистка предыдущей установки
echo "=== Cleaning up previous installation ==="
chmod +x ./scripts/clean.sh
./scripts/clean.sh

# 1. Запуск Canton (фоновый режим, ожидание healthcheck)
echo "=== Starting Canton Node ==="
docker-compose up -d --wait canton json-api

# 2. Деплой приложения (используем run для получения кода возврата)
echo "=== Deploying Application ==="
docker-compose run --rm -T deploy

# 3. Запуск тестов (используем run для получения кода возврата)
echo "=== Running Tests ==="
docker-compose run --rm -T test

# 4. Проверка результата по API
echo "=== Checking Transaction via API ==="
./scripts/check-tx.sh

# Остановка (опционально, если нужно оставить сеть запущенной - закомментируйте)
echo "=== Stopping Services ==="
docker-compose stop

echo "=== Restart Complete === "
