#!/bin/bash
echo "Starting Canton node..."
docker-compose up -d --wait canton
echo "Canton node is running."
