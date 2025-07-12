#!/bin/bash

# Детальный скрипт для диагностики MongoDB репозитория

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "============================================================================="
echo "🔍 Детальная диагностика MongoDB репозитория"
echo "============================================================================="

# Проверка версии Ubuntu
log_info "Проверка версии Ubuntu..."
echo "Версия: $(lsb_release -rs)"
echo "Кодовое имя: $(lsb_release -cs)"
echo "Описание: $(lsb_release -d)"

# Проверка архитектуры
log_info "Проверка архитектуры..."
echo "Архитектура: $(dpkg --print-architecture)"

# Проверка подключения к интернету
log_info "Проверка подключения к интернету..."
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    log_success "Интернет доступен"
else
    log_error "Нет подключения к интернету"
    exit 1
fi

# Проверка доступности MongoDB GPG ключей
log_info "Проверка доступности MongoDB GPG ключей..."

echo "Проверка старого URL (www.mongodb.org):"
if curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc >/dev/null 2>&1; then
    log_success "Старый URL доступен"
else
    log_warning "Старый URL недоступен"
fi

echo "Проверка нового URL (pgp.mongodb.com):"
if curl -fsSL https://pgp.mongodb.com/server-7.0.asc >/dev/null 2>&1; then
    log_success "Новый URL доступен"
else
    log_warning "Новый URL недоступен"
fi

# Проверка доступности репозиториев
log_info "Проверка доступности репозиториев..."

# Список возможных комбинаций
declare -a combinations=(
    "noble/mongodb-org/7.0"
    "jammy/mongodb-org/7.0"
    "focal/mongodb-org/7.0"
    "noble/mongodb-org/6.0"
    "jammy/mongodb-org/6.0"
    "focal/mongodb-org/6.0"
)

for combo in "${combinations[@]}"; do
    echo "Проверка: https://repo.mongodb.org/apt/ubuntu $combo"
    if curl -fsSL "https://repo.mongodb.org/apt/ubuntu $combo" >/dev/null 2>&1; then
        log_success "✅ Доступен: $combo"
    else
        log_warning "❌ Недоступен: $combo"
    fi
done

# Проверка DNS
log_info "Проверка DNS..."
echo "Проверка repo.mongodb.org:"
nslookup repo.mongodb.org 2>/dev/null || echo "DNS запрос не удался"

echo "Проверка pgp.mongodb.com:"
nslookup pgp.mongodb.com 2>/dev/null || echo "DNS запрос не удался"

# Проверка HTTPS соединения
log_info "Проверка HTTPS соединения..."
echo "Проверка repo.mongodb.org:"
curl -I https://repo.mongodb.org/apt/ubuntu/ 2>/dev/null | head -1 || echo "HTTPS соединение не удалось"

echo "Проверка pgp.mongodb.com:"
curl -I https://pgp.mongodb.com/ 2>/dev/null | head -1 || echo "HTTPS соединение не удалось"

# Попытка ручной установки MongoDB 7.0
log_info "Попытка ручной установки MongoDB 7.0..."

# Очистка старых репозиториев
log_info "Очистка старых MongoDB репозиториев..."
rm -f /etc/apt/sources.list.d/mongodb-org-*.list 2>/dev/null || true
rm -f /usr/share/keyrings/mongodb-server-*.gpg 2>/dev/null || true

# Добавление GPG ключа
log_info "Добавление GPG ключа MongoDB 7.0..."
if curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor; then
    log_success "GPG ключ добавлен"
else
    log_error "Ошибка добавления GPG ключа"
fi

# Добавление репозитория
log_info "Добавление репозитория MongoDB 7.0..."
REPO_LINE="deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse"
echo "$REPO_LINE" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Обновление списков пакетов
log_info "Обновление списков пакетов..."
if apt update 2>&1 | grep -q "mongodb"; then
    log_success "MongoDB репозиторий найден в apt update"
else
    log_warning "MongoDB репозиторий не найден в apt update"
    echo "Вывод apt update:"
    apt update 2>&1 | grep -i mongodb || echo "Нет упоминаний MongoDB"
fi

# Проверка доступности пакетов
log_info "Проверка доступности пакетов MongoDB..."
if apt list mongodb-org 2>/dev/null | grep -q "mongodb-org"; then
    log_success "Пакет mongodb-org доступен"
    apt list mongodb-org
else
    log_warning "Пакет mongodb-org недоступен"
fi

echo
echo "============================================================================="
log_success "Диагностика завершена"
echo "=============================================================================" 