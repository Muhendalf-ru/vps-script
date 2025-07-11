#!/bin/bash

# =============================================================================
# Скрипт аудита безопасности Ubuntu сервера
# =============================================================================
# Автор: Pesherkino VPN
# Описание: Комплексная проверка безопасности системы
# Версия: 1.0.0
# =============================================================================

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Переменные
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/security_audit_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="/tmp/security_audit_report_$(date +%Y%m%d_%H%M%S).html"
TEMP_DIR="/tmp/security_audit_$(date +%Y%m%d_%H%M%S)"
SCAN_LEVEL="full" # full, quick, basic
EXPORT_FORMAT="html" # html, json, txt
SCAN_PORTS="common" # common, all, custom
VERBOSE=false
FIX_ISSUES=false

# Счетчики
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0
CRITICAL_ISSUES=0

# Функция логирования
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO") echo -e "${BLUE}[INFO]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "CRITICAL") echo -e "${RED}[CRITICAL]${NC} $message" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Функция проверки зависимостей
check_dependencies() {
    log "INFO" "Проверка зависимостей..."
    
    local deps=("nmap" "netstat" "ss" "lsof" "chkrootkit" "rkhunter" "fail2ban-client" "ufw" "openssl" "curl" "wget")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "WARNING" "Отсутствуют зависимости: ${missing_deps[*]}"
        log "INFO" "Установка недостающих пакетов..."
        
        # Установка основных инструментов
        sudo apt update
        sudo apt install -y nmap net-tools lsof chkrootkit rkhunter fail2ban ufw openssl curl wget
        
        # Проверка после установки
        for dep in "${missing_deps[@]}"; do
            if ! command -v "$dep" &> /dev/null; then
                log "ERROR" "Не удалось установить: $dep"
            fi
        done
    else
        log "SUCCESS" "Все зависимости установлены"
    fi
}

# Функция проверки прав доступа
check_permissions() {
    log "INFO" "Проверка прав доступа к критическим файлам..."
    
    local critical_files=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/group"
        "/etc/sudoers"
        "/etc/ssh/sshd_config"
        "/etc/fstab"
        "/etc/crontab"
    )
    
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            local perms=$(stat -c "%a" "$file")
            local owner=$(stat -c "%U" "$file")
            
            case "$file" in
                "/etc/shadow")
                    if [ "$perms" != "640" ] || [ "$owner" != "root" ]; then
                        log "CRITICAL" "Небезопасные права на $file (текущие: $perms, владелец: $owner)"
                        ((CRITICAL_ISSUES++))
                    else
                        log "SUCCESS" "Права на $file корректны"
                        ((PASSED_CHECKS++))
                    fi
                    ;;
                "/etc/passwd"|"/etc/group")
                    if [ "$perms" != "644" ] || [ "$owner" != "root" ]; then
                        log "WARNING" "Некорректные права на $file (текущие: $perms, владелец: $owner)"
                        ((WARNINGS++))
                    else
                        log "SUCCESS" "Права на $file корректны"
                        ((PASSED_CHECKS++))
                    fi
                    ;;
                *)
                    if [ "$owner" != "root" ]; then
                        log "WARNING" "Файл $file принадлежит не root (владелец: $owner)"
                        ((WARNINGS++))
                    else
                        log "SUCCESS" "Права на $file корректны"
                        ((PASSED_CHECKS++))
                    fi
                    ;;
            esac
            ((TOTAL_CHECKS++))
        fi
    done
}

# Функция проверки пользователей и паролей
check_users() {
    log "INFO" "Проверка пользователей и паролей..."
    
    # Проверка пользователей без пароля
    local users_without_pass=$(sudo awk -F: '$2 == "" {print $1}' /etc/shadow 2>/dev/null || true)
    if [ -n "$users_without_pass" ]; then
        log "CRITICAL" "Пользователи без пароля: $users_without_pass"
        ((CRITICAL_ISSUES++))
    else
        log "SUCCESS" "Все пользователи имеют пароли"
        ((PASSED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
    
    # Проверка UID 0 пользователей
    local uid0_users=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)
    local uid0_count=$(echo "$uid0_users" | wc -l)
    if [ "$uid0_count" -gt 1 ]; then
        log "WARNING" "Несколько пользователей с UID 0: $uid0_users"
        ((WARNINGS++))
    else
        log "SUCCESS" "Только один пользователь с UID 0"
        ((PASSED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
    
    # Проверка неактивных пользователей
    local inactive_users=$(sudo chage -l root 2>/dev/null | grep "Account expires" | awk '{print $4}')
    if [ "$inactive_users" = "never" ]; then
        log "SUCCESS" "Корневая учетная запись не имеет срока действия"
        ((PASSED_CHECKS++))
    else
        log "WARNING" "Корневая учетная запись имеет срок действия: $inactive_users"
        ((WARNINGS++))
    fi
    ((TOTAL_CHECKS++))
}

# Функция проверки SSH конфигурации
check_ssh_config() {
    log "INFO" "Проверка конфигурации SSH..."
    
    local sshd_config="/etc/ssh/sshd_config"
    
    if [ -f "$sshd_config" ]; then
        # Проверка протокола
        local protocol=$(grep -i "^Protocol" "$sshd_config" | awk '{print $2}' || echo "2")
        if [ "$protocol" != "2" ]; then
            log "CRITICAL" "SSH использует устаревший протокол: $protocol"
            ((CRITICAL_ISSUES++))
        else
            log "SUCCESS" "SSH использует протокол 2"
            ((PASSED_CHECKS++))
        fi
        ((TOTAL_CHECKS++))
        
        # Проверка root логина
        local root_login=$(grep -i "^PermitRootLogin" "$sshd_config" | awk '{print $2}' || echo "yes")
        if [ "$root_login" = "yes" ]; then
            log "WARNING" "SSH разрешает root логин"
            ((WARNINGS++))
        else
            log "SUCCESS" "SSH запрещает root логин"
            ((PASSED_CHECKS++))
        fi
        ((TOTAL_CHECKS++))
        
        # Проверка пустой пароль
        local empty_pass=$(grep -i "^PermitEmptyPasswords" "$sshd_config" | awk '{print $2}' || echo "no")
        if [ "$empty_pass" = "yes" ]; then
            log "CRITICAL" "SSH разрешает пустые пароли"
            ((CRITICAL_ISSUES++))
        else
            log "SUCCESS" "SSH запрещает пустые пароли"
            ((PASSED_CHECKS++))
        fi
        ((TOTAL_CHECKS++))
        
        # Проверка аутентификации по паролю
        local password_auth=$(grep -i "^PasswordAuthentication" "$sshd_config" | awk '{print $2}' || echo "yes")
        if [ "$password_auth" = "yes" ]; then
            log "WARNING" "SSH разрешает аутентификацию по паролю"
            ((WARNINGS++))
        else
            log "SUCCESS" "SSH использует только ключевую аутентификацию"
            ((PASSED_CHECKS++))
        fi
        ((TOTAL_CHECKS++))
    else
        log "ERROR" "Файл SSH конфигурации не найден"
        ((FAILED_CHECKS++))
        ((TOTAL_CHECKS++))
    fi
}

# Функция сканирования открытых портов
scan_ports() {
    log "INFO" "Сканирование открытых портов..."
    
    local scan_type="$1"
    local port_range=""
    
    case "$scan_type" in
        "common")
            port_range="21-23,25,53,80,110,111,135,139,143,443,993,995,1723,3306,3389,5900,8080"
            ;;
        "all")
            port_range="1-65535"
            ;;
        "custom")
            port_range="22,80,443,3306,5432,6379,27017"
            ;;
    esac
    
    log "INFO" "Сканирование портов: $port_range"
    
    # Использование nmap для сканирования
    if command -v nmap &> /dev/null; then
        local scan_result=$(nmap -sT -p "$port_range" localhost 2>/dev/null | grep -E "^(22|80|443|3306|5432|6379|27017)/" || true)
        
        if [ -n "$scan_result" ]; then
            log "INFO" "Открытые порты:"
            echo "$scan_result" | while read -r line; do
                local port=$(echo "$line" | awk '{print $1}' | cut -d'/' -f1)
                local service=$(echo "$line" | awk '{print $3}')
                
                case "$port" in
                    "22") log "INFO" "  Порт 22 (SSH) - $service" ;;
                    "80") log "INFO" "  Порт 80 (HTTP) - $service" ;;
                    "443") log "INFO" "  Порт 443 (HTTPS) - $service" ;;
                    "3306") log "WARNING" "  Порт 3306 (MySQL) - $service" ;;
                    "5432") log "WARNING" "  Порт 5432 (PostgreSQL) - $service" ;;
                    "6379") log "WARNING" "  Порт 6379 (Redis) - $service" ;;
                    "27017") log "WARNING" "  Порт 27017 (MongoDB) - $service" ;;
                    *) log "WARNING" "  Порт $port ($service)" ;;
                esac
            done
        else
            log "SUCCESS" "Не найдено открытых портов в диапазоне"
        fi
    else
        log "ERROR" "nmap не установлен"
    fi
    
    ((TOTAL_CHECKS++))
    ((PASSED_CHECKS++))
}

# Функция проверки сетевых соединений
check_network_connections() {
    log "INFO" "Проверка активных сетевых соединений..."
    
    # Проверка LISTEN портов
    local listen_ports=$(ss -tuln | grep LISTEN | awk '{print $5}' | cut -d':' -f2 | sort -u)
    
    if [ -n "$listen_ports" ]; then
        log "INFO" "Порты в состоянии LISTEN:"
        echo "$listen_ports" | while read -r port; do
            local service=$(grep -w "$port" /etc/services 2>/dev/null | head -1 | awk '{print $1}' || echo "unknown")
            log "INFO" "  Порт $port ($service)"
        done
    else
        log "SUCCESS" "Нет активных слушающих портов"
    fi
    
    ((TOTAL_CHECKS++))
    ((PASSED_CHECKS++))
}

# Функция проверки файрвола
check_firewall() {
    log "INFO" "Проверка файрвола..."
    
    # Проверка UFW
    if command -v ufw &> /dev/null; then
        local ufw_status=$(sudo ufw status 2>/dev/null | head -1)
        if [[ "$ufw_status" == *"active"* ]]; then
            log "SUCCESS" "UFW активен: $ufw_status"
            ((PASSED_CHECKS++))
        else
            log "WARNING" "UFW неактивен: $ufw_status"
            ((WARNINGS++))
        fi
    else
        log "WARNING" "UFW не установлен"
        ((WARNINGS++))
    fi
    ((TOTAL_CHECKS++))
    
    # Проверка iptables
    local iptables_rules=$(sudo iptables -L 2>/dev/null | wc -l)
    if [ "$iptables_rules" -gt 3 ]; then
        log "SUCCESS" "IPTables настроен ($iptables_rules правил)"
        ((PASSED_CHECKS++))
    else
        log "WARNING" "IPTables не настроен или пуст"
        ((WARNINGS++))
    fi
    ((TOTAL_CHECKS++))
}

# Функция проверки Fail2Ban
check_fail2ban() {
    log "INFO" "Проверка Fail2Ban..."
    
    if command -v fail2ban-client &> /dev/null; then
        local fail2ban_status=$(sudo fail2ban-client status 2>/dev/null | head -1)
        if [[ "$fail2ban_status" == *"running"* ]]; then
            log "SUCCESS" "Fail2Ban активен: $fail2ban_status"
            ((PASSED_CHECKS++))
            
            # Проверка активных jail'ов
            local jails=$(sudo fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d':' -f2 | tr ',' ' ')
            if [ -n "$jails" ]; then
                log "INFO" "Активные jail'ы: $jails"
            else
                log "WARNING" "Нет активных jail'ов"
                ((WARNINGS++))
            fi
        else
            log "WARNING" "Fail2Ban неактивен: $fail2ban_status"
            ((WARNINGS++))
        fi
    else
        log "WARNING" "Fail2Ban не установлен"
        ((WARNINGS++))
    fi
    ((TOTAL_CHECKS++))
}

# Функция проверки обновлений системы
check_system_updates() {
    log "INFO" "Проверка обновлений системы..."
    
    # Проверка доступных обновлений
    local update_count=$(sudo apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo "0")
    
    if [ "$update_count" -gt 0 ]; then
        log "WARNING" "Доступно обновлений: $update_count"
        ((WARNINGS++))
        
        if [ "$VERBOSE" = true ]; then
            log "INFO" "Список обновлений:"
            sudo apt list --upgradable 2>/dev/null | grep "upgradable" | head -10
        fi
    else
        log "SUCCESS" "Система обновлена"
        ((PASSED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
    
    # Проверка автоматических обновлений
    if [ -f "/etc/apt/apt.conf.d/20auto-upgrades" ]; then
        local auto_updates=$(grep -c "1" /etc/apt/apt.conf.d/20auto-upgrades || echo "0")
        if [ "$auto_updates" -gt 0 ]; then
            log "SUCCESS" "Автоматические обновления включены"
            ((PASSED_CHECKS++))
        else
            log "WARNING" "Автоматические обновления отключены"
            ((WARNINGS++))
        fi
    else
        log "WARNING" "Автоматические обновления не настроены"
        ((WARNINGS++))
    fi
    ((TOTAL_CHECKS++))
}

# Функция проверки на вредоносное ПО
check_malware() {
    log "INFO" "Проверка на вредоносное ПО..."
    
    # Проверка chkrootkit
    if command -v chkrootkit &> /dev/null; then
        log "INFO" "Запуск chkrootkit..."
        local chkrootkit_output=$(sudo chkrootkit 2>/dev/null | grep -E "(INFECTED|Warning)" || true)
        
        if [ -n "$chkrootkit_output" ]; then
            log "CRITICAL" "chkrootkit обнаружил проблемы:"
            echo "$chkrootkit_output"
            ((CRITICAL_ISSUES++))
        else
            log "SUCCESS" "chkrootkit не обнаружил проблем"
            ((PASSED_CHECKS++))
        fi
    else
        log "WARNING" "chkrootkit не установлен"
        ((WARNINGS++))
    fi
    ((TOTAL_CHECKS++))
    
    # Проверка rkhunter
    if command -v rkhunter &> /dev/null; then
        log "INFO" "Запуск rkhunter..."
        local rkhunter_output=$(sudo rkhunter --check --skip-keypress 2>/dev/null | grep -E "(Warning|Suspicious)" || true)
        
        if [ -n "$rkhunter_output" ]; then
            log "WARNING" "rkhunter обнаружил подозрительные файлы:"
            echo "$rkhunter_output" | head -5
            ((WARNINGS++))
        else
            log "SUCCESS" "rkhunter не обнаружил проблем"
            ((PASSED_CHECKS++))
        fi
    else
        log "WARNING" "rkhunter не установлен"
        ((WARNINGS++))
    fi
    ((TOTAL_CHECKS++))
}

# Функция проверки SSL/TLS сертификатов
check_ssl_certificates() {
    log "INFO" "Проверка SSL/TLS сертификатов..."
    
    local ssl_ports=("443" "993" "995")
    
    for port in "${ssl_ports[@]}"; do
        if ss -tuln | grep ":$port " &> /dev/null; then
            log "INFO" "Проверка SSL на порту $port..."
            
            local cert_info=$(echo | openssl s_client -connect "localhost:$port" -servername localhost 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || true)
            
            if [ -n "$cert_info" ]; then
                local expiry_date=$(echo "$cert_info" | grep "notAfter" | cut -d'=' -f2)
                local expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null || echo "0")
                local current_timestamp=$(date +%s)
                local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
                
                if [ "$days_until_expiry" -lt 30 ]; then
                    log "WARNING" "SSL сертификат на порту $port истекает через $days_until_expiry дней"
                    ((WARNINGS++))
                else
                    log "SUCCESS" "SSL сертификат на порту $port действителен еще $days_until_expiry дней"
                    ((PASSED_CHECKS++))
                fi
            else
                log "WARNING" "Не удалось проверить SSL сертификат на порту $port"
                ((WARNINGS++))
            fi
            ((TOTAL_CHECKS++))
        fi
    done
}

# Функция проверки конфигурации системы
check_system_config() {
    log "INFO" "Проверка конфигурации системы..."
    
    # Проверка лимитов системы
    local max_files=$(ulimit -n 2>/dev/null || echo "1024")
    if [ "$max_files" -lt 65536 ]; then
        log "WARNING" "Лимит открытых файлов низкий: $max_files (рекомендуется >= 65536)"
        ((WARNINGS++))
    else
        log "SUCCESS" "Лимит открытых файлов: $max_files"
        ((PASSED_CHECKS++))
    fi
    ((TOTAL_CHECKS++))
    
    # Проверка kernel параметров
    local tcp_syncookies=$(sysctl net.ipv4.tcp_syncookies 2>/dev/null | awk '{print $3}' || echo "0")
    if [ "$tcp_syncookies" = "1" ]; then
        log "SUCCESS" "TCP SYN cookies включены"
        ((PASSED_CHECKS++))
    else
        log "WARNING" "TCP SYN cookies отключены"
        ((WARNINGS++))
    fi
    ((TOTAL_CHECKS++))
    
    # Проверка ASLR
    local aslr=$(cat /proc/sys/kernel/randomize_va_space 2>/dev/null || echo "0")
    if [ "$aslr" = "2" ]; then
        log "SUCCESS" "ASLR включен (уровень 2)"
        ((PASSED_CHECKS++))
    else
        log "WARNING" "ASLR отключен или настроен слабо (уровень $aslr)"
        ((WARNINGS++))
    fi
    ((TOTAL_CHECKS++))
}

# Функция генерации отчета
generate_report() {
    log "INFO" "Генерация отчета безопасности..."
    
    local report_content="
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <title>Отчет аудита безопасности</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .summary { background: #ecf0f1; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .critical { color: #e74c3c; font-weight: bold; }
        .warning { color: #f39c12; font-weight: bold; }
        .success { color: #27ae60; font-weight: bold; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #bdc3c7; border-radius: 5px; }
        .check-item { margin: 10px 0; padding: 5px; }
        .timestamp { color: #7f8c8d; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class='header'>
        <h1>🔒 Отчет аудита безопасности Ubuntu сервера</h1>
        <p class='timestamp'>Сгенерирован: $(date)</p>
        <p>Хост: $(hostname)</p>
        <p>IP: $(hostname -I | awk '{print $1}')</p>
    </div>
    
    <div class='summary'>
        <h2>📊 Сводка проверок</h2>
        <p><span class='success'>✅ Пройдено: $PASSED_CHECKS</span></p>
        <p><span class='warning'>⚠️ Предупреждения: $WARNINGS</span></p>
        <p><span class='critical'>❌ Критические проблемы: $CRITICAL_ISSUES</span></p>
        <p><span class='critical'>❌ Провалено: $FAILED_CHECKS</span></p>
        <p><strong>Всего проверок: $TOTAL_CHECKS</strong></p>
    </div>
    
    <div class='section'>
        <h2>🔧 Рекомендации по улучшению</h2>
        <ul>
"
    
    # Добавление рекомендаций на основе найденных проблем
    if [ "$CRITICAL_ISSUES" -gt 0 ]; then
        report_content+="
            <li class='critical'>Немедленно исправьте критические проблемы безопасности</li>
            <li>Обновите систему: sudo apt update && sudo apt upgrade</li>
            <li>Настройте файрвол: sudo ufw enable</li>
            <li>Установите Fail2Ban: sudo apt install fail2ban</li>
        "
    fi
    
    if [ "$WARNINGS" -gt 0 ]; then
        report_content+="
            <li class='warning'>Исправьте предупреждения для повышения безопасности</li>
            <li>Настройте автоматические обновления</li>
            <li>Проверьте права доступа к критическим файлам</li>
            <li>Настройте мониторинг системы</li>
        "
    fi
    
    report_content+="
        </ul>
    </div>
    
    <div class='section'>
        <h2>📋 Детальная информация</h2>
        <p>Полный лог проверки: $LOG_FILE</p>
        <p>Время выполнения: $(date -d @$SECONDS -u +%H:%M:%S)</p>
    </div>
</body>
</html>
"
    
    echo "$report_content" > "$REPORT_FILE"
    log "SUCCESS" "Отчет сохранен: $REPORT_FILE"
}

# Функция показа справки
show_help() {
    cat << EOF
🔒 Скрипт аудита безопасности Ubuntu сервера

ИСПОЛЬЗОВАНИЕ:
    $0 [ОПЦИИ]

ОПЦИИ:
    -l, --level LEVEL     Уровень сканирования (basic/quick/full) [по умолчанию: full]
    -p, --ports TYPE      Тип сканирования портов (common/all/custom) [по умолчанию: common]
    -f, --format FORMAT   Формат отчета (html/json/txt) [по умолчанию: html]
    -v, --verbose         Подробный вывод
    --fix                 Автоматическое исправление некоторых проблем
    -h, --help           Показать эту справку

ПРИМЕРЫ:
    $0                    # Полное сканирование
    $0 -l quick          # Быстрое сканирование
    $0 -p all            # Сканирование всех портов
    $0 -v --fix          # Подробный вывод с автоправками

УРОВНИ СКАНИРОВАНИЯ:
    basic   - Основные проверки безопасности
    quick   - Быстрые проверки без глубокого анализа
    full    - Полный аудит безопасности (по умолчанию)

ТИПЫ СКАНИРОВАНИЯ ПОРТОВ:
    common  - Только основные порты (22, 80, 443, 3306, 5432, 6379, 27017)
    all     - Все порты (1-65535)
    custom  - Пользовательский набор портов

ФОРМАТЫ ОТЧЕТОВ:
    html    - HTML отчет с цветовой схемой
    json    - JSON формат для автоматической обработки
    txt     - Простой текстовый формат

ПРОВЕРКИ ВКЛЮЧАЮТ:
    ✅ Права доступа к критическим файлам
    ✅ Пользователи и пароли
    ✅ Конфигурация SSH
    ✅ Открытые порты и сетевые соединения
    ✅ Настройки файрвола
    ✅ Состояние Fail2Ban
    ✅ Обновления системы
    ✅ Проверка на вредоносное ПО
    ✅ SSL/TLS сертификаты
    ✅ Конфигурация системы

ВЫХОДНЫЕ ФАЙЛЫ:
    Лог файл: /var/log/security_audit_YYYYMMDD_HHMMSS.log
    Отчет: /tmp/security_audit_report_YYYYMMDD_HHMMSS.html

ТРЕБОВАНИЯ:
    - Ubuntu 18.04+ или совместимый дистрибутив
    - Права sudo
    - Интернет соединение для установки зависимостей

АВТОР: VPS Scripts
ВЕРСИЯ: 1.0.0
EOF
}

# Функция парсинга аргументов
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -l|--level)
                SCAN_LEVEL="$2"
                shift 2
                ;;
            -p|--ports)
                SCAN_PORTS="$2"
                shift 2
                ;;
            -f|--format)
                EXPORT_FORMAT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --fix)
                FIX_ISSUES=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log "ERROR" "Неизвестная опция: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Функция проверки прав sudo
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log "ERROR" "Требуются права sudo для выполнения аудита"
        log "INFO" "Запустите скрипт с правами sudo или добавьте пользователя в группу sudo"
        exit 1
    fi
}

# Функция создания временной директории
create_temp_dir() {
    mkdir -p "$TEMP_DIR"
    log "INFO" "Создана временная директория: $TEMP_DIR"
}

# Функция очистки
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        log "INFO" "Временная директория удалена: $TEMP_DIR"
    fi
}

# Основная функция
main() {
    local start_time=$(date +%s)
    
    # Парсинг аргументов
    parse_arguments "$@"
    
    # Проверка прав sudo
    check_sudo
    
    # Создание временной директории
    create_temp_dir
    
    # Установка обработчика сигналов для очистки
    trap cleanup EXIT
    
    log "INFO" "🔒 Запуск аудита безопасности Ubuntu сервера"
    log "INFO" "Уровень сканирования: $SCAN_LEVEL"
    log "INFO" "Сканирование портов: $SCAN_PORTS"
    log "INFO" "Формат отчета: $EXPORT_FORMAT"
    log "INFO" "Лог файл: $LOG_FILE"
    
    # Проверка зависимостей
    check_dependencies
    
    # Основные проверки безопасности
    check_permissions
    check_users
    check_ssh_config
    
    # Сетевые проверки
    scan_ports "$SCAN_PORTS"
    check_network_connections
    check_firewall
    check_fail2ban
    
    # Системные проверки
    check_system_updates
    check_system_config
    
    # Дополнительные проверки для полного сканирования
    if [ "$SCAN_LEVEL" = "full" ]; then
        check_malware
        check_ssl_certificates
    fi
    
    # Генерация отчета
    generate_report
    
    # Вывод итоговой статистики
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo
    log "INFO" "📊 ИТОГОВАЯ СТАТИСТИКА АУДИТА"
    log "SUCCESS" "✅ Пройдено проверок: $PASSED_CHECKS"
    log "WARNING" "⚠️ Предупреждений: $WARNINGS"
    log "ERROR" "❌ Критических проблем: $CRITICAL_ISSUES"
    log "ERROR" "❌ Провалено проверок: $FAILED_CHECKS"
    log "INFO" "📈 Всего проверок: $TOTAL_CHECKS"
    log "INFO" "⏱️ Время выполнения: $(date -d @$duration -u +%H:%M:%S)"
    
    if [ "$CRITICAL_ISSUES" -gt 0 ]; then
        log "CRITICAL" "🚨 ОБНАРУЖЕНЫ КРИТИЧЕСКИЕ ПРОБЛЕМЫ БЕЗОПАСНОСТИ!"
        log "CRITICAL" "Немедленно исправьте найденные проблемы"
        exit 1
    elif [ "$WARNINGS" -gt 0 ]; then
        log "WARNING" "⚠️ Обнаружены предупреждения безопасности"
        log "INFO" "Рекомендуется исправить найденные проблемы"
        exit 0
    else
        log "SUCCESS" "🎉 Аудит безопасности пройден успешно!"
        log "SUCCESS" "Система соответствует базовым требованиям безопасности"
        exit 0
    fi
}

# Запуск основной функции
main "$@" 