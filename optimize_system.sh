#!/bin/bash

# =============================================================================
# System Optimization Script
# Скрипт оптимизации Ubuntu сервера для максимальной производительности
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
    -s, --swap SIZE          Размер swap в GB [по умолчанию: 50% от RAM]
    -f, --filesystem         Оптимизировать файловую систему
    -n, --network            Оптимизировать сетевые настройки
    -m, --memory             Оптимизировать настройки памяти
    -d, --disk               Оптимизировать настройки диска
    -l, --limits             Настроить системные лимиты
    -k, --kernel             Оптимизировать параметры ядра
    -a, --all                Выполнить все оптимизации
    -b, --backup             Создать резервные копии конфигов
    -r, --restore            Восстановить из резервной копии
    -v, --verbose            Подробный вывод
    -h, --help               Показать эту справку

Примеры:
    $0 -a                      # Все оптимизации
    $0 -s 4 -f -n             # Swap 4GB + файловая система + сеть
    $0 -m -k                  # Память + ядро
    $0 -b                     # Только резервная копия
    $0 -r                     # Восстановление

EOF
}

# Функция для проверки root прав
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Этот скрипт должен быть запущен с правами root (sudo)"
        exit 1
    fi
}

# Функция для проверки системы
check_system() {
    log_info "Проверка системы..."
    
    # Проверка дистрибутива
    if ! grep -q "Ubuntu" /etc/os-release; then
        log_warning "Скрипт тестировался на Ubuntu. Другие дистрибутивы могут работать некорректно"
    fi
    
    # Проверка архитектуры
    local arch=$(uname -m)
    if [[ "$arch" != "x86_64" && "$arch" != "aarch64" ]]; then
        log_warning "Архитектура $arch может требовать дополнительной настройки"
    fi
    
    log_success "Система проверена"
}

# Функция для получения информации о системе
get_system_info() {
    echo "============================================================================="
    log_info "Информация о системе"
    echo "============================================================================="
    
    echo "🖥️  Система:"
    echo "  • ОС: $(lsb_release -d | cut -f2)"
    echo "  • Ядро: $(uname -r)"
    echo "  • Архитектура: $(uname -m)"
    echo
    
    echo "💾 Память:"
    local total_mem=$(free -h | awk 'NR==2{print $2}')
    local used_mem=$(free -h | awk 'NR==2{print $3}')
    local free_mem=$(free -h | awk 'NR==2{print $4}')
    echo "  • Всего: $total_mem"
    echo "  • Использовано: $used_mem"
    echo "  • Свободно: $free_mem"
    echo
    
    echo "💿 Диски:"
    df -h | grep -E '^/dev/' | while read line; do
        local device=$(echo $line | awk '{print $1}')
        local size=$(echo $line | awk '{print $2}')
        local used=$(echo $line | awk '{print $3}')
        local mount=$(echo $line | awk '{print $6}')
        echo "  • $device: $size (использовано: $used) -> $mount"
    done
    echo
    
    echo "🌐 Сеть:"
    ip route | grep default | awk '{print "  • Шлюз: " $3}'
    echo "  • DNS: $(cat /etc/resolv.conf | grep nameserver | head -1 | awk '{print $2}')"
    echo
}

# Функция для создания резервных копий
create_backup() {
    local backup_dir="/opt/system_backup_$(date +%Y%m%d_%H%M%S)"
    
    log_info "Создание резервных копий в $backup_dir"
    
    mkdir -p "$backup_dir"
    
    # Резервные копии важных файлов
    local files=(
        "/etc/sysctl.conf"
        "/etc/security/limits.conf"
        "/etc/fstab"
        "/etc/systemd/system.conf"
        "/etc/systemd/user.conf"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            cp "$file" "$backup_dir/"
            log_info "Сохранен: $file"
        fi
    done
    
    # Резервная копия sysctl параметров
    sysctl -a > "$backup_dir/sysctl_current.conf" 2>/dev/null || true
    
    log_success "Резервные копии созданы в $backup_dir"
    echo "$backup_dir" > /tmp/last_backup_path
}

# Функция для восстановления из резервной копии
restore_backup() {
    local backup_path=""
    
    if [[ -f "/tmp/last_backup_path" ]]; then
        backup_path=$(cat /tmp/last_backup_path)
    else
        log_error "Путь к резервной копии не найден"
        exit 1
    fi
    
    if [[ ! -d "$backup_path" ]]; then
        log_error "Резервная копия не найдена: $backup_path"
        exit 1
    fi
    
    log_warning "Восстановление из резервной копии: $backup_path"
    read -p "Продолжить? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Восстановление отменено"
        exit 0
    fi
    
    # Восстановление файлов
    if [[ -f "$backup_path/sysctl.conf" ]]; then
        cp "$backup_path/sysctl.conf" /etc/sysctl.conf
        log_success "Восстановлен: /etc/sysctl.conf"
    fi
    
    if [[ -f "$backup_path/limits.conf" ]]; then
        cp "$backup_path/limits.conf" /etc/security/limits.conf
        log_success "Восстановлен: /etc/security/limits.conf"
    fi
    
    if [[ -f "$backup_path/fstab" ]]; then
        cp "$backup_path/fstab" /etc/fstab
        log_success "Восстановлен: /etc/fstab"
    fi
    
    # Применение изменений
    sysctl -p
    log_success "Восстановление завершено"
}

# Функция для настройки swap
setup_swap() {
    local swap_size=$1
    
    log_info "Настройка swap размером ${swap_size}GB..."
    
    # Проверка существующего swap
    if swapon --show | grep -q "/swapfile"; then
        log_warning "Swap файл уже существует"
        read -p "Перезаписать? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Настройка swap пропущена"
            return 0
        fi
        
        # Отключение существующего swap
        swapoff /swapfile 2>/dev/null || true
        rm -f /swapfile
    fi
    
    # Создание swap файла
    fallocate -l ${swap_size}G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    
    # Добавление в fstab
    if ! grep -q "/swapfile" /etc/fstab; then
        echo "/swapfile none swap sw 0 0" >> /etc/fstab
    fi
    
    # Настройка swappiness
    echo "vm.swappiness = 10" >> /etc/sysctl.conf
    
    log_success "Swap настроен: ${swap_size}GB"
}

# Функция для оптимизации файловой системы
optimize_filesystem() {
    log_info "Оптимизация файловой системы..."
    
    # Настройка noatime для всех файловых систем
    sed -i 's/defaults/defaults,noatime/g' /etc/fstab
    
    # Настройка readahead для SSD
    if command -v blockdev &> /dev/null; then
        for device in /dev/sd*; do
            if [[ -b "$device" ]]; then
                blockdev --setra 32768 "$device" 2>/dev/null || true
            fi
        done
    fi
    
    # Настройка I/O scheduler
    for device in /sys/block/sd*/queue/scheduler; do
        if [[ -f "$device" ]]; then
            echo "mq-deadline" > "$device" 2>/dev/null || true
        fi
    done
    
    log_success "Файловая система оптимизирована"
}

# Функция для оптимизации сетевых настроек
optimize_network() {
    log_info "Оптимизация сетевых настроек..."
    
    # Сетевые параметры
    cat >> /etc/sysctl.conf << EOF

# Network optimization
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 65535
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.core.default_qdisc = fq
EOF

    log_success "Сетевые настройки оптимизированы"
}

# Функция для оптимизации памяти
optimize_memory() {
    log_info "Оптимизация настроек памяти..."
    
    # Параметры памяти
    cat >> /etc/sysctl.conf << EOF

# Memory optimization
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
vm.min_free_kbytes = 65536
vm.overcommit_memory = 1
vm.overcommit_ratio = 50
vm.panic_on_oom = 0
vm.oom_kill_allocating_task = 0
vm.oom_dump_tasks = 1
vm.lowmem_reserve_ratio = 256 256 32
vm.drop_caches = 0
EOF

    log_success "Настройки памяти оптимизированы"
}

# Функция для оптимизации диска
optimize_disk() {
    log_info "Оптимизация настроек диска..."
    
    # Параметры диска
    cat >> /etc/sysctl.conf << EOF

# Disk optimization
fs.file-max = 2097152
fs.nr_open = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
fs.inotify.max_queued_events = 512
EOF

    log_success "Настройки диска оптимизированы"
}

# Функция для настройки лимитов
setup_limits() {
    log_info "Настройка системных лимитов..."
    
    # Создание резервной копии
    cp /etc/security/limits.conf /etc/security/limits.conf.backup
    
    # Добавление лимитов
    cat >> /etc/security/limits.conf << EOF

# System optimization limits
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 32768
* hard nproc 32768
* soft memlock unlimited
* hard memlock unlimited
* soft core unlimited
* hard core unlimited
root soft nofile 1048576
root hard nofile 1048576
root soft nproc 32768
root hard nproc 32768
EOF

    # Настройка systemd лимитов
    mkdir -p /etc/systemd/system.conf.d
    cat > /etc/systemd/system.conf.d/limits.conf << EOF
[Manager]
DefaultLimitNOFILE=1048576
DefaultLimitNPROC=32768
EOF

    log_success "Системные лимиты настроены"
}

# Функция для оптимизации ядра
optimize_kernel() {
    log_info "Оптимизация параметров ядра..."
    
    # Параметры ядра
    cat >> /etc/sysctl.conf << EOF

# Kernel optimization
kernel.panic = 10
kernel.panic_on_oops = 1
kernel.keys.root_maxkeys = 1000000
kernel.keys.root_maxbytes = 25000000
kernel.keys.maxkeys = 2000
kernel.keys.maxbytes = 20000
kernel.sysrq = 1
kernel.core_uses_pid = 1
kernel.core_pattern = core.%e.%p.%t
kernel.msgmax = 65536
kernel.msgmnb = 65536
kernel.msgmni = 2878
kernel.sem = 250 32000 100 142
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
kernel.shmmni = 4096
kernel.threads-max = 143360
kernel.pid_max = 65536
kernel.randomize_va_space = 2
kernel.kptr_restrict = 1
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
kernel.perf_event_paranoid = 2
EOF

    log_success "Параметры ядра оптимизированы"
}

# Функция для применения изменений
apply_changes() {
    log_info "Применение изменений..."
    
    # Применение sysctl параметров
    sysctl -p
    
    # Перезагрузка systemd
    systemctl daemon-reload
    
    # Проверка swap
    if swapon --show | grep -q "/swapfile"; then
        log_success "Swap активен"
    fi
    
    log_success "Изменения применены"
}

# Функция для показа результатов
show_results() {
    echo
    echo "============================================================================="
    log_success "Оптимизация системы завершена!"
    echo "============================================================================="
    echo
    
    echo "📊 Результаты оптимизации:"
    echo
    
    echo "💾 Память и Swap:"
    echo "  • Swap: $(swapon --show | grep swapfile | awk '{print $3}' || echo 'не настроен')"
    echo "  • Swappiness: $(sysctl vm.swappiness | awk '{print $3}')"
    echo "  • Dirty ratio: $(sysctl vm.dirty_ratio | awk '{print $3}')"
    echo
    
    echo "🌐 Сеть:"
    echo "  • TCP congestion control: $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')"
    echo "  • TCP max connections: $(sysctl net.core.somaxconn | awk '{print $3}')"
    echo "  • TCP window scaling: $(sysctl net.ipv4.tcp_window_scaling | awk '{print $3}')"
    echo
    
    echo "💿 Файловая система:"
    echo "  • Max open files: $(sysctl fs.file-max | awk '{print $3}')"
    echo "  • Inotify watches: $(sysctl fs.inotify.max_user_watches | awk '{print $3}')"
    echo
    
    echo "🔧 Системные лимиты:"
    echo "  • Soft nofile: $(ulimit -Sn)"
    echo "  • Hard nofile: $(ulimit -Hn)"
    echo "  • Soft nproc: $(ulimit -Su)"
    echo "  • Hard nproc: $(ulimit -Hu)"
    echo
    
    echo "⚠️  Рекомендации:"
    echo "  • Перезагрузите систему для применения всех изменений"
    echo "  • Мониторьте производительность после оптимизации"
    echo "  • Проверьте логи на наличие ошибок"
    echo "  • Резервная копия сохранена в /opt/system_backup_*"
    echo
    
    echo "🔗 Полезные команды:"
    echo "  • Проверить swap: free -h"
    echo "  • Проверить сеть: ss -tuln"
    echo "  • Проверить лимиты: ulimit -a"
    echo "  • Проверить sysctl: sysctl -a | grep -E '(vm|net|fs)'"
    echo
}

# =============================================================================
# ОСНОВНАЯ ЛОГИКА
# =============================================================================

main() {
    # Переменные
    local SWAP_SIZE=""
    local OPTIMIZE_FS=false
    local OPTIMIZE_NETWORK=false
    local OPTIMIZE_MEMORY=false
    local OPTIMIZE_DISK=false
    local SETUP_LIMITS=false
    local OPTIMIZE_KERNEL=false
    local DO_ALL=false
    local CREATE_BACKUP=false
    local RESTORE_BACKUP=false
    local VERBOSE=false
    
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--swap)
                SWAP_SIZE="$2"
                shift 2
                ;;
            -f|--filesystem)
                OPTIMIZE_FS=true
                shift
                ;;
            -n|--network)
                OPTIMIZE_NETWORK=true
                shift
                ;;
            -m|--memory)
                OPTIMIZE_MEMORY=true
                shift
                ;;
            -d|--disk)
                OPTIMIZE_DISK=true
                shift
                ;;
            -l|--limits)
                SETUP_LIMITS=true
                shift
                ;;
            -k|--kernel)
                OPTIMIZE_KERNEL=true
                shift
                ;;
            -a|--all)
                DO_ALL=true
                shift
                ;;
            -b|--backup)
                CREATE_BACKUP=true
                shift
                ;;
            -r|--restore)
                RESTORE_BACKUP=true
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
    
    echo "============================================================================="
    echo "⚡ System Optimization Script"
    echo "Оптимизация Ubuntu сервера для максимальной производительности"
    echo "============================================================================="
    
    # Проверка системы
    check_system
    
    # Показ информации о системе
    get_system_info
    
    # Восстановление из резервной копии
    if [[ "$RESTORE_BACKUP" == "true" ]]; then
        restore_backup
        exit 0
    fi
    
    # Создание резервной копии
    if [[ "$CREATE_BACKUP" == "true" ]] || [[ "$DO_ALL" == "true" ]]; then
        create_backup
    fi
    
    # Определение размера swap
    if [[ -z "$SWAP_SIZE" ]]; then
        local total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
        SWAP_SIZE=$((total_mem / 2 / 1024))  # 50% от RAM в GB
        if [[ "$SWAP_SIZE" -lt 1 ]]; then
            SWAP_SIZE=1
        fi
    fi
    
    # Выполнение оптимизаций
    if [[ "$DO_ALL" == "true" ]]; then
        OPTIMIZE_FS=true
        OPTIMIZE_NETWORK=true
        OPTIMIZE_MEMORY=true
        OPTIMIZE_DISK=true
        SETUP_LIMITS=true
        OPTIMIZE_KERNEL=true
    fi
    
    # Настройка swap
    if [[ -n "$SWAP_SIZE" ]]; then
        setup_swap "$SWAP_SIZE"
    fi
    
    # Оптимизация файловой системы
    if [[ "$OPTIMIZE_FS" == "true" ]]; then
        optimize_filesystem
    fi
    
    # Оптимизация сети
    if [[ "$OPTIMIZE_NETWORK" == "true" ]]; then
        optimize_network
    fi
    
    # Оптимизация памяти
    if [[ "$OPTIMIZE_MEMORY" == "true" ]]; then
        optimize_memory
    fi
    
    # Оптимизация диска
    if [[ "$OPTIMIZE_DISK" == "true" ]]; then
        optimize_disk
    fi
    
    # Настройка лимитов
    if [[ "$SETUP_LIMITS" == "true" ]]; then
        setup_limits
    fi
    
    # Оптимизация ядра
    if [[ "$OPTIMIZE_KERNEL" == "true" ]]; then
        optimize_kernel
    fi
    
    # Применение изменений
    apply_changes
    
    # Показ результатов
    show_results
}

# Запуск основной функции
main "$@" 