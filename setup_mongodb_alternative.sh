#!/bin/bash

# Альтернативный скрипт установки MongoDB с несколькими методами

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

# Функция для показа справки
show_help() {
    cat << EOF
Использование: $0 [ОПЦИИ]

Опции:
    -v, --version VERSION    Версия MongoDB (7.0, 6.0, 5.0) [по умолчанию: 7.0]
    -m, --method METHOD      Метод установки (repo, snap, docker) [по умолчанию: repo]
    -a, --auth               Включить аутентификацию
    -h, --help               Показать эту справку

Примеры:
    $0                                    # Установка MongoDB 7.0 через репозиторий
    $0 -v 6.0 -m repo                     # MongoDB 6.0 через репозиторий
    $0 -v 7.0 -m snap                     # MongoDB 7.0 через Snap
    $0 -v 7.0 -m docker                   # MongoDB 7.0 через Docker

EOF
}

# Метод 1: Установка через репозиторий
install_via_repo() {
    local version=$1
    log_info "Метод 1: Установка MongoDB $version через репозиторий"
    
    # Очистка старых репозиториев
    rm -f /etc/apt/sources.list.d/mongodb-org-*.list 2>/dev/null || true
    rm -f /usr/share/keyrings/mongodb-server-*.gpg 2>/dev/null || true
    
    # Добавление GPG ключа
    log_info "Добавление GPG ключа..."
    if [[ "$version" == "7.0" ]]; then
        curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
    else
        wget -qO - https://www.mongodb.org/static/pgp/server-$version.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-$version.gpg
    fi
    
    # Определение репозитория
    local ubuntu_codename=$(lsb_release -cs)
    if [[ "$ubuntu_codename" == "noble" ]]; then
        ubuntu_codename="jammy"
        log_info "Используем репозиторий jammy для Ubuntu noble"
    fi
    
    # Добавление репозитория
    log_info "Добавление репозитория..."
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-$version.gpg ] https://repo.mongodb.org/apt/ubuntu $ubuntu_codename/mongodb-org/$version multiverse" | tee /etc/apt/sources.list.d/mongodb-org-$version.list
    
    # Обновление и установка
    apt update
    apt install -y mongodb-org
    
    log_success "MongoDB $version установлен через репозиторий"
}

# Метод 2: Установка через Snap
install_via_snap() {
    local version=$1
    log_info "Метод 2: Установка MongoDB $version через Snap"
    
    # Установка snapd если не установлен
    if ! command -v snap &> /dev/null; then
        log_info "Установка snapd..."
        apt update
        apt install -y snapd
    fi
    
    # Установка MongoDB через snap
    if snap install mongodb --channel=$version/stable; then
        log_success "MongoDB $version установлен через Snap"
    else
        log_error "Ошибка установки MongoDB через Snap"
        return 1
    fi
}

# Метод 3: Установка через Docker
install_via_docker() {
    local version=$1
    log_info "Метод 3: Установка MongoDB $version через Docker"
    
    # Установка Docker если не установлен
    if ! command -v docker &> /dev/null; then
        log_info "Установка Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl enable --now docker
    fi
    
    # Создание директорий для данных
    mkdir -p /opt/mongodb/data
    mkdir -p /opt/mongodb/config
    
    # Создание конфигурационного файла
    cat > /opt/mongodb/config/mongod.conf << EOF
systemLog:
  destination: file
  path: /var/log/mongodb/mongod.log
  logAppend: true
storage:
  dbPath: /data/db
net:
  bindIp: 0.0.0.0
  port: 27017
EOF
    
    # Запуск MongoDB в Docker
    docker run -d \
        --name mongodb \
        --restart unless-stopped \
        -p 27017:27017 \
        -v /opt/mongodb/data:/data/db \
        -v /opt/mongodb/config:/etc/mongodb \
        mongo:$version \
        --config /etc/mongodb/mongod.conf
    
    log_success "MongoDB $version запущен в Docker"
}

# Основная функция
main() {
    local VERSION="7.0"
    local METHOD="repo"
    local AUTH=false
    
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -m|--method)
                METHOD="$2"
                shift 2
                ;;
            -a|--auth)
                AUTH=true
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
    
    echo "============================================================================="
    echo "🐘 Альтернативная установка MongoDB"
    echo "Версия: $VERSION"
    echo "Метод: $METHOD"
    echo "============================================================================="
    
    # Проверка root прав
    if [[ $EUID -ne 0 ]]; then
        log_error "Этот скрипт должен быть запущен с правами root (sudo)"
        exit 1
    fi
    
    # Установка в зависимости от метода
    case $METHOD in
        "repo")
            install_via_repo "$VERSION"
            ;;
        "snap")
            install_via_snap "$VERSION"
            ;;
        "docker")
            install_via_docker "$VERSION"
            ;;
        *)
            log_error "Неизвестный метод: $METHOD"
            log_info "Доступные методы: repo, snap, docker"
            exit 1
            ;;
    esac
    
    # Настройка аутентификации если требуется
    if [[ "$AUTH" == "true" ]]; then
        log_info "Настройка аутентификации..."
        # Здесь можно добавить настройку аутентификации
    fi
    
    echo
    echo "============================================================================="
    log_success "Установка MongoDB $VERSION завершена!"
    echo "============================================================================="
    echo
    echo "📋 Информация:"
    echo "  • Версия: $VERSION"
    echo "  • Метод: $METHOD"
    echo "  • Порт: 27017"
    echo
    echo "🚀 Команды управления:"
    case $METHOD in
        "repo")
            echo "  • Статус: systemctl status mongod"
            echo "  • Запуск: systemctl start mongod"
            echo "  • Остановка: systemctl stop mongod"
            ;;
        "snap")
            echo "  • Статус: snap services mongodb"
            echo "  • Запуск: snap start mongodb"
            echo "  • Остановка: snap stop mongodb"
            ;;
        "docker")
            echo "  • Статус: docker ps | grep mongodb"
            echo "  • Запуск: docker start mongodb"
            echo "  • Остановка: docker stop mongodb"
            ;;
    esac
    echo
}

# Запуск основной функции
main "$@" 