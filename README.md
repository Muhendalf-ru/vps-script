# 🚀 VPS Script Collection

> **Коллекция скриптов для быстрой настройки Ubuntu серверов**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-orange)](https://ubuntu.com/)
[![Shell](https://img.shields.io/badge/Shell-Bash-green)](https://www.gnu.org/software/bash/)

---

## 📋 Содержание

- [🚀 Быстрый старт](#-быстрый-старт)
- [📚 Документация по скриптам](#-документация-по-скриптам)
- [🛠️ Требования](#️-требования)
- [📖 Как использовать](#-как-использовать)
- [🛡️ Безопасность](#️-безопасность)
- [📄 Лицензия](#-лицензия)

---

## 🚀 Быстрый старт

### ⚡ Полная настройка сервера за 5 минут

```bash
# 1. Основная настройка (пользователь, SSH, Docker, безопасность)
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/start.sh -o start.sh && chmod +x start.sh && sudo ./start.sh

# 2. Оптимизация системы (производительность)
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/optimize_system.sh -o optimize_system.sh && chmod +x optimize_system.sh && sudo ./optimize_system.sh -a

# 3. Аудит безопасности (проверка)
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/security_audit.sh -o security_audit.sh && chmod +x security_audit.sh && sudo ./security_audit.sh
```

### 🎯 Быстрые команды по категориям

#### 🔧 Базовая настройка

```bash
# Основной скрипт настройки
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/start.sh -o start.sh && chmod +x start.sh && sudo ./start.sh

# Настройка времени и локали
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/set_time_locale.sh -o set_time_locale.sh && chmod +x set_time_locale.sh && sudo ./set_time_locale.sh
```

#### 🔑 SSH и безопасность

```bash
# Генерация SSH-ключа для автодеплоя
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/generate_ssh_key.sh -o generate_ssh_key.sh && chmod +x generate_ssh_key.sh && ./generate_ssh_key.sh -g

# Аудит безопасности
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/security_audit.sh -o security_audit.sh && chmod +x security_audit.sh && sudo ./security_audit.sh
```

#### ⚡ Оптимизация и производительность

```bash
# Полная оптимизация системы
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/optimize_system.sh -o optimize_system.sh && chmod +x optimize_system.sh && sudo ./optimize_system.sh -a

# Только swap и файловая система
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/optimize_system.sh -o optimize_system.sh && chmod +x optimize_system.sh && sudo ./optimize_system.sh -s 4 -f
```

#### 🗄️ Базы данных

```bash
# MongoDB с аутентификацией
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/setup_mongodb.sh -o setup_mongodb.sh && chmod +x setup_mongodb.sh && sudo ./setup_mongodb.sh -a

# MongoDB 6.0 на нестандартном порту
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/setup_mongodb.sh -o setup_mongodb.sh && chmod +x setup_mongodb.sh && sudo ./setup_mongodb.sh -v 6.0 -p 27018
```

---

## 📚 Документация по скриптам

### 🔧 Основные скрипты

| Скрипт                | Описание                   | Документация                                           |
| --------------------- | -------------------------- | ------------------------------------------------------ |
| `start.sh`            | Основная настройка сервера | [📖 README_start.md](docs/README_start.md)             |
| `set_time_locale.sh`  | Настройка времени и локали | [📖 README_time_locale.md](docs/README_time_locale.md) |
| `generate_ssh_key.sh` | Генерация SSH-ключа        | [📖 README_ssh_key.md](docs/README_ssh_key.md)         |

### 🛡️ Безопасность и оптимизация

| Скрипт               | Описание            | Документация                                                   |
| -------------------- | ------------------- | -------------------------------------------------------------- |
| `security_audit.sh`  | Аудит безопасности  | [📖 README_security_audit.md](docs/README_security_audit.md)   |
| `optimize_system.sh` | Оптимизация системы | [📖 README_optimize_system.md](docs/README_optimize_system.md) |

### 🗄️ Базы данных

| Скрипт             | Описание          | Документация                                   |
| ------------------ | ----------------- | ---------------------------------------------- |
| `setup_mongodb.sh` | Установка MongoDB | [📖 README_mongodb.md](docs/README_mongodb.md) |

---

## 🛠️ Требования

### 📋 Системные требования

- **ОС**: Ubuntu 20.04 или новее
- **Архитектура**: x86_64, ARM64
- **Права**: root (sudo)
- **Интернет**: требуется для загрузки пакетов

### 🔧 Зависимости

Все скрипты автоматически устанавливают необходимые зависимости:

- `curl`, `wget` - загрузка файлов
- `nmap`, `net-tools` - сетевая диагностика
- `openssl` - SSL/TLS проверки
- `fail2ban`, `ufw` - безопасность
- `docker` - контейнеризация

---

## 📖 Как использовать

### 🎯 Пошаговая инструкция

1. **Подключитесь к серверу** по SSH
2. **Выполните основной скрипт** для базовой настройки
3. **Настройте время и локаль** при необходимости
4. **Создайте SSH-ключ** для автодеплоя
5. **Оптимизируйте систему** для производительности
6. **Проведите аудит безопасности** для проверки
7. **Установите базы данных** по необходимости

### 🔄 Обновление скриптов

```bash
# Клонирование репозитория
git clone https://github.com/Muhendalf-ru/vps-script.git
cd vps-script

# Обновление
git pull origin main
```

### 📝 Логи и отчеты

Все скрипты создают подробные логи:

- **Логи скриптов**: `/var/log/script_name_*.log`
- **Отчеты безопасности**: `/tmp/security_audit_report_*.html`
- **Резервные копии**: `/opt/system_backup_*`

---

## 🛡️ Безопасность

### 🔒 Принципы безопасности

- **Минимальные права**: скрипты используют только необходимые права
- **Валидация входных данных**: все параметры проверяются
- **Безопасные настройки по умолчанию**: приоритет безопасности
- **Логирование**: все действия записываются в логи
- **Резервные копии**: автоматическое создание бэкапов

### 🚨 Рекомендации

1. **Всегда проверяйте скрипты** перед выполнением
2. **Используйте отдельного пользователя** для приложений
3. **Регулярно проводите аудит безопасности**
4. **Обновляйте систему** автоматически
5. **Настройте мониторинг** и алерты

### 🔍 Проверка целостности

```bash
# Проверка контрольных сумм (если доступны)
sha256sum -c checksums.txt

# Проверка подписи GPG (если доступны)
gpg --verify script.sh.asc script.sh
```

---

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл [LICENSE](LICENSE) для получения дополнительной информации.

---

## 🤝 Вклад в проект

Мы приветствуем вклад в развитие проекта! Пожалуйста, ознакомьтесь с [CONTRIBUTING.md](CONTRIBUTING.md) для получения информации о том, как внести свой вклад.

### 📞 Поддержка

- **Issues**: [GitHub Issues](https://github.com/Muhendalf-ru/vps-script/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Muhendalf-ru/vps-script/discussions)
- **Wiki**: [GitHub Wiki](https://github.com/Muhendalf-ru/vps-script/wiki)

---

## ⭐ Звезды и форки

Если этот проект помог вам, поставьте звезду ⭐ и поделитесь с друзьями!

```bash
# Быстрая ссылка для звезды
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/start.sh | bash
```

---

**Автор**: Pesherkino VPN  
**Версия**: 1.0.0  
**Последнее обновление**: $(date +%Y-%m-%d)
