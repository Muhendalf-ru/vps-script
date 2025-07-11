#!/bin/bash

set -e

echo "=== Текущие настройки времени и локали ==="
timedatectl
locale

echo
read -p "Введите часовой пояс (например, Europe/Moscow): " TIMEZONE
read -p "Введите локаль (например, ru_RU.UTF-8): " LOCALE

echo "=== Установка часового пояса: $TIMEZONE ==="
timedatectl set-timezone "$TIMEZONE"

echo "=== Установка локали: $LOCALE ==="
locale-gen "$LOCALE"
update-locale LANG="$LOCALE"

echo "=== Проверка установленных настроек ==="
timedatectl
locale

echo "=== Готово! ==="
