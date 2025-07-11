#!/bin/bash

# =============================================================================
# SSH Key Generator for GitHub Actions Deployment
# Генератор SSH-ключей для автодеплоя через GitHub Actions
# =============================================================================

set -euo pipefail  # Строгий режим

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

# Функция для показа справки
show_help() {
    cat << EOF
Использование: $0 [ОПЦИИ]

Опции:
    -t, --type TYPE        Тип ключа (rsa, ed25519, ecdsa) [по умолчанию: ed25519]
    -b, --bits BITS        Размер ключа (для RSA: 2048, 4096; для ECDSA: 256, 384, 521) [по умолчанию: 4096 для RSA, 256 для ECDSA]
    -f, --file FILENAME    Имя файла ключа (без расширения) [по умолчанию: id_ed25519 или id_rsa]
    -c, --comment COMMENT  Комментарий к ключу [по умолчанию: deploy-key-YYYY-MM-DD]
    -p, --passphrase       Запросить пароль для ключа
    -o, --output DIR       Директория для сохранения [по умолчанию: ~/.ssh]
    -f, --force           Перезаписать существующий ключ
    -g, --github-actions  Оптимизировать для GitHub Actions (без пароля, специальный комментарий)
    -v, --verbose         Подробный вывод
    -h, --help            Показать эту справку

Примеры:
    $0                                    # Создать ed25519 ключ для GitHub Actions
    $0 -t rsa -b 4096                    # Создать RSA 4096 ключ
    $0 -t ed25519 -c "my-deploy-key"     # Создать ключ с комментарием
    $0 -g -o /tmp                        # Создать ключ для GitHub Actions в /tmp

EOF
}

# Функция для проверки зависимостей
check_dependencies() {
    if ! command -v ssh-keygen &> /dev/null; then
        log_error "ssh-keygen не найден. Установите openssh-client"
        exit 1
    fi
}

# Функция для валидации типа ключа
validate_key_type() {
    local key_type=$1
    case $key_type in
        rsa|ed25519|ecdsa)
            return 0
            ;;
        *)
            log_error "Неверный тип ключа: $key_type. Поддерживаемые типы: rsa, ed25519, ecdsa"
            return 1
            ;;
    esac
}

# Функция для валидации размера ключа
validate_key_bits() {
    local key_type=$1
    local bits=$2
    
    case $key_type in
        rsa)
            if [[ ! "$bits" =~ ^(2048|4096)$ ]]; then
                log_error "Для RSA поддерживаются размеры: 2048, 4096"
                return 1
            fi
            ;;
        ecdsa)
            if [[ ! "$bits" =~ ^(256|384|521)$ ]]; then
                log_error "Для ECDSA поддерживаются размеры: 256, 384, 521"
                return 1
            fi
            ;;
        ed25519)
            if [[ "$bits" != "256" ]]; then
                log_warning "Для ed25519 размер всегда 256 бит, игнорируем указанный размер"
                bits=256
            fi
            ;;
    esac
    echo "$bits"
}

# Функция для определения имени файла по умолчанию
get_default_filename() {
    local key_type=$1
    case $key_type in
        rsa) echo "id_rsa" ;;
        ed25519) echo "id_ed25519" ;;
        ecdsa) echo "id_ecdsa" ;;
    esac
}

# Функция для создания SSH директории
create_ssh_directory() {
    local ssh_dir=$1
    if [[ ! -d "$ssh_dir" ]]; then
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        log_success "Создана директория: $ssh_dir"
    else
        log_info "Директория уже существует: $ssh_dir"
    fi
}

# Функция для проверки существования ключа
check_existing_key() {
    local key_path=$1
    local force=$2
    
    if [[ -f "$key_path" ]] && [[ "$force" != "true" ]]; then
        log_warning "Ключ $key_path уже существует"
        read -p "Перезаписать? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Операция отменена"
            exit 0
        fi
    fi
}

# Функция для генерации ключа
generate_key() {
    local key_type=$1
    local bits=$2
    local key_path=$3
    local comment=$4
    local passphrase=$5
    local verbose=$6
    
    local ssh_keygen_cmd="ssh-keygen -t $key_type"
    
    # Добавляем размер ключа (кроме ed25519)
    if [[ "$key_type" != "ed25519" ]]; then
        ssh_keygen_cmd="$ssh_keygen_cmd -b $bits"
    fi
    
    # Добавляем файл и комментарий
    ssh_keygen_cmd="$ssh_keygen_cmd -f $key_path -C $comment"
    
    # Добавляем пароль или его отсутствие
    if [[ "$passphrase" == "true" ]]; then
        log_info "Будет запрошен пароль для ключа"
    else
        ssh_keygen_cmd="$ssh_keygen_cmd -N \"\""
    fi
    
    # Выполняем генерацию
    if [[ "$verbose" == "true" ]]; then
        log_info "Выполняется команда: $ssh_keygen_cmd"
    fi
    
    if eval "$ssh_keygen_cmd"; then
        log_success "SSH ключ успешно сгенерирован"
    else
        log_error "Ошибка при генерации ключа"
        exit 1
    fi
}

# Функция для установки прав доступа
set_permissions() {
    local key_path=$1
    chmod 600 "$key_path"
    chmod 644 "${key_path}.pub"
    log_success "Установлены правильные права доступа"
}

# Функция для показа информации о ключе
show_key_info() {
    local key_path=$1
    local key_type=$2
    local bits=$3
    
    echo
    echo "============================================================================="
    log_success "SSH ключ успешно создан!"
    echo "============================================================================="
    echo
    echo "📋 Информация о ключе:"
    echo "  • Тип: $key_type"
    echo "  • Размер: $bits бит"
    echo "  • Приватный ключ: $key_path"
    echo "  • Публичный ключ: ${key_path}.pub"
    echo
    echo "🔑 Содержимое публичного ключа:"
    echo "============================================================================="
    cat "${key_path}.pub"
    echo "============================================================================="
    echo
    echo "📝 Для использования в GitHub Actions:"
    echo "  1. Скопируйте содержимое публичного ключа выше"
    echo "  2. Добавьте его в Deploy Keys вашего репозитория"
    echo "  3. Добавьте приватный ключ в GitHub Secrets как SSH_PRIVATE_KEY"
    echo
    echo "🔗 Полезные ссылки:"
    echo "  • GitHub Deploy Keys: https://github.com/USER/REPO/settings/keys"
    echo "  • GitHub Secrets: https://github.com/USER/REPO/settings/secrets/actions"
    echo
}

# Функция для проверки ключа
test_key() {
    local key_path=$1
    if ssh-keygen -l -f "$key_path" &>/dev/null; then
        log_success "Ключ прошел проверку"
        if [[ "${VERBOSE:-false}" == "true" ]]; then
            ssh-keygen -l -f "$key_path"
        fi
    else
        log_error "Ошибка проверки ключа"
        exit 1
    fi
}

# =============================================================================
# ОСНОВНАЯ ЛОГИКА
# =============================================================================

main() {
    # Переменные по умолчанию
    local KEY_TYPE="ed25519"
    local KEY_BITS="4096"
    local KEY_FILENAME=""
    local KEY_COMMENT=""
    local USE_PASSPHRASE=false
    local OUTPUT_DIR="$HOME/.ssh"
    local FORCE=false
    local GITHUB_ACTIONS=false
    local VERBOSE=false
    
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)
                KEY_TYPE="$2"
                shift 2
                ;;
            -b|--bits)
                KEY_BITS="$2"
                shift 2
                ;;
            -f|--file)
                KEY_FILENAME="$2"
                shift 2
                ;;
            -c|--comment)
                KEY_COMMENT="$2"
                shift 2
                ;;
            -p|--passphrase)
                USE_PASSPHRASE=true
                shift
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --force)
                FORCE=true
                shift
                ;;
            -g|--github-actions)
                GITHUB_ACTIONS=true
                shift
                ;;
            -v|--verbose)
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
    check_dependencies
    
    if ! validate_key_type "$KEY_TYPE"; then
        exit 1
    fi
    
    KEY_BITS=$(validate_key_bits "$KEY_TYPE" "$KEY_BITS")
    
    # Установка значений по умолчанию
    if [[ -z "$KEY_FILENAME" ]]; then
        KEY_FILENAME=$(get_default_filename "$KEY_TYPE")
    fi
    
    if [[ -z "$KEY_COMMENT" ]]; then
        if [[ "$GITHUB_ACTIONS" == "true" ]]; then
            KEY_COMMENT="github-actions-deploy-$(date +%F)"
        else
            KEY_COMMENT="deploy-key-$(date +%F)"
        fi
    fi
    
    # Создание директории
    create_ssh_directory "$OUTPUT_DIR"
    
    # Полный путь к ключу
    local KEY_PATH="$OUTPUT_DIR/$KEY_FILENAME"
    
    # Проверка существования
    check_existing_key "$KEY_PATH" "$FORCE"
    
    # Генерация ключа
    log_info "Генерация SSH ключа типа $KEY_TYPE ($KEY_BITS бит)..."
    generate_key "$KEY_TYPE" "$KEY_BITS" "$KEY_PATH" "$KEY_COMMENT" "$USE_PASSPHRASE" "$VERBOSE"
    
    # Установка прав
    set_permissions "$KEY_PATH"
    
    # Проверка ключа
    test_key "$KEY_PATH"
    
    # Показ информации
    show_key_info "$KEY_PATH" "$KEY_TYPE" "$KEY_BITS"
}

# Запуск основной функции
main "$@"
