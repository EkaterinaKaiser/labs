#!/bin/bash
set -e

echo "Установка Suricata"
sudo apt update
sudo apt install -y suricata

# Копируем конфиг и правила
sudo cp suricata/suricata.yaml /etc/suricata/suricata.yaml
sudo mkdir -p /etc/suricata/rules
sudo cp suricata/rules/local.rules /etc/suricata/rules/

# Настройка iptables для IPS
echo "Настройка iptables для NFQ"
sudo iptables -I FORWARD -j NFQUEUE --queue-num 0

# Запуск Suricata
sudo systemctl enable suricata
sudo systemctl restart suricata

echo "Suricata запущен в режиме IPS (NFQ)"
echo "Правило iptables применено: FORWARD → NFQUEUE"
echo "Логи: sudo tail -f /var/log/suricata/fast.log"