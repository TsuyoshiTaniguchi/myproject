#!/bin/bash
set -e
cp env/.env.example env/.env
echo "① env/.env を開いて設定を確認/変更してください"
echo "② docker compose up --build で起動できます"
