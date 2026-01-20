#!/bin/bash
set -e

echo "Установка Suricata"
sudo apt update
sudo apt install -y suricata

# Копируем конфиг и правила
sudo cp suricata/suricata.yaml /etc/suricata/suricata.yaml
sudo mkdir -p /etc/suricata/rules
sudo cp suricata/rules/local.rules /etc/suricata/rules/

# Создаём директорию для логов
sudo mkdir -p /var/log/suricata

# Загрузка модулей ядра для NFQ
echo "Загрузка модулей ядра для NFQ"
sudo modprobe nfnetlink || true
sudo modprobe nfnetlink_queue || true

# Проверка что модули загружены
echo "Проверка загруженных модулей NFQ:"
if sudo lsmod | grep -q nfnetlink_queue; then
  echo "✓ Модуль nfnetlink_queue загружен"
else
  echo "⚠ Модуль nfnetlink_queue не загружен (возможны проблемы с NFQ)"
fi

# Убиваем все процессы Suricata перед запуском
echo "Остановка существующих процессов Suricata"
sudo pkill -x suricata || true
sudo systemctl stop suricata 2>/dev/null || true
sleep 1

# Настройка iptables для IPS
echo "Настройка iptables для NFQ"
sudo iptables -I FORWARD -j NFQUEUE --queue-num 0 || true

# Проверка конфига Suricata
echo "Проверка конфига Suricata"
sudo mkdir -p /tmp/suricata-test
sudo suricata -T -c /etc/suricata/suricata.yaml -l /tmp/suricata-test

# Запуск Suricata
echo "Запуск Suricata в режиме IPS (NFQ)"
# Пробуем запустить напрямую в daemon режиме (systemd часто не работает с NFQ)
echo "Запуск Suricata в daemon режиме с NFQ..."
sudo suricata -c /etc/suricata/suricata.yaml -q 0 -D
sleep 3

# Проверка что Suricata запущена
sleep 2
if pgrep -x suricata > /dev/null; then
  echo "✓ Suricata запущена (PID: $(pgrep -x suricata))"
else
  echo "⚠ Suricata не запущена, проверьте логи"
fi

echo ""
echo "Suricata IPS настроена."
echo "Правило iptables применено: FORWARD → NFQUEUE (если iptables доступен)"
echo "Проверка правила iptables:"
sudo iptables -L FORWARD -n -v | grep NFQUEUE || echo "Правило NFQUEUE не найдено в FORWARD"
echo ""
echo "Логи: sudo tail -f /var/log/suricata/fast.log"