#!/bin/bash

# =============================================================================
# VPS Server Setup Script
# Автоматическая настройка Ubuntu сервера
# =============================================================================

set -euo pipefail  # Строгий режим: выход при ошибке, неопределенные переменные, ошибки в пайпах

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Функция для проверки root прав
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Этот скрипт должен быть запущен с правами root (sudo)"
        exit 1
    fi
}

# Функция для проверки интернет-соединения
check_internet() {
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_error "Нет подключения к интернету. Проверьте соединение."
        exit 1
    fi
}

# Функция для валидации порта
validate_port() {
    local port=$1
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log_error "Неверный порт. Должен быть числом от 1 до 65535"
        return 1
    fi
    if [ "$port" -eq 22 ] || [ "$port" -eq 2222 ] || [ "$port" -eq 22222 ]; then
        log_warning "Рекомендуется использовать нестандартный порт для безопасности"
    fi
}

# Функция для валидации имени пользователя
validate_username() {
    local username=$1
    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        log_error "Неверное имя пользователя. Используйте только строчные буквы, цифры, дефисы и подчеркивания"
        return 1
    fi
    if id "$username" &>/dev/null; then
        log_error "Пользователь $username уже существует"
        return 1
    fi
}

# Функция для создания резервной копии конфига
backup_config() {
    local config_file=$1
    if [ -f "$config_file" ]; then
        cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Создана резервная копия: ${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

# Функция для установки пакетов с проверкой
install_package() {
    local package=$1
    log_info "Установка пакета: $package"
    if apt install -y "$package"; then
        log_success "Пакет $package установлен успешно"
    else
        log_error "Ошибка установки пакета $package"
        return 1
    fi
}

# Функция для проверки успешности операции
check_exit_code() {
    if [ $? -eq 0 ]; then
        log_success "$1"
    else
        log_error "$2"
        exit 1
    fi
}

# =============================================================================
# ОСНОВНАЯ ЛОГИКА СКРИПТА
# =============================================================================

main() {
    echo "============================================================================="
    echo "🚀 VPS Server Setup Script"
    echo "Автоматическая настройка Ubuntu сервера"
    echo "============================================================================="
    
    # Проверки
    check_root
    check_internet
    
    # Получение данных от пользователя
    echo
    log_info "Введите параметры для настройки сервера:"
    
    # Валидация имени пользователя
    while true; do
        read -p "Введите имя нового пользователя: " NEW_USER
        if validate_username "$NEW_USER"; then
            break
        fi
    done
    
    # Валидация порта SSH
    while true; do
        read -p "Введите порт для SSH (например, 2222): " SSH_PORT
        if validate_port "$SSH_PORT"; then
            break
        fi
    done
    
    # Подтверждение
    echo
    log_warning "Будет выполнена следующая настройка:"
    echo "  • Создание пользователя: $NEW_USER"
    echo "  • Порт SSH: $SSH_PORT"
    echo "  • Установка Docker и Docker Compose"
    echo "  • Настройка безопасности (Fail2Ban, UFW)"
    echo
    read -p "Продолжить? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Настройка отменена"
        exit 0
    fi
    
    # =============================================================================
    # ОБНОВЛЕНИЕ СИСТЕМЫ
    # =============================================================================
    log_info "=== Обновление системы ==="
    apt update && apt upgrade -y
    check_exit_code "Система обновлена" "Ошибка обновления системы"
    
    # =============================================================================
    # СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ
    # =============================================================================
    log_info "=== Создание нового пользователя: $NEW_USER ==="
    adduser --disabled-password --gecos "" "$NEW_USER"
    usermod -aG sudo "$NEW_USER"
    check_exit_code "Пользователь $NEW_USER создан" "Ошибка создания пользователя"
    
    # Принудительная смена пароля при первом входе
    chage -d 0 "$NEW_USER"
    log_success "Пользователь должен сменить пароль при первом входе"
    
    # =============================================================================
    # НАСТРОЙКА SSH
    # =============================================================================
    log_info "=== Настройка SSH ==="
    
    # Установка SSH сервера, если не установлен
    if ! systemctl is-active --quiet ssh; then
        log_info "Установка SSH сервера..."
        install_package "openssh-server"
        systemctl enable --now ssh
    fi
    
    # Создание резервной копии
    backup_config "/etc/ssh/sshd_config"
    
    # Настройка порта
    sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config || true
    sed -i "s/Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config || true
    
    # Отключение root-доступа
    sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
    sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin no/" /etc/ssh/sshd_config
    
    # Настройка аутентификации
    sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/" /etc/ssh/sshd_config
    
    # Дополнительные настройки безопасности
    echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
    echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
    echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config
    
    # Перезапуск SSH
    systemctl restart ssh
    check_exit_code "SSH настроен и перезапущен" "Ошибка настройки SSH"
    
    # =============================================================================
    # УСТАНОВКА DOCKER
    # =============================================================================
    log_info "=== Установка Docker ==="
    
    # Удаление старых версий
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Установка зависимостей
    install_package "apt-transport-https"
    install_package "ca-certificates"
    install_package "curl"
    install_package "gnupg"
    install_package "lsb-release"
    
    # Добавление GPG ключа Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Добавление репозитория Docker
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Обновление и установка Docker
    apt update
    install_package "docker-ce"
    install_package "docker-ce-cli"
    install_package "containerd.io"
    
    # Добавление пользователя в группу docker
    usermod -aG docker "$NEW_USER"
    
    # Запуск Docker
    systemctl enable --now docker
    check_exit_code "Docker установлен и запущен" "Ошибка установки Docker"
    
    # =============================================================================
    # УСТАНОВКА DOCKER COMPOSE
    # =============================================================================
    log_info "=== Установка Docker Compose v2 ==="
    
    # Получение последней версии
    DOCKER_COMPOSE_VERSION=$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    # Скачивание и установка
    curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Проверка установки
    if docker-compose version &>/dev/null; then
        log_success "Docker Compose установлен успешно"
    else
        log_error "Ошибка установки Docker Compose"
    fi
    
    # =============================================================================
    # УСТАНОВКА FAIL2BAN
    # =============================================================================
    log_info "=== Установка и настройка Fail2Ban ==="
    
    install_package "fail2ban"
    
    # Создание конфигурации
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF
    
    systemctl enable --now fail2ban
    check_exit_code "Fail2Ban установлен и настроен" "Ошибка установки Fail2Ban"
    
    # =============================================================================
    # НАСТРОЙКА UFW
    # =============================================================================
    log_info "=== Настройка UFW Firewall ==="
    
    install_package "ufw"
    
    # Сброс правил
    ufw --force reset
    
    # Настройка политик по умолчанию
    ufw default deny incoming
    ufw default allow outgoing
    
    # Открытие портов
    ufw allow "$SSH_PORT"
    ufw allow 2376  # Docker TLS
    ufw allow 2377  # Docker Swarm
    ufw allow 7946  # Docker Swarm
    ufw allow 4789/udp  # Docker overlay network
    
    # Включение UFW
    ufw --force enable
    check_exit_code "UFW настроен и включен" "Ошибка настройки UFW"
    
    # =============================================================================
    # ДОПОЛНИТЕЛЬНЫЕ НАСТРОЙКИ
    # =============================================================================
    log_info "=== Дополнительные настройки ==="
    
    # Установка полезных утилит
    install_package "htop"
    install_package "nano"
    install_package "wget"
    install_package "unzip"
    install_package "tree"
    
    # Настройка часового пояса (опционально)
    log_info "Текущий часовой пояс: $(timedatectl show --property=Timezone --value)"
    
    # =============================================================================
    # ФИНАЛЬНАЯ ИНФОРМАЦИЯ
    # =============================================================================
    echo
    echo "============================================================================="
    log_success "🎉 Настройка сервера завершена успешно!"
    echo "============================================================================="
    echo
    echo "📋 Информация для подключения:"
    echo "  • Пользователь: $NEW_USER"
    echo "  • Порт SSH: $SSH_PORT"
    echo "  • IP адрес: $(hostname -I | awk '{print $1}')"
    echo
    echo "🔗 Команда для подключения:"
    echo "  ssh -p $SSH_PORT $NEW_USER@$(hostname -I | awk '{print $1}')"
    echo
    echo "🧪 Команды для проверки:"
    echo "  • Docker: sudo -i -u $NEW_USER docker run hello-world"
    echo "  • Docker Compose: docker-compose version"
    echo "  • Fail2Ban: sudo fail2ban-client status"
    echo "  • UFW: sudo ufw status"
    echo
    echo "⚠️  ВАЖНО:"
    echo "  • При первом входе пользователь $NEW_USER должен сменить пароль"
    echo "  • Рекомендуется настроить SSH-ключи для большей безопасности"
    echo "  • Не забудьте настроить резервное копирование"
    echo
    echo "============================================================================="
}

# Запуск основной функции
main "$@"
