# 🔧 Скрипт исправления MongoDB репозиториев

## `fix_mongodb_repo.sh` - Исправление проблем с MongoDB репозиториями

Скрипт для очистки проблемных MongoDB репозиториев и исправления ошибок apt, которые могут возникать при установке MongoDB на Ubuntu 24.04+.

---

## 🎯 Назначение

Этот скрипт решает проблему с MongoDB репозиториями, которые были добавлены для несовместимых версий Ubuntu:

- **Проблема**: MongoDB 6.0 не поддерживается в Ubuntu 24.04 (noble)
- **Ошибка**: `404 Not Found` при обновлении apt
- **Решение**: Очистка старых репозиториев и исправление системы

---

## 🚀 Быстрый запуск

```bash
# Скачивание и запуск
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/fix_mongodb_repo.sh -o fix_mongodb_repo.sh && chmod +x fix_mongodb_repo.sh && sudo ./fix_mongodb_repo.sh -a
```

---

## 📋 Примеры использования

### Полная очистка и исправление (рекомендуется)

```bash
sudo ./fix_mongodb_repo.sh -a
```

### Только очистка MongoDB репозиториев

```bash
sudo ./fix_mongodb_repo.sh -c
```

### Только исправление проблем с apt

```bash
sudo ./fix_mongodb_repo.sh -f
```

### Проверка статуса без изменений

```bash
sudo ./fix_mongodb_repo.sh
```

---

## 🔧 Доступные опции

| Опция         | Описание                               |
| ------------- | -------------------------------------- |
| `-c, --clean` | Очистить все MongoDB репозитории       |
| `-f, --fix`   | Исправить проблемы с apt               |
| `-a, --all`   | Выполнить полную очистку и исправление |
| `--verbose`   | Подробный вывод                        |
| `-h, --help`  | Показать справку                       |

---

## 🔍 Что делает скрипт

### 1. Очистка MongoDB репозиториев (`-c`)

Удаляет все файлы MongoDB репозиториев:

```bash
# Удаляемые файлы:
/etc/apt/sources.list.d/mongodb-org-*.list
/usr/share/keyrings/mongodb-server-*.gpg
```

### 2. Исправление apt (`-f`)

Выполняет стандартные операции исправления:

```bash
apt clean          # Очистка кэша
apt autoclean      # Удаление устаревших пакетов
apt update         # Обновление списков
apt --fix-broken   # Исправление зависимостей
```

### 3. Проверка статуса

Показывает текущее состояние системы:

- ✅/❌ Наличие MongoDB репозиториев
- ✅/❌ Наличие MongoDB GPG ключей
- ✅/❌ Работоспособность apt update

---

## 📊 Пример вывода

### Успешная очистка

```bash
[INFO] 🔧 MongoDB Repository Fix Script
[INFO] Исправление проблем с MongoDB репозиториями
=============================================================================

[INFO] Очистка MongoDB репозиториев...
[INFO] Удаление файла: /etc/apt/sources.list.d/mongodb-org-6.0.list
[INFO] Удаление ключа: /usr/share/keyrings/mongodb-server-6.0.gpg
[SUCCESS] Удалено 2 файлов MongoDB
  - /etc/apt/sources.list.d/mongodb-org-6.0.list
  - /usr/share/keyrings/mongodb-server-6.0.gpg

[INFO] Исправление проблем с apt...
[INFO] Очистка кэша apt...
[INFO] Обновление списков пакетов...
[INFO] Исправление сломанных зависимостей...
[SUCCESS] Проблемы с apt исправлены

[INFO] Проверка статуса системы...

📋 Статус репозиториев:
  ✅ MongoDB репозитории не найдены
  ✅ MongoDB GPG ключи не найдены

📋 Тест apt update:
  ✅ apt update работает корректно

=============================================================================
[SUCCESS] Операция завершена успешно!
=============================================================================

💡 Рекомендации:
  • Для установки MongoDB используйте обновленный скрипт setup_mongodb.sh
  • Скрипт автоматически выберет совместимую версию для вашей Ubuntu
  • Ubuntu 24.04+ поддерживает MongoDB 7.0+
```

### Проверка без изменений

```bash
[INFO] Проверка статуса системы...

📋 Статус репозиториев:
  ❌ /etc/apt/sources.list.d/mongodb-org-6.0.list
  ❌ /usr/share/keyrings/mongodb-server-6.0.gpg

📋 Тест apt update:
  ❌ apt update содержит ошибки
  💡 Запустите: ./fix_mongodb_repo.sh -f
```

---

## 🚨 Когда использовать

### Ситуации, требующие исправления:

1. **Ошибка 404 при apt update**:

   ```
   Err: https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/6.0 Release
     404 Not Found
   ```

2. **Проблемы с MongoDB репозиторием**:

   ```
   E: The repository 'https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/6.0 Release' does not have a Release file.
   ```

3. **Неудачная установка MongoDB**:
   ```
   [WARNING] Отсутствуют зависимости: nmap chkrootkit rkhunter
   [INFO] Установка недостающих пакетов...
   Err: https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/6.0 Release
   ```

### Профилактическое использование:

- После неудачной установки MongoDB
- При переходе на новую версию Ubuntu
- Перед установкой MongoDB через setup_mongodb.sh

---

## 🔄 Последовательность действий

### 1. Исправление проблемы

```bash
# Скачать и запустить скрипт исправления
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/fix_mongodb_repo.sh -o fix_mongodb_repo.sh
chmod +x fix_mongodb_repo.sh
sudo ./fix_mongodb_repo.sh -a
```

### 2. Установка MongoDB

```bash
# Установка MongoDB с автоматическим определением версии
curl -fsSL https://raw.githubusercontent.com/Muhendalf-ru/vps-script/main/setup_mongodb.sh -o setup_mongodb.sh
chmod +x setup_mongodb.sh
sudo ./setup_mongodb.sh
```

### 3. Проверка результата

```bash
# Проверка статуса MongoDB
sudo systemctl status mongod

# Проверка подключения
mongosh --eval "db.runCommand('ping')"
```

---

## 🛡️ Безопасность

### Принципы безопасности:

- **Только удаление**: скрипт не устанавливает новые пакеты
- **Проверка прав**: требует root права для системных изменений
- **Безопасное удаление**: использует `rm -f` для предотвращения ошибок
- **Логирование**: все действия записываются в логи

### Проверка перед запуском:

```bash
# Просмотр файлов, которые будут удалены
ls -la /etc/apt/sources.list.d/mongodb-org-*.list 2>/dev/null || echo "Файлы не найдены"
ls -la /usr/share/keyrings/mongodb-server-*.gpg 2>/dev/null || echo "Ключи не найдены"
```

---

## 📝 Логирование

Скрипт создает подробные логи всех операций:

- **Информационные сообщения**: синим цветом
- **Предупреждения**: желтым цветом
- **Ошибки**: красным цветом
- **Успешные операции**: зеленым цветом

### Пример лога:

```bash
[INFO] Очистка MongoDB репозиториев...
[INFO] Удаление файла: /etc/apt/sources.list.d/mongodb-org-6.0.list
[SUCCESS] Удалено 1 файлов MongoDB
[INFO] Исправление проблем с apt...
[SUCCESS] Проблемы с apt исправлены
```

---

## 🔗 Связанные скрипты

- **[setup_mongodb.sh](README_mongodb.md)** - Установка MongoDB с автоопределением версии
- **[security_audit.sh](README_security_audit.md)** - Аудит безопасности системы
- **[start.sh](README_start.md)** - Основная настройка сервера

---

## 📞 Поддержка

Если у вас возникли проблемы:

1. **Проверьте логи**: все действия записываются в консоль
2. **Используйте --verbose**: для подробного вывода
3. **Проверьте права**: скрипт требует sudo
4. **Создайте issue**: на GitHub с подробным описанием проблемы

---

## 📄 Лицензия

Этот скрипт распространяется под лицензией MIT. См. файл [LICENSE](../LICENSE) для получения дополнительной информации.
