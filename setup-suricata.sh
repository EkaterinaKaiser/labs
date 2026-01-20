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

# Настройка iptables для IPS
echo "Настройка iptables для NFQ"
sudo iptables -I FORWARD -j NFQUEUE --queue-num 0 || true

# Проверка конфига Suricata
echo "Проверка конфига Suricata"
sudo mkdir -p /tmp/suricata-test
sudo suricata -T -c /etc/suricata/suricata.yaml -l /tmp/suricata-test

# Запуск Suricata
echo "Запуск Suricata в режиме IPS (NFQ)"
if sudo systemctl restart suricata 2>/dev/null; then
  sudo systemctl enable suricata || true
  echo "Suricata запущена как systemd-сервис"
  sleep 2
  if sudo systemctl is-active --quiet suricata; then
    echo "Suricata успешно запущена"
  else
    echo "Systemd сервис не активен, запускаю напрямую"
    sudo systemctl stop suricata 2>/dev/null || true
    sudo pkill -x suricata || true
    sleep 1
    sudo suricata -c /etc/suricata/suricata.yaml -q 0 -D
  fi
else
  echo "Не удалось запустить Suricata через systemd, запускаю напрямую (daemon)"
  sudo pkill -x suricata || true
  sleep 1
  sudo suricata -c /etc/suricata/suricata.yaml -q 0 -D
fi

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