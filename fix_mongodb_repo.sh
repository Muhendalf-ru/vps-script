#!/bin/bash

# =============================================================================
# MongoDB Repository Fix Script
# Скрипт для исправления проблем с MongoDB репозиториями
# =============================================================================

set -euo pipefail  # Строгий режим

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функции для логирования
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Функция для показа справки
show_help() {
    cat << EOF
Использование: $0 [ОПЦИИ]

Опции:
    -c, --clean           Очистить все MongoDB репозитории
    -f, --fix             Исправить проблемы с apt
    -a, --all             Выполнить полную очистку и исправление
    -v, --verbose         Подробный вывод
    -h, --help            Показать эту справку

Примеры:
    $0 -c                    # Очистить MongoDB репозитории
    $0 -f                    # Исправить проблемы с apt
    $0 -a                    # Полная очистка и исправление

EOF
}

# Функция для проверки root прав
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Этот скрипт должен быть запущен с правами root (sudo)"
        exit 1
    fi
}

# Функция для очистки MongoDB репозиториев
clean_mongodb_repos() {
    log_info "Очистка MongoDB репозиториев..."
    
    # Удаление файлов репозиториев MongoDB
    local removed_files=()
    
    for file in /etc/apt/sources.list.d/mongodb-org-*.list; do
        if [[ -f "$file" ]]; then
            log_info "Удаление файла: $file"
            rm -f "$file"
            removed_files+=("$file")
        fi
    done
    
    # Удаление GPG ключей MongoDB
    for key in /usr/share/keyrings/mongodb-server-*.gpg; do
        if [[ -f "$key" ]]; then
            log_info "Удаление ключа: $key"
            rm -f "$key"
            removed_files+=("$key")
        fi
    done
    
    if [[ ${#removed_files[@]} -eq 0 ]]; then
        log_info "MongoDB репозитории не найдены"
    else
        log_success "Удалено ${#removed_files[@]} файлов MongoDB"
        for file in "${removed_files[@]}"; do
            echo "  - $file"
        done
    fi
}

# Функция для исправления проблем с apt
fix_apt_issues() {
    log_info "Исправление проблем с apt..."
    
    # Очистка кэша apt
    log_info "Очистка кэша apt..."
    apt clean
    apt autoclean
    
    # Обновление списков пакетов
    log_info "Обновление списков пакетов..."
    apt update
    
    # Исправление сломанных зависимостей
    log_info "Исправление сломанных зависимостей..."
    apt --fix-broken install -y
    
    log_success "Проблемы с apt исправлены"
}

# Функция для проверки статуса
check_status() {
    log_info "Проверка статуса системы..."
    
    echo
    echo "📋 Статус репозиториев:"
    
    # Проверка MongoDB репозиториев
    local mongodb_repos=0
    for file in /etc/apt/sources.list.d/mongodb-org-*.list; do
        if [[ -f "$file" ]]; then
            echo "  ❌ $file"
            mongodb_repos=$((mongodb_repos + 1))
        fi
    done
    
    if [[ $mongodb_repos -eq 0 ]]; then
        echo "  ✅ MongoDB репозитории не найдены"
    fi
    
    # Проверка GPG ключей MongoDB
    local mongodb_keys=0
    for key in /usr/share/keyrings/mongodb-server-*.gpg; do
        if [[ -f "$key" ]]; then
            echo "  ❌ $key"
            mongodb_keys=$((mongodb_keys + 1))
        fi
    done
    
    if [[ $mongodb_keys -eq 0 ]]; then
        echo "  ✅ MongoDB GPG ключи не найдены"
    fi
    
    echo
    echo "📋 Тест apt update:"
    if apt update >/dev/null 2>&1; then
        echo "  ✅ apt update работает корректно"
    else
        echo "  ❌ apt update содержит ошибки"
        echo "  💡 Запустите: $0 -f"
    fi
}

# Функция для полной очистки и исправления
full_cleanup() {
    log_info "Выполнение полной очистки и исправления..."
    
    clean_mongodb_repos
    fix_apt_issues
    check_status
    
    log_success "Полная очистка завершена"
}

# =============================================================================
# ОСНОВНАЯ ЛОГИКА
# =============================================================================

main() {
    local CLEAN=false
    local FIX=false
    local ALL=false
    local VERBOSE=false
    
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--clean)
                CLEAN=true
                shift
                ;;
            -f|--fix)
                FIX=true
                shift
                ;;
            -a|--all)
                ALL=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Неизвестная опция: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Если не указаны опции, показать справку
    if [[ "$CLEAN" == "false" ]] && [[ "$FIX" == "false" ]] && [[ "$ALL" == "false" ]]; then
        show_help
        exit 0
    fi
    
    # Проверки
    check_root
    
    echo "============================================================================="
    echo "🔧 MongoDB Repository Fix Script"
    echo "Исправление проблем с MongoDB репозиториями"
    echo "============================================================================="
    
    # Выполнение операций
    if [[ "$ALL" == "true" ]]; then
        full_cleanup
    else
        if [[ "$CLEAN" == "true" ]]; then
            clean_mongodb_repos
        fi
        
        if [[ "$FIX" == "true" ]]; then
            fix_apt_issues
        fi
        
        check_status
    fi
    
    echo
    echo "============================================================================="
    log_success "Операция завершена успешно!"
    echo "============================================================================="
    echo
    echo "💡 Рекомендации:"
    echo "  • Для установки MongoDB используйте обновленный скрипт setup_mongodb.sh"
    echo "  • Скрипт автоматически выберет совместимую версию для вашей Ubuntu"
    echo "  • Ubuntu 24.04+ поддерживает MongoDB 7.0+"
    echo
}

# Запуск основной функции
main "$@" 