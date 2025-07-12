#!/bin/bash

# =============================================================================
# MongoDB Setup Script
# Скрипт установки и настройки MongoDB для Ubuntu серверов
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
    -v, --version VERSION    Версия MongoDB (7.0, 6.0, 5.0, 4.4) [по умолчанию: 6.0]
    -p, --port PORT          Порт MongoDB [по умолчанию: 27017]
    -d, --data-dir DIR       Директория для данных [по умолчанию: /var/lib/mongodb]
    -l, --log-dir DIR        Директория для логов [по умолчанию: /var/log/mongodb]
    -u, --user USER          Пользователь MongoDB [по умолчанию: mongodb]
    -a, --auth               Включить аутентификацию
    -r, --replica-set        Настроить как часть replica set
    -c, --config-server      Настроить как config server
    -m, --memory SIZE        Лимит памяти в MB [по умолчанию: 50% от доступной]
    -s, --storage-engine     Движок хранения (wiredTiger, inMemory) [по умолчанию: wiredTiger]
    -b, --backup             Настроить автоматические бэкапы
    -n, --no-start           Не запускать MongoDB после установки
    -v, --verbose            Подробный вывод
    -h, --help               Показать эту справку

Примеры:
    $0                                    # Базовая установка MongoDB (автоопределение версии)
    $0 -v 7.0 -p 27018                    # MongoDB 7.0 на порту 27018
    $0 -v 5.0 -p 27018                    # MongoDB 5.0 на порту 27018
    $0 -a -u myuser -m 2048               # С аутентификацией и лимитом памяти
    $0 -r -c                              # Config server для replica set
    $0 -b -s inMemory                     # In-memory с бэкапами

EOF
}

# Функция для проверки зависимостей
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        log_error "curl не найден. Установите curl"
        exit 1
    fi
    
    if ! command -v wget &> /dev/null; then
        log_error "wget не найден. Установите wget"
        exit 1
    fi
}

# Функция для проверки root прав
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Этот скрипт должен быть запущен с правами root (sudo)"
        exit 1
    fi
}

# Функция для проверки версии Ubuntu и определения совместимой версии MongoDB
check_ubuntu_version() {
    local ubuntu_version=$(lsb_release -rs)
    local codename=$(lsb_release -cs)
    
    log_info "Обнаружена Ubuntu $ubuntu_version ($codename)"
    
    # Определение совместимой версии MongoDB
    case $codename in
        "jammy"|"kinetic"|"lunar"|"mantic")
            # Ubuntu 22.04+ поддерживает MongoDB 6.0+
            if [[ "$1" == "6.0" ]] || [[ "$1" == "7.0" ]]; then
                return 0
            fi
            ;;
        "focal"|"groovy"|"hirsute"|"impish")
            # Ubuntu 20.04+ поддерживает MongoDB 5.0+
            if [[ "$1" == "5.0" ]] || [[ "$1" == "6.0" ]] || [[ "$1" == "7.0" ]]; then
                return 0
            fi
            ;;
        "bionic"|"cosmic"|"disco"|"eoan")
            # Ubuntu 18.04+ поддерживает MongoDB 4.4+
            if [[ "$1" == "4.4" ]] || [[ "$1" == "5.0" ]] || [[ "$1" == "6.0" ]] || [[ "$1" == "7.0" ]]; then
                return 0
            fi
            ;;
        "noble"|"oracular")
            # Ubuntu 24.04+ поддерживает MongoDB 7.0+
            if [[ "$1" == "7.0" ]]; then
                return 0
            else
                log_warning "Ubuntu $ubuntu_version ($codename) поддерживает только MongoDB 7.0+"
                log_warning "Автоматически переключаемся на MongoDB 7.0"
                return 2  # Специальный код для автоматического переключения
            fi
            ;;
        *)
            log_warning "Неизвестная версия Ubuntu: $codename"
            log_warning "Рекомендуется Ubuntu 18.04+"
            return 1
            ;;
    esac
    
    return 0
}

# Функция для получения рекомендуемой версии MongoDB для текущей Ubuntu
get_recommended_mongodb_version() {
    local codename=$(lsb_release -cs)
    
    case $codename in
        "noble"|"oracular")
            echo "7.0"
            ;;
        "jammy"|"kinetic"|"lunar"|"mantic")
            echo "6.0"
            ;;
        "focal"|"groovy"|"hirsute"|"impish")
            echo "5.0"
            ;;
        "bionic"|"cosmic"|"disco"|"eoan")
            echo "4.4"
            ;;
        *)
            echo "6.0"  # По умолчанию
            ;;
    esac
}

# Функция для получения доступной памяти
get_available_memory() {
    local total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    local recommended_mem=$((total_mem * 50 / 100))
    echo $recommended_mem
}

# Функция для валидации порта
validate_port() {
    local port=$1
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log_error "Неверный порт: $port. Должен быть числом от 1 до 65535"
        return 1
    fi
    
    if netstat -tuln | grep -q ":$port "; then
        log_warning "Порт $port уже используется"
        return 1
    fi
    
    return 0
}

# Функция для валидации версии MongoDB
validate_version() {
    local version=$1
    case $version in
        4.4|5.0|6.0|7.0)
            return 0
            ;;
        *)
            log_error "Неверная версия MongoDB: $version. Поддерживаемые: 4.4, 5.0, 6.0, 7.0"
            return 1
            ;;
    esac
}

# Функция для установки зависимостей
install_dependencies() {
    log_info "Установка зависимостей..."
    
    apt update
    
    local packages=(
        "gnupg"
        "curl"
        "wget"
        "ca-certificates"
        "software-properties-common"
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log_info "Установка пакета: $package"
            apt install -y "$package"
        else
            log_info "Пакет $package уже установлен"
        fi
    done
    
    log_success "Зависимости установлены"
}

# Функция для добавления MongoDB репозитория
add_mongodb_repo() {
    local version=$1
    
    log_info "Добавление MongoDB репозитория версии $version..."
    
    # Удаление старых ключей
    rm -f /usr/share/keyrings/mongodb-server-*.gpg 2>/dev/null || true
    
    # Добавление GPG ключа
    wget -qO - https://www.mongodb.org/static/pgp/server-$version.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-$version.gpg
    
    # Добавление репозитория
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-$version.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/$version multiverse" | tee /etc/apt/sources.list.d/mongodb-org-$version.list
    
    # Обновление пакетов
    apt update
    
    log_success "MongoDB репозиторий добавлен"
}

# Функция для установки MongoDB
install_mongodb() {
    local version=$1
    
    log_info "Установка MongoDB $version..."
    
    # Установка MongoDB
    apt install -y mongodb-org
    
    # Предотвращение автоматического обновления
    echo "mongodb-org hold" | dpkg --set-selections
    echo "mongodb-org-database hold" | dpkg --set-selections
    echo "mongodb-org-server hold" | dpkg --set-selections
    echo "mongodb-org-shell hold" | dpkg --set-selections
    echo "mongodb-org-mongos hold" | dpkg --set-selections
    echo "mongodb-org-tools hold" | dpkg --set-selections
    
    log_success "MongoDB $version установлен"
}

# Функция для создания пользователя и директорий
create_mongodb_user() {
    local user=$1
    local data_dir=$2
    local log_dir=$3
    
    log_info "Создание пользователя и директорий..."
    
    # Создание пользователя
    if ! id "$user" &>/dev/null; then
        useradd --system --shell /bin/false --home-dir /var/lib/mongodb --comment "MongoDB Database Server" "$user"
        log_success "Пользователь $user создан"
    else
        log_info "Пользователь $user уже существует"
    fi
    
    # Создание директорий
    mkdir -p "$data_dir" "$log_dir"
    chown -R "$user:$user" "$data_dir" "$log_dir"
    chmod 755 "$data_dir" "$log_dir"
    
    log_success "Директории созданы и настроены"
}

# Функция для создания конфигурации MongoDB
create_mongodb_config() {
    local port=$1
    local data_dir=$2
    local log_dir=$3
    local user=$4
    local auth=$5
    local memory_limit=$6
    local storage_engine=$7
    local replica_set=$8
    local config_server=$9
    
    log_info "Создание конфигурации MongoDB..."
    
    # Создание конфигурационного файла
    cat > /etc/mongod.conf << EOF
# MongoDB Configuration File

# Network interfaces
net:
  port: $port
  bindIp: 0.0.0.0
  maxIncomingConnections: 100

# Data storage
storage:
  dbPath: $data_dir
  journal:
    enabled: true
  engine: $storage_engine
EOF

    # Добавление настроек для in-memory движка
    if [[ "$storage_engine" == "inMemory" ]]; then
        cat >> /etc/mongod.conf << EOF
  inMemory:
    engineConfig:
      inMemorySizeGB: $((memory_limit / 1024))
EOF
    fi

    # Добавление настроек для WiredTiger
    if [[ "$storage_engine" == "wiredTiger" ]]; then
        cat >> /etc/mongod.conf << EOF
  wiredTiger:
    engineConfig:
      cacheSizeGB: $((memory_limit / 1024))
    collectionConfig:
      blockCompressor: snappy
    indexConfig:
      prefixCompression: true
EOF
    fi

    # Добавление аутентификации
    if [[ "$auth" == "true" ]]; then
        cat >> /etc/mongod.conf << EOF

# Security
security:
  authorization: enabled
EOF
    fi

    # Добавление replica set конфигурации
    if [[ "$replica_set" == "true" ]]; then
        cat >> /etc/mongod.conf << EOF

# Replication
replication:
  replSetName: rs0
EOF
    fi

    # Добавление config server конфигурации
    if [[ "$config_server" == "true" ]]; then
        cat >> /etc/mongod.conf << EOF

# Sharding
sharding:
  clusterRole: configsvr
EOF
    fi

    # Добавление логирования
    cat >> /etc/mongod.conf << EOF

# Logging
systemLog:
  destination: file
  logAppend: true
  path: $log_dir/mongod.log
  logRotate: reopen
  timeStampFormat: iso8601-local

# Process management
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

# Operation profiling
operationProfiling:
  slowOpThresholdMs: 100
  mode: slowOp

# Performance
setParameter:
  enableLocalhostAuthBypass: false
EOF

    log_success "Конфигурация MongoDB создана"
}

# Функция для настройки systemd сервиса
setup_systemd_service() {
    log_info "Настройка systemd сервиса..."
    
    # Создание systemd сервиса
    cat > /etc/systemd/system/mongod.service << EOF
[Unit]
Description=MongoDB Database Server
Documentation=https://docs.mongodb.org/manual
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=mongodb
Group=mongodb
ExecStart=/usr/bin/mongod --config /etc/mongod.conf
PIDFile=/var/run/mongodb/mongod.pid
LimitFSIZE=infinity
LimitCPU=infinity
LimitAS=infinity
LimitNOFILE=64000
LimitNPROC=64000

[Install]
WantedBy=multi-user.target
EOF

    # Создание PID директории
    mkdir -p /var/run/mongodb
    chown mongodb:mongodb /var/run/mongodb
    
    # Перезагрузка systemd
    systemctl daemon-reload
    
    # Включение автозапуска
    systemctl enable mongod
    
    log_success "Systemd сервис настроен"
}

# Функция для настройки аутентификации
setup_authentication() {
    local admin_user=$1
    local admin_password=$2
    
    log_info "Настройка аутентификации..."
    
    # Генерация пароля если не указан
    if [[ -z "$admin_password" ]]; then
        admin_password=$(openssl rand -base64 32)
    fi
    
    # Создание JavaScript файла для настройки пользователя
    cat > /tmp/setup_auth.js << EOF
use admin
db.createUser({
  user: "$admin_user",
  pwd: "$admin_password",
  roles: [
    { role: "userAdminAnyDatabase", db: "admin" },
    { role: "readWriteAnyDatabase", db: "admin" },
    { role: "dbAdminAnyDatabase", db: "admin" },
    { role: "clusterAdmin", db: "admin" }
  ]
})
EOF

    # Запуск MongoDB без аутентификации для первоначальной настройки
    systemctl start mongod
    sleep 5
    
    # Выполнение скрипта настройки
    mongosh --file /tmp/setup_auth.js
    
    # Остановка MongoDB
    systemctl stop mongod
    
    # Очистка временного файла
    rm -f /tmp/setup_auth.js
    
    log_success "Аутентификация настроена"
    log_info "Администратор: $admin_user"
    log_info "Пароль: $admin_password"
}

# Функция для настройки бэкапов
setup_backups() {
    log_info "Настройка автоматических бэкапов..."
    
    # Создание директории для бэкапов
    mkdir -p /var/backups/mongodb
    chown mongodb:mongodb /var/backups/mongodb
    
    # Создание скрипта бэкапа
    cat > /usr/local/bin/mongodb-backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/var/backups/mongodb"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Создание бэкапа
mongodump --out "$BACKUP_DIR/backup_$DATE"

# Сжатие бэкапа
tar -czf "$BACKUP_DIR/backup_$DATE.tar.gz" -C "$BACKUP_DIR" "backup_$DATE"
rm -rf "$BACKUP_DIR/backup_$DATE"

# Удаление старых бэкапов
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: backup_$DATE.tar.gz"
EOF

    chmod +x /usr/local/bin/mongodb-backup.sh
    
    # Создание cron задачи для ежедневных бэкапов
    echo "0 2 * * * /usr/local/bin/mongodb-backup.sh" | crontab -
    
    log_success "Автоматические бэкапы настроены"
}

# Функция для настройки мониторинга
setup_monitoring() {
    log_info "Настройка мониторинга..."
    
    # Установка MongoDB Exporter для Prometheus
    if command -v wget &> /dev/null; then
        wget -O /usr/local/bin/mongodb_exporter https://github.com/percona/mongodb_exporter/releases/latest/download/mongodb_exporter
        chmod +x /usr/local/bin/mongodb_exporter
        
        # Создание systemd сервиса для экспортера
        cat > /etc/systemd/system/mongodb_exporter.service << EOF
[Unit]
Description=MongoDB Exporter
After=network.target

[Service]
Type=simple
User=mongodb
ExecStart=/usr/local/bin/mongodb_exporter --mongodb.uri=mongodb://localhost:27017
Restart=always

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable mongodb_exporter
        
        log_success "MongoDB Exporter установлен"
    fi
}

# Функция для показа финальной информации
show_final_info() {
    local port=$1
    local auth=$2
    local admin_user=$3
    local admin_password=$4
    
    echo
    echo "============================================================================="
    log_success "MongoDB успешно установлен и настроен!"
    echo "============================================================================="
    echo
    
    echo "📋 Информация о установке:"
    echo "  • Порт: $port"
    echo "  • Конфигурация: /etc/mongod.conf"
    echo "  • Логи: /var/log/mongodb/mongod.log"
    echo "  • Данные: /var/lib/mongodb"
    echo "  • Сервис: mongod"
    echo
    
    if [[ "$auth" == "true" ]]; then
        echo "🔐 Аутентификация:"
        echo "  • Пользователь: $admin_user"
        echo "  • Пароль: $admin_password"
        echo "  • Строка подключения: mongodb://$admin_user:$admin_password@localhost:$port"
        echo
    else
        echo "🔓 Аутентификация отключена"
        echo "  • Строка подключения: mongodb://localhost:$port"
        echo
    fi
    
    echo "🚀 Команды управления:"
    echo "  • Запуск: sudo systemctl start mongod"
    echo "  • Остановка: sudo systemctl stop mongod"
    echo "  • Статус: sudo systemctl status mongod"
    echo "  • Логи: sudo journalctl -u mongod -f"
    echo
    
    echo "🔗 Полезные ссылки:"
    echo "  • Документация: https://docs.mongodb.org/"
    echo "  • MongoDB Compass: https://www.mongodb.com/products/compass"
    echo "  • Мониторинг: http://localhost:9216/metrics (если установлен экспортер)"
    echo
    
    echo "⚠️  ВАЖНО:"
    echo "  • Не забудьте настроить файрвол для порта $port"
    echo "  • Рекомендуется настроить SSL/TLS для продакшена"
    echo "  • Регулярно проверяйте логи и бэкапы"
    echo
}

# =============================================================================
# ОСНОВНАЯ ЛОГИКА
# =============================================================================

main() {
    # Переменные по умолчанию
    local VERSION="6.0"
    local PORT="27017"
    local DATA_DIR="/var/lib/mongodb"
    local LOG_DIR="/var/log/mongodb"
    local USER="mongodb"
    local AUTH=false
    local REPLICA_SET=false
    local CONFIG_SERVER=false
    local MEMORY_LIMIT=$(get_available_memory)
    local STORAGE_ENGINE="wiredTiger"
    local BACKUP=false
    local NO_START=false
    local VERBOSE=false
    local ADMIN_USER="admin"
    local ADMIN_PASSWORD=""
    
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -p|--port)
                PORT="$2"
                shift 2
                ;;
            -d|--data-dir)
                DATA_DIR="$2"
                shift 2
                ;;
            -l|--log-dir)
                LOG_DIR="$2"
                shift 2
                ;;
            -u|--user)
                USER="$2"
                shift 2
                ;;
            -a|--auth)
                AUTH=true
                shift
                ;;
            -r|--replica-set)
                REPLICA_SET=true
                shift
                ;;
            -c|--config-server)
                CONFIG_SERVER=true
                shift
                ;;
            -m|--memory)
                MEMORY_LIMIT="$2"
                shift 2
                ;;
            -s|--storage-engine)
                STORAGE_ENGINE="$2"
                shift 2
                ;;
            -b|--backup)
                BACKUP=true
                shift
                ;;
            -n|--no-start)
                NO_START=true
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
    
    # Проверки
    check_root
    check_dependencies
    
    # Проверка совместимости версии MongoDB с Ubuntu
    check_ubuntu_version "$VERSION"
    local compatibility_result=$?
    
    if [[ $compatibility_result -eq 2 ]]; then
        # Автоматическое переключение на рекомендуемую версию
        VERSION=$(get_recommended_mongodb_version)
        log_info "Автоматически переключились на MongoDB $VERSION для совместимости"
    elif [[ $compatibility_result -ne 0 ]]; then
        log_error "Несовместимая версия MongoDB $VERSION для данной версии Ubuntu"
        log_info "Рекомендуемая версия: $(get_recommended_mongodb_version)"
        exit 1
    fi
    
    if ! validate_version "$VERSION"; then
        exit 1
    fi
    
    if ! validate_port "$PORT"; then
        exit 1
    fi
    
    echo "============================================================================="
    echo "🐘 MongoDB Setup Script"
    echo "Установка и настройка MongoDB $VERSION"
    echo "Автоматическое определение совместимой версии для Ubuntu $(lsb_release -rs)"
    echo "============================================================================="
    
    # Установка
    install_dependencies
    add_mongodb_repo "$VERSION"
    install_mongodb "$VERSION"
    
    # Настройка
    create_mongodb_user "$USER" "$DATA_DIR" "$LOG_DIR"
    create_mongodb_config "$PORT" "$DATA_DIR" "$LOG_DIR" "$USER" "$AUTH" "$MEMORY_LIMIT" "$STORAGE_ENGINE" "$REPLICA_SET" "$CONFIG_SERVER"
    setup_systemd_service
    
    # Дополнительные настройки
    if [[ "$AUTH" == "true" ]]; then
        setup_authentication "$ADMIN_USER" "$ADMIN_PASSWORD"
    fi
    
    if [[ "$BACKUP" == "true" ]]; then
        setup_backups
    fi
    
    setup_monitoring
    
    # Запуск сервиса
    if [[ "$NO_START" != "true" ]]; then
        log_info "Запуск MongoDB..."
        systemctl start mongod
        
        # Проверка статуса
        if systemctl is-active --quiet mongod; then
            log_success "MongoDB успешно запущен"
        else
            log_error "Ошибка запуска MongoDB"
            systemctl status mongod
            exit 1
        fi
    fi
    
    # Показ финальной информации
    show_final_info "$PORT" "$AUTH" "$ADMIN_USER" "$ADMIN_PASSWORD"
}

# Запуск основной функции
main "$@" 