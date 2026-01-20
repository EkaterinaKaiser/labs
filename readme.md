## Лаборатория Suricata IPS (victim / attacker)

### Локальный запуск

- **Запуск контейнеров**
  ```bash
  docker compose up -d
  ```

- **Установка и запуск Suricata в режиме IPS на хосте**
  ```bash
  chmod +x setup-suricata.sh
  sudo ./setup-suricata.sh
  ```

### Автоматическая установка в облаке (GitHub Actions)

Workflow `.github/workflows/main.yml` автоматически устанавливает лабораторию на удалённый облачный хост по SSH при пуше в ветку `main`.

- **Требования к облачному хосту**
  - Обычный Linux-сервер (Ubuntu/Debian или RHEL/CentOS).
  - Пользователь, под которым будет выполняться деплой, имеет доступ по SSH и права `sudo` без пароля (или настроен соответствующим образом).

- **Необходимые GitHub Secrets**
  Создайте в настройках репозитория (`Settings → Secrets and variables → Actions`) следующие секреты:

  - **`CLOUD_HOST`**: IP или DNS-имя облачного сервера (например, `203.0.113.10`).
  - **`CLOUD_USER`**: SSH‑пользователь для подключения к серверу (например, `ubuntu`).
  - **`CLOUD_SSH_KEY`**: приватный SSH‑ключ в формате PEM, соответствующий открытому ключу, добавленному в `~/.ssh/authorized_keys` на сервере.

- **Что делает деплой‑job `deploy-cloud`**
  - Подключается к облачному хосту по SSH с использованием `CLOUD_SSH_KEY`.
  - Устанавливает при необходимости `git` и Docker (`docker` + `docker compose`).
  - Клонирует (при первом запуске) или обновляет репозиторий в каталоге `~/labs`.
  - Запускает на сервере скрипт `setup-suricata.sh` для установки и настройки Suricata в режиме IPS.
  - Запускает лабораторные контейнеры командой `docker compose up -d`.
  - Выполняет базовую проверку:
    - `ping victim` из контейнера `attacker` (ICMP должен блокироваться Suricata — ответов не будет).
    - `curl http://victim` из контейнера `attacker` (HTTP‑ответ должен приходить).
    - Выводит в лог GitHub Actions последние события из `/var/log/suricata/eve.json` (ожидаются события `drop` для ICMP и записи про HTTP‑запросы).