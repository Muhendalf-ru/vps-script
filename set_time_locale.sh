#!/bin/bash

# =============================================================================
# Time and Locale Setup Script
# Скрипт настройки времени и локали для Ubuntu серверов
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
    -t, --timezone TIMEZONE    Установить часовой пояс (например, Europe/Moscow)
    -l, --locale LOCALE        Установить локаль (например, ru_RU.UTF-8)
    -i, --interactive          Интерактивный режим (по умолчанию)
    -v, --verbose              Подробный вывод
    -h, --help                 Показать эту справку

Примеры:
    $0                                    # Интерактивный режим
    $0 -t Europe/Moscow -l ru_RU.UTF-8   # Прямая установка
    $0 -i                                  # Принудительно интерактивный режим

EOF
}

# Функция для проверки зависимостей
check_dependencies() {
    if ! command -v timedatectl &> /dev/null; then
        log_error "timedatectl не найден. Установите systemd"
        exit 1
    fi
    
    if ! command -v locale-gen &> /dev/null; then
        log_error "locale-gen не найден. Установите locales"
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

# Функция для показа текущих настроек
show_current_settings() {
    echo
    echo "============================================================================="
    log_info "Текущие настройки системы"
    echo "============================================================================="
    echo
    
    echo "🕐 Часовой пояс:"
    timedatectl show --property=Timezone --value
    echo
    
    echo "🌍 Локаль:"
    locale | grep -E "^(LANG|LC_ALL)" || echo "LANG не установлен"
    echo
    
    echo "📅 Дата и время:"
    date
    echo
}

# Функция для показа доступных часовых поясов
show_timezone_options() {
    cat << EOF
=============================================================================
🕐 Выберите часовой пояс:
=============================================================================

Основные часовые пояса:

1)  Europe/Moscow          (UTC+3)  - Москва
2)  Europe/London          (UTC+0)  - Лондон
3)  Europe/Paris           (UTC+1)  - Париж
4)  Europe/Berlin          (UTC+1)  - Берлин
5)  America/New_York       (UTC-5)  - Нью-Йорк
6)  America/Los_Angeles    (UTC-8)  - Лос-Анджелес
7)  Asia/Tokyo             (UTC+9)  - Токио
8)  Asia/Shanghai          (UTC+8)  - Шанхай
9)  Australia/Sydney       (UTC+10) - Сидней
10) UTC                    (UTC+0)  - UTC

11) Ввести вручную
12) Пропустить (оставить текущий)

EOF
}

# Функция для показа доступных локалей
show_locale_options() {
    cat << EOF
=============================================================================
🌍 Выберите локаль:
=============================================================================

Основные локали:

1)  ru_RU.UTF-8            - Русский (Россия)
2)  en_US.UTF-8            - English (United States)
3)  en_GB.UTF-8            - English (United Kingdom)
4)  de_DE.UTF-8            - Deutsch (Deutschland)
5)  fr_FR.UTF-8            - Français (France)
6)  es_ES.UTF-8            - Español (España)
7)  it_IT.UTF-8            - Italiano (Italia)
8)  pt_BR.UTF-8            - Português (Brasil)
9)  ja_JP.UTF-8            - 日本語 (日本)
10) zh_CN.UTF-8            - 中文 (中国)

11) Ввести вручную
12) Пропустить (оставить текущий)

EOF
}

# Функция для выбора часового пояса
select_timezone() {
    local timezone=""
    
    show_timezone_options
    
    while true; do
        read -p "Введите номер (1-12): " choice
        
        case $choice in
            1) timezone="Europe/Moscow" ;;
            2) timezone="Europe/London" ;;
            3) timezone="Europe/Paris" ;;
            4) timezone="Europe/Berlin" ;;
            5) timezone="America/New_York" ;;
            6) timezone="America/Los_Angeles" ;;
            7) timezone="Asia/Tokyo" ;;
            8) timezone="Asia/Shanghai" ;;
            9) timezone="Australia/Sydney" ;;
            10) timezone="UTC" ;;
            11)
                read -p "Введите часовой пояс (например, Europe/Moscow): " timezone
                ;;
            12)
                log_info "Часовой пояс не изменен"
                return 1
                ;;
            *)
                log_error "Неверный выбор. Попробуйте снова."
                continue
                ;;
        esac
        
        # Проверка существования часового пояса
        if timedatectl list-timezones | grep -q "^$timezone$"; then
            break
        else
            log_error "Часовой пояс '$timezone' не найден"
            if [[ $choice -eq 11 ]]; then
                continue
            else
                log_error "Ошибка в предустановленных опциях"
                exit 1
            fi
        fi
    done
    
    echo "$timezone"
}

# Функция для выбора локали
select_locale() {
    local locale=""
    
    show_locale_options
    
    while true; do
        read -p "Введите номер (1-12): " choice
        
        case $choice in
            1) locale="ru_RU.UTF-8" ;;
            2) locale="en_US.UTF-8" ;;
            3) locale="en_GB.UTF-8" ;;
            4) locale="de_DE.UTF-8" ;;
            5) locale="fr_FR.UTF-8" ;;
            6) locale="es_ES.UTF-8" ;;
            7) locale="it_IT.UTF-8" ;;
            8) locale="pt_BR.UTF-8" ;;
            9) locale="ja_JP.UTF-8" ;;
            10) locale="zh_CN.UTF-8" ;;
            11)
                read -p "Введите локаль (например, ru_RU.UTF-8): " locale
                ;;
            12)
                log_info "Локаль не изменена"
                return 1
                ;;
            *)
                log_error "Неверный выбор. Попробуйте снова."
                continue
                ;;
        esac
        
        # Проверка существования локали
        if locale -a | grep -q "^$locale$"; then
            break
        else
            log_error "Локаль '$locale' не найдена"
            if [[ $choice -eq 11 ]]; then
                continue
            else
                log_error "Ошибка в предустановленных опциях"
                exit 1
            fi
        fi
    done
    
    echo "$locale"
}

# Функция для валидации часового пояса
validate_timezone() {
    local timezone=$1
    if ! timedatectl list-timezones | grep -q "^$timezone$"; then
        log_error "Неверный часовой пояс: $timezone"
        return 1
    fi
    return 0
}

# Функция для валидации локали
validate_locale() {
    local locale=$1
    if ! locale -a | grep -q "^$locale$"; then
        log_error "Неверная локаль: $locale"
        return 1
    fi
    return 0
}

# Функция для установки часового пояса
set_timezone() {
    local timezone=$1
    
    log_info "Установка часового пояса: $timezone"
    
    if timedatectl set-timezone "$timezone"; then
        log_success "Часовой пояс установлен: $timezone"
        return 0
    else
        log_error "Ошибка установки часового пояса"
        return 1
    fi
}

# Функция для установки локали
set_locale() {
    local locale=$1
    
    log_info "Установка локали: $locale"
    
    # Генерация локали
    if locale-gen "$locale"; then
        log_success "Локаль сгенерирована: $locale"
    else
        log_error "Ошибка генерации локали"
        return 1
    fi
    
    # Обновление системной локали
    if update-locale LANG="$locale"; then
        log_success "Системная локаль обновлена: $locale"
    else
        log_error "Ошибка обновления системной локали"
        return 1
    fi
    
    return 0
}

# Функция для показа финальной информации
show_final_info() {
    echo
    echo "============================================================================="
    log_success "Настройка времени и локали завершена!"
    echo "============================================================================="
    echo
    
    echo "📋 Текущие настройки:"
    echo "  • Часовой пояс: $(timedatectl show --property=Timezone --value)"
    echo "  • Локаль: $(locale | grep '^LANG=' | cut -d= -f2 || echo 'не установлена')"
    echo "  • Дата и время: $(date)"
    echo
    
    echo "⚠️  ВАЖНО:"
    echo "  • Для применения изменений локали может потребоваться перезагрузка"
    echo "  • Или выполните: source /etc/default/locale"
    echo
    
    echo "🔗 Полезные команды:"
    echo "  • Показать все часовые пояса: timedatectl list-timezones"
    echo "  • Показать все локали: locale -a"
    echo "  • Проверить настройки: timedatectl && locale"
    echo
}

# =============================================================================
# ОСНОВНАЯ ЛОГИКА
# =============================================================================

main() {
    # Переменные
    local TIMEZONE=""
    local LOCALE=""
    local INTERACTIVE=true
    local VERBOSE=false
    
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--timezone)
                TIMEZONE="$2"
                INTERACTIVE=false
                shift 2
                ;;
            -l|--locale)
                LOCALE="$2"
                INTERACTIVE=false
                shift 2
                ;;
            -i|--interactive)
                INTERACTIVE=true
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
    check_root
    check_dependencies
    
    echo "============================================================================="
    echo "⏰ Time and Locale Setup Script"
    echo "Настройка времени и локали для Ubuntu серверов"
    echo "============================================================================="
    
    # Показ текущих настроек
    show_current_settings
    
    # Интерактивный режим
    if [[ "$INTERACTIVE" == "true" ]]; then
        # Выбор часового пояса
        if [[ -z "$TIMEZONE" ]]; then
            TIMEZONE=$(select_timezone)
            if [[ $? -ne 0 ]]; then
                TIMEZONE=""
            fi
        fi
        
        # Выбор локали
        if [[ -z "$LOCALE" ]]; then
            LOCALE=$(select_locale)
            if [[ $? -ne 0 ]]; then
                LOCALE=""
            fi
        fi
    fi
    
    # Валидация и установка часового пояса
    if [[ -n "$TIMEZONE" ]]; then
        if validate_timezone "$TIMEZONE"; then
            set_timezone "$TIMEZONE"
        else
            exit 1
        fi
    fi
    
    # Валидация и установка локали
    if [[ -n "$LOCALE" ]]; then
        if validate_locale "$LOCALE"; then
            set_locale "$LOCALE"
        else
            exit 1
        fi
    fi
    
    # Показ финальной информации
    show_final_info
}

# Запуск основной функции
main "$@"
