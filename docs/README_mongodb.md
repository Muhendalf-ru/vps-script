# 🐘 Скрипт установки MongoDB

## `setup_mongodb.sh` - Установка и настройка MongoDB

Профессиональный скрипт для установки и настройки MongoDB с поддержкой различных версий, аутентификации, репликации и мониторинга.

---

## ✨ Функции

- 🎯 **Автоматическое определение версии**: выбор совместимой версии MongoDB для вашей Ubuntu
- 🔐 **Безопасность**: автоматическая настройка аутентификации с генерацией паролей
- ⚡ **Производительность**: автоматическая оптимизация памяти и движков хранения
- 🔄 **Высокая доступность**: настройка replica sets и config servers
- 📊 **Мониторинг**: интеграция с MongoDB Exporter для Prometheus
- 💾 **Бэкапы**: автоматические ежедневные бэкапы с ротацией
- 🛡️ **Безопасность**: правильные права доступа и системные пользователи
- 📋 **Информативность**: готовые строки подключения и команды управления

---

## 🚀 Быстрый запуск

```bash
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/setup_mongodb.sh -o setup_mongodb.sh && chmod +x setup_mongodb.sh && sudo ./setup_mongodb.sh
```

---

## 📋 Примеры использования

### Базовая установка (автоматическое определение версии)

```bash
./setup_mongodb.sh
```

### MongoDB 5.0 на нестандартном порту

```bash
./setup_mongodb.sh -v 5.0 -p 27018
```

### С аутентификацией и лимитом памяти

```bash
./setup_mongodb.sh -a -m 2048
```

### Config server для replica set

```bash
./setup_mongodb.sh -r -c
```

### In-memory с бэкапами

```bash
./setup_mongodb.sh -b -s inMemory
```

### Только установка без запуска

```bash
./setup_mongodb.sh -n
```

### Подробный вывод

```bash
./setup_mongodb.sh -v -a
```

---

## 🔧 Доступные опции

| Опция                  | Описание                                              |
| ---------------------- | ----------------------------------------------------- |
| `-v, --version`        | Версия MongoDB (4.4, 5.0, 6.0, 7.0) [автоопределение] |
| `-p, --port`           | Порт MongoDB (по умолчанию: 27017)                    |
| `-d, --data-dir`       | Директория для данных                                 |
| `-l, --log-dir`        | Директория для логов                                  |
| `-u, --user`           | Пользователь MongoDB                                  |
| `-a, --auth`           | Включить аутентификацию                               |
| `-r, --replica-set`    | Настроить как часть replica set                       |
| `-c, --config-server`  | Настроить как config server                           |
| `-m, --memory`         | Лимит памяти в MB                                     |
| `-s, --storage-engine` | Движок хранения (wiredTiger, inMemory)                |
| `-b, --backup`         | Настроить автоматические бэкапы                       |
| `-n, --no-start`       | Не запускать MongoDB после установки                  |
| `--verbose`            | Подробный вывод                                       |
| `-h, --help`           | Показать справку                                      |

---

## 🔐 Аутентификация

При использовании флага `-a` скрипт автоматически:

- Генерирует безопасный пароль (32 байта base64)
- Создает администратора с полными правами
- Выдает готовую строку подключения
- Настраивает безопасную конфигурацию

### Пример вывода с аутентификацией:

```
🐘 MongoDB успешно установлен и настроен!

📋 Информация о установке:
   Версия: 6.0.12
   Порт: 27017
   Пользователь: admin
   Пароль: xK9mP2nQ8vR5tY7wZ1aB3cD6eF9gH2jK
   Данные: /var/lib/mongodb
   Логи: /var/log/mongodb

🔗 Строка подключения:
   mongodb://admin:xK9mP2nQ8vR5tY7wZ1aB3cD6eF9gH2jK@localhost:27017/admin

📝 Команды управления:
   Статус: sudo systemctl status mongod
   Запуск: sudo systemctl start mongod
   Остановка: sudo systemctl stop mongod
   Перезапуск: sudo systemctl restart mongod

📊 Мониторинг:
   MongoDB Exporter: http://localhost:9216/metrics
   Prometheus endpoint: /metrics
```

---

## 📊 Мониторинг и бэкапы

### MongoDB Exporter

- **Порт**: 9216
- **Метрики**: для Prometheus
- **Автозапуск**: включен
- **Конфигурация**: автоматическая

### Автоматические бэкапы

- **Расписание**: ежедневно в 2:00
- **Ротация**: 7 дней
- **Сжатие**: включено
- **Уведомления**: по email (опционально)

### Логирование

- **Формат**: структурированные логи
- **Ротация**: автоматическая
- **Уровень**: INFO
- **Профилирование**: медленные операции

---

## 📋 Подробное описание функций

### 🎯 Гибкая установка

Поддержка всех актуальных версий MongoDB с автоматическим выбором оптимальных параметров для каждой версии.

### 🔐 Безопасность

- Автоматическая генерация безопасных паролей
- Настройка аутентификации и авторизации
- Правильные права доступа к файлам
- Создание системного пользователя

### ⚡ Производительность

- Автоматическая оптимизация памяти
- Настройка движков хранения
- Оптимизация индексов
- Настройка кэширования

### 🔄 Высокая доступность

- Настройка replica sets
- Конфигурация config servers
- Автоматическое переключение
- Мониторинг состояния

### 📊 Мониторинг

- Интеграция с Prometheus
- Метрики производительности
- Алерты и уведомления
- Дашборды Grafana

### 💾 Бэкапы

- Автоматические ежедневные бэкапы
- Ротация и сжатие
- Проверка целостности
- Восстановление из бэкапов

---

## 🔄 Совместимость версий

Скрипт автоматически определяет совместимую версию MongoDB для вашей версии Ubuntu:

| Ubuntu Version | Кодовое имя | Поддерживаемые версии MongoDB | Рекомендуемая |
| -------------- | ----------- | ----------------------------- | ------------- |
| 24.04+         | noble       | 7.0+                          | 7.0           |
| 22.04+         | jammy       | 6.0+, 7.0                     | 6.0           |
| 20.04+         | focal       | 5.0+, 6.0, 7.0                | 5.0           |
| 18.04+         | bionic      | 4.4+, 5.0, 6.0, 7.0           | 4.4           |

### Автоматическое переключение

Если указанная версия несовместима с вашей Ubuntu, скрипт автоматически переключится на рекомендуемую версию:

```bash
[INFO] Обнаружена Ubuntu 24.04 (noble)
[WARNING] Ubuntu 24.04 (noble) поддерживает MongoDB 7.0+
[WARNING] Автоматически переключаемся на MongoDB 7.0
[INFO] Автоматически переключились на MongoDB 7.0 для совместимости
```

### 🛡️ Безопасность

- Правильные права доступа
- Создание системного пользователя
- Настройка файрвола
- Шифрование данных

### 📋 Информативность

- Готовые строки подключения
- Команды управления
- Инструкции по настройке
- Примеры использования

---

## 🔄 Replica Set

### Настройка replica set

```bash
# Первичный узел
./setup_mongodb.sh -r -p 27017

# Вторичный узел 1
./setup_mongodb.sh -r -p 27018

# Вторичный узел 2
./setup_mongodb.sh -r -p 27019
```

### Инициализация replica set

```bash
# Подключитесь к первичному узлу
mongosh --port 27017

# Инициализируйте replica set
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "localhost:27017" },
    { _id: 1, host: "localhost:27018" },
    { _id: 2, host: "localhost:27019" }
  ]
})
```

---

## 🛠️ Требования

- **ОС**: Ubuntu 20.04 или новее
- **Права**: root (sudo)
- **Память**: минимум 512MB RAM
- **Диск**: минимум 1GB свободного места
- **Архитектура**: x86_64, ARM64

---

## 🔍 Устранение неполадок

### Проблема: MongoDB не запускается

```bash
# Проверьте статус
sudo systemctl status mongod

# Проверьте логи
sudo journalctl -u mongod -f

# Проверьте права доступа
ls -la /var/lib/mongodb/
ls -la /var/log/mongodb/
```

### Проблема: Не удается подключиться

```bash
# Проверьте порт
sudo netstat -tlnp | grep 27017

# Проверьте файрвол
sudo ufw status

# Проверьте конфигурацию
sudo cat /etc/mongod.conf
```

### Проблема: Недостаточно памяти

```bash
# Проверьте использование памяти
free -h

# Уменьшите лимит памяти
sudo systemctl stop mongod
# Отредактируйте /etc/mongod.conf
sudo systemctl start mongod
```

---

## 📝 Логи

Скрипт создает подробные логи в:

- `/var/log/mongodb_setup_YYYYMMDD_HHMMSS.log`
- `/var/log/mongodb/mongod.log`

---

## 🔄 Обновление

Для обновления скрипта:

```bash
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/setup_mongodb.sh -o setup_mongodb.sh
chmod +x setup_mongodb.sh
```

---

## 🔧 Альтернативные методы установки

Если основной скрипт не работает, используйте альтернативные методы:

### 🐳 Установка через Snap

```bash
# Скачать альтернативный скрипт
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/setup_mongodb_alternative.sh -o setup_mongodb_alternative.sh
chmod +x setup_mongodb_alternative.sh

# Установка MongoDB 7.0 через Snap
sudo ./setup_mongodb_alternative.sh -v 7.0 -m snap
```

### 🐳 Установка через Docker

```bash
# Установка MongoDB 7.0 через Docker
sudo ./setup_mongodb_alternative.sh -v 7.0 -m docker
```

### 📦 Установка через репозиторий (альтернативный скрипт)

```bash
# Установка MongoDB 7.0 через репозиторий
sudo ./setup_mongodb_alternative.sh -v 7.0 -m repo
```

### Доступные методы:

| Метод      | Описание                | Преимущества                 | Недостатки                    |
| ---------- | ----------------------- | ---------------------------- | ----------------------------- |
| **repo**   | Официальный репозиторий | Полная интеграция с системой | Может не работать на новых ОС |
| **snap**   | Snap пакет              | Простота, автообновления     | Ограниченная настройка        |
| **docker** | Docker контейнер        | Изоляция, гибкость           | Дополнительные ресурсы        |

---

## 🧪 Тестирование и диагностика

### Быстрый тест репозитория

```bash
# Скачать тестовый скрипт
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/test_mongodb_7.sh -o test_mongodb_7.sh
chmod +x test_mongodb_7.sh

# Запустить тест
sudo ./test_mongodb_7.sh
```

### Детальная диагностика

```bash
# Скачать скрипт диагностики
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/debug_mongodb_repo.sh -o debug_mongodb_repo.sh
chmod +x debug_mongodb_repo.sh

# Запустить детальную диагностику
sudo ./debug_mongodb_repo.sh
```

### Что проверяют тесты:

#### test_mongodb_7.sh

- ✅ Доступность GPG ключей MongoDB 6.0 и 7.0
- ✅ Доступность репозиториев для разных версий Ubuntu
- ✅ Существующие MongoDB репозитории в системе

#### debug_mongodb_repo.sh

- ✅ Версия Ubuntu и архитектура
- ✅ Подключение к интернету
- ✅ Доступность GPG ключей (старый и новый URL)
- ✅ Доступность всех комбинаций репозиториев
- ✅ DNS и HTTPS соединения
- ✅ Ручная установка MongoDB 7.0
- ✅ Доступность пакетов в репозитории

### Пример вывода диагностики:

```bash
[INFO] Проверка версии Ubuntu...
Версия: 24.04
Кодовое имя: noble
[SUCCESS] Интернет доступен
[SUCCESS] GPG ключ MongoDB 7.0 доступен
[SUCCESS] MongoDB репозиторий найден в apt update
[SUCCESS] Пакет mongodb-org доступен
mongodb-org/jammy/mongodb-org/7.0 7.0.21 amd64
```

---

## 🔗 Связанные скрипты

- **[setup_mongodb.sh](README_mongodb.md)** - Установка MongoDB с автоопределением версии
- **[setup_mongodb_alternative.sh](README_mongodb_alternative.md)** - Альтернативные методы установки MongoDB
- **[test_mongodb_7.sh](README_mongodb_test.md)** - Тестирование MongoDB репозиториев
- **[debug_mongodb_repo.sh](README_mongodb_debug.md)** - Детальная диагностика MongoDB
- **[security_audit.sh](README_security_audit.md)** - Аудит безопасности системы
- **[start.sh](README_start.md)** - Основная настройка сервера

---

## 📞 Поддержка

- **Issues**: [GitHub Issues](https://github.com/Muhendalf-ru/vps-script/issues)
- **Документация**: [Главный README](../README.md)
- **Автор**: Pesherkino VPN

---

**Версия**: 1.0.0  
**Последнее обновление**: 12.07.2025
