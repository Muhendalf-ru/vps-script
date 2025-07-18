#!/bin/bash

# Тестовый скрипт для проверки MongoDB 7.0 репозитория

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
echo "🧪 Тест MongoDB репозитория для Ubuntu 24.04"
echo "============================================================================="

# Проверка версии Ubuntu
log_info "Проверка версии Ubuntu..."
echo "Версия: $(lsb_release -rs)"
echo "Кодовое имя: $(lsb_release -cs)"

# Проверка подключения к интернету
log_info "Проверка подключения к интернету..."
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    log_success "Интернет доступен"
else
    log_error "Нет подключения к интернету"
    exit 1
fi

# Проверка доступности MongoDB 6.0 GPG ключа
log_info "Проверка доступности MongoDB 6.0 GPG ключа..."
if curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc >/dev/null 2>&1; then
    log_success "GPG ключ MongoDB 6.0 доступен"
else
    log_error "GPG ключ MongoDB 6.0 недоступен"
    exit 1
fi

# Проверка доступности MongoDB 7.0 GPG ключа
log_info "Проверка доступности MongoDB 7.0 GPG ключа..."
if curl -fsSL https://pgp.mongodb.com/server-7.0.asc >/dev/null 2>&1; then
    log_success "GPG ключ MongoDB 7.0 доступен"
else
    log_warning "GPG ключ MongoDB 7.0 недоступен"
fi

# Проверка доступности репозитория MongoDB 6.0
log_info "Проверка доступности MongoDB 6.0 репозитория..."
REPO_URL_6="https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0"
if curl -fsSL "$REPO_URL_6" >/dev/null 2>&1; then
    log_success "Репозиторий MongoDB 6.0 доступен"
else
    log_warning "Репозиторий MongoDB 6.0 недоступен для $(lsb_release -cs)"
    log_info "Попробуем альтернативный URL..."
    
    # Попробуем альтернативный URL для Ubuntu 24.04
    if [[ "$(lsb_release -cs)" == "noble" ]]; then
        ALT_REPO_URL="https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0"
        if curl -fsSL "$ALT_REPO_URL" >/dev/null 2>&1; then
            log_success "Альтернативный репозиторий MongoDB 6.0 доступен (jammy)"
            echo "Рекомендуется использовать Ubuntu jammy (22.04) репозиторий для noble (24.04)"
        else
            log_error "Альтернативный репозиторий MongoDB 6.0 также недоступен"
        fi
    fi
fi

# Проверка доступности репозитория MongoDB 7.0
log_info "Проверка доступности MongoDB 7.0 репозитория..."
log_info "Добавление временного репозитория для проверки..."

# Временно добавляем репозиторий для проверки
rm -f /etc/apt/sources.list.d/mongodb-test-*.list 2>/dev/null || true
rm -f /usr/share/keyrings/mongodb-test-*.gpg 2>/dev/null || true

# Добавляем GPG ключ
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-test-7.0.gpg --dearmor

# Добавляем репозиторий
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-test-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-test-7.0.list

# Проверяем доступность
if apt update 2>&1 | grep -q "mongodb"; then
    log_success "Репозиторий MongoDB 7.0 доступен"
    apt list mongodb-org 2>/dev/null | grep mongodb-org || log_warning "Пакет не найден в списке"
else
    log_warning "Репозиторий MongoDB 7.0 недоступен"
fi

# Очищаем временные файлы
rm -f /etc/apt/sources.list.d/mongodb-test-*.list
rm -f /usr/share/keyrings/mongodb-test-*.gpg

# Проверка существующих MongoDB репозиториев
log_info "Проверка существующих MongoDB репозиториев..."
if ls /etc/apt/sources.list.d/mongodb-org-*.list 2>/dev/null; then
    log_warning "Найдены существующие MongoDB репозитории:"
    ls -la /etc/apt/sources.list.d/mongodb-org-*.list
else
    log_info "Существующие MongoDB репозитории не найдены"
fi

echo
echo "============================================================================="
log_success "Тест завершен"
echo "=============================================================================" 