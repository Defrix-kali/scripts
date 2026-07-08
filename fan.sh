#!/bin/bash

# Проверка на права root
if [ "$EUID" -ne 0 ]; then 
  echo "[-] Ошибка: Запусти скрипт через sudo (sudo ./fan.sh)"
  exit 1
fi

echo "--- [1] Смена сетевой личности (MAC) ---"
# Автоматически находим все физические интерфейсы (исключая loopback 'lo')
interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo")

for iface in $interfaces; do
    echo "[+] Обработка $iface..."
    ip link set "$iface" down 2>/dev/null
    
    # Имитируем случайного реального производителя (-A)
    if macchanger -A "$iface" 2>/dev/null; then
        ip link set "$iface" up 2>/dev/null
    else
        echo "[-] Не удалось изменить MAC для $iface (возможно, виртуальный интерфейс)"
        ip link set "$iface" up 2>/dev/null
    fi
done

echo "--- [2] Маскировка Hostname ---"
names=("DESKTOP-OFFICE" "WORK-PC" "USER-LAPTOP" "STATION-MAIN")
RAND_NAME="${names[$RANDOM % ${#names[@]}]}-$RANDOM"
hostnamectl set-hostname "$RAND_NAME"
echo "[+] Новое имя в сети: $RAND_NAME"

echo "--- [3] Блокировка утечек (IPv6) ---"
sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null
sysctl -w net.ipv6.conf.default.disable_ipv6=1 > /dev/null
echo "[+] IPv6 полностью отключен."

echo "--- [4] Анонимный канал (Tor) ---"
if systemctl is-active --quiet tor; then
    echo "[+] Tor уже запущен и работает."
else
    echo "[*] Запускаю сервис Tor..."
    systemctl start tor
    sleep 2
fi

echo "--- [5] Заметание следов (Безопасная очистка логов) ---"
# удаления логов
find /var/log -type f -exec truncate -s 0 {} \; 2>/dev/null
echo "[+] Системные логи очищены."

echo "--------------------------------------------------"
echo " СИСТЕМА ГОТОВА "
echo "--------------------------------------------------"
echo "Для выхода в сеть :     proxychains4 firefox-esr"
echo "Для анонимного терминала:     proxychains4 bash"
echo "--------------------------------------------------"
echo "[!] ВНИМАНИЕ: Чтобы очистить историю текущего терминала,"
echo "    после выхода из скрипта выполни команду: history -c && history -w"
echo "--------------------------------------------------"
