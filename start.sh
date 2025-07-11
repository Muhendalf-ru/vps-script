#!/bin/bash

set -e

read -p "Введите имя нового пользователя: " NEW_USER
read -p "Введите порт для SSH (например, 2222): " SSH_PORT

echo "=== Обновление системы ==="
apt update && apt upgrade -y

echo "=== Создание нового пользователя без пароля: $NEW_USER ==="
adduser --disabled-password --gecos "" "$NEW_USER"
usermod -aG sudo "$NEW_USER"

echo "=== Настройка, чтобы при первом входе пользователь сменил пароль ==="
chage -d 0 "$NEW_USER"

echo "=== Настройка SSH ==="
sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config || true
sed -i "s/Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config || true
sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/" /etc/ssh/sshd_config

systemctl restart sshd

echo "=== Установка Docker ==="
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker "$NEW_USER"

echo "=== Установка Docker Compose v2 ==="
DOCKER_COMPOSE_VERSION=$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Проверяем установку
docker-compose version || echo "Docker Compose установка не удалась"

echo "=== Установка и запуск Fail2Ban ==="
apt install -y fail2ban
systemctl enable --now fail2ban

echo "=== Настройка UFW ==="
ufw default deny incoming
ufw default allow outgoing
ufw allow "$SSH_PORT"
ufw allow 2376
ufw allow 2377
ufw allow 7946
ufw allow 4789/udp
ufw --force enable

echo "=== Готово! ==="
echo "Пользователь $NEW_USER создан без пароля."
echo "При первом входе пароль нужно будет задать заново."
echo "Подключайся по SSH: ssh -p $SSH_PORT $NEW_USER@$(hostname -I | awk '{print $1}')"
echo "Проверь docker: sudo -i -u $NEW_USER docker run hello-world"
echo "Проверь docker-compose: docker-compose version"
