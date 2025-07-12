# 🔍 Детальная диагностика MongoDB

## `debug_mongodb_repo.sh` - Детальная диагностика MongoDB репозиториев

Скрипт для глубокой диагностики проблем с MongoDB репозиториями. Предоставляет подробную информацию о системе, сети, репозиториях и выполняет ручную установку для проверки.

---

## 🎯 Назначение

Этот скрипт выполняет комплексную диагностику:

- **Системная информация**: версия Ubuntu, архитектура, ресурсы
- **Сетевая диагностика**: подключение, DNS, SSL сертификаты
- **Репозитории**: проверка всех комбинаций версий и дистрибутивов
- **Ручная установка**: тестирование установки MongoDB 7.0
- **Анализ пакетов**: проверка доступности в репозитории

---

## 🚀 Быстрый запуск

```bash
# Скачивание и запуск
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/debug_mongodb_repo.sh -o debug_mongodb_repo.sh && chmod +x debug_mongodb_repo.sh && sudo ./debug_mongodb_repo.sh
```

---

## 📋 Что проверяет скрипт

### 1. Системная информация

- Версия Ubuntu и кодовое имя
- Архитектура процессора
- Использование памяти и диска
- Версия ядра

### 2. Сетевая диагностика

- Подключение к интернету (ping, curl)
- DNS разрешение доменов MongoDB
- SSL сертификаты репозиториев
- Скорость соединения

### 3. GPG ключи

- **Старый URL**: `https://www.mongodb.org/static/pgp/server-7.0.asc`
- **Новый URL**: `https://pgp.mongodb.com/server-7.0.asc`
- Проверка подписи ключей
- Импорт в систему

### 4. Репозитории

- Проверка всех комбинаций:
  - `noble/mongodb-org/7.0`
  - `jammy/mongodb-org/7.0`
  - `focal/mongodb-org/7.0`
  - `bionic/mongodb-org/7.0`
- Доступность через apt update
- Проверка SSL соединений

### 5. Ручная установка

- Очистка старых репозиториев
- Добавление GPG ключа
- Добавление репозитория
- Обновление apt
- Проверка доступности пакетов

### 6. Анализ пакетов

- Поиск mongodb-org пакета
- Проверка зависимостей
- Анализ версий

---

## 📊 Пример вывода

### Успешная диагностика

```bash
=============================================================================
🔍 Детальная диагностика MongoDB репозитория
=============================================================================

[INFO] Проверка версии Ubuntu...
Версия: 24.04
Кодовое имя: noble
Архитектура: x86_64
Ядро: 6.8.0-31-generic

[INFO] Проверка системных ресурсов...
Память: 2.0G / 4.0G (50%)
Диск: 15G / 50G (30%)

[INFO] Проверка подключения к интернету...
[SUCCESS] Интернет доступен (ping: 8.8.8.8)
[SUCCESS] DNS работает (nslookup: repo.mongodb.org)

[INFO] Проверка SSL сертификатов...
[SUCCESS] SSL сертификат repo.mongodb.org валиден
[SUCCESS] SSL сертификат pgp.mongodb.com валиден

[INFO] Проверка GPG ключей...
[SUCCESS] Старый GPG ключ MongoDB 7.0 доступен
[SUCCESS] Новый GPG ключ MongoDB 7.0 доступен

[INFO] Проверка репозиториев...
[SUCCESS] Репозиторий noble/mongodb-org/7.0 недоступен (ожидаемо)
[SUCCESS] Репозиторий jammy/mongodb-org/7.0 доступен
[SUCCESS] Репозиторий focal/mongodb-org/7.0 доступен

[INFO] Ручная установка MongoDB 7.0...
[SUCCESS] GPG ключ добавлен
[SUCCESS] Репозиторий добавлен
[SUCCESS] apt update выполнен
[SUCCESS] Пакет mongodb-org найден:
mongodb-org/jammy/mongodb-org/7.0 7.0.21 amd64

=============================================================================
[SUCCESS] Диагностика завершена успешно
=============================================================================
```

### Проблемы с сетью

```bash
[INFO] Проверка подключения к интернету...
[ERROR] Интернет недоступен (ping: 8.8.8.8)
[ERROR] DNS не работает (nslookup: repo.mongodb.org)

[INFO] Проверка сетевых настроек...
Интерфейсы:
lo: 127.0.0.1/8
eth0: 192.168.1.100/24

Маршруты:
default via 192.168.1.1 dev eth0
```

### Проблемы с репозиторием

```bash
[INFO] Проверка репозиториев...
[ERROR] Все репозитории недоступны
[ERROR] SSL соединение не удается
[ERROR] apt update завершился с ошибкой

[INFO] Анализ ошибок apt...
E: The repository 'https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 Release' does not have a Release file.
```

---

## 🔍 Интерпретация результатов

### ✅ Все проверки прошли успешно

- Система готова к установке MongoDB
- Репозиторий доступен и работает
- **Рекомендация**: Используйте основной скрипт установки

### ⚠️ Частичные проблемы

- Сеть работает, но репозиторий недоступен
- GPG ключи доступны, но пакеты не найдены
- **Рекомендация**: Попробуйте альтернативные методы

### ❌ Критические проблемы

- Нет подключения к интернету
- SSL сертификаты недействительны
- Все репозитории недоступны
- **Рекомендация**: Проверьте сеть и настройки

---

## 🛠️ Использование результатов

### Если диагностика успешна

```bash
# Установка MongoDB 7.0
sudo ./setup_mongodb.sh -v 7.0 -a
```

### Если есть проблемы с репозиторием

```bash
# Попробуйте альтернативный метод
sudo ./setup_mongodb_alternative.sh -v 7.0 -m snap
```

### Если проблемы с сетью

```bash
# Проверьте настройки сети
sudo nano /etc/network/interfaces
sudo systemctl restart networking
```

---

## 🔧 Настройка диагностики

### Добавление проверки других версий

```bash
# Добавьте проверку MongoDB 6.0
log_info "Проверка MongoDB 6.0..."
check_gpg_key "https://www.mongodb.org/static/pgp/server-6.0.asc"
check_repository "jammy/mongodb-org/6.0"
```

### Добавление проверки других дистрибутивов

```bash
# Добавьте проверку Debian
declare -a distributions=(
    "noble"
    "jammy"
    "focal"
    "bionic"
    "bookworm"  # Добавьте эту строку
)
```

### Настройка таймаутов

```bash
# Увеличьте таймаут для медленных соединений
CURL_TIMEOUT=30
PING_TIMEOUT=10
```

---

## 🚨 Устранение неполадок

### Проблема: Нет подключения к интернету

```bash
# Проверьте физическое подключение
ip link show

# Проверьте DHCP
sudo dhclient -r
sudo dhclient

# Проверьте файрвол
sudo ufw status
sudo iptables -L
```

### Проблема: DNS не работает

```bash
# Проверьте resolv.conf
cat /etc/resolv.conf

# Добавьте Google DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf

# Перезапустите сеть
sudo systemctl restart systemd-resolved
```

### Проблема: SSL сертификаты недействительны

```bash
# Обновите CA сертификаты
sudo apt update
sudo apt install ca-certificates

# Проверьте дату системы
date
sudo ntpdate pool.ntp.org
```

### Проблема: Репозиторий недоступен

```bash
# Проверьте прокси
echo $http_proxy
echo $https_proxy

# Попробуйте без прокси
unset http_proxy https_proxy
sudo ./debug_mongodb_repo.sh
```

---

## 📝 Логи и отладка

### Сохранение полного лога

```bash
# Сохранить весь вывод в файл
sudo ./debug_mongodb_repo.sh 2>&1 | tee mongodb_debug_full.log
```

### Включение отладочной информации

```bash
# Запустить с отладкой
bash -x ./debug_mongodb_repo.sh
```

### Анализ логов apt

```bash
# Проверить логи apt
sudo cat /var/log/apt/history.log | tail -50

# Проверить ошибки
sudo cat /var/log/apt/term.log | tail -50
```

---

## 🔄 Обновление

Для обновления скрипта:

```bash
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/debug_mongodb_repo.sh -o debug_mongodb_repo.sh
chmod +x debug_mongodb_repo.sh
```

---

## 🔗 Связанные скрипты

- **[setup_mongodb.sh](README_mongodb.md)** - Основной скрипт установки MongoDB
- **[setup_mongodb_alternative.sh](README_mongodb_alternative.md)** - Альтернативные методы установки
- **[test_mongodb_7.sh](README_mongodb_test.md)** - Быстрое тестирование MongoDB

---

## 📞 Поддержка

Если диагностика показывает проблемы:

1. **Проверьте сетевые настройки** и файрвол
2. **Попробуйте альтернативные методы** установки
3. **Проверьте системные ресурсы** и права доступа
4. **Создайте issue** на GitHub с полным логом диагностики

---

## 📄 Лицензия

Этот скрипт распространяется под лицензией MIT. См. файл [LICENSE](../LICENSE) для получения дополнительной информации.
