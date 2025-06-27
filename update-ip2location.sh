#!/bin/bash
# /etc/cron.weekly/update-ip2location
set -e  # Hata durumunda betiği durdur
LOG_FILE="/var/log/update-ip2location.log"

echo "$(date): Betik başladı" >> "$LOG_FILE"

# ZIP dosyasını indir
wget -O /etc/haproxy/IP2LOCATION-LITE-DB1.CSV.zip "https://www.ip2location.com/download?token=ip2location dan almış olduğunuz tokeni buraya giriniz." 2>> "$LOG_FILE"
if [ $? -ne 0 ]; then
    echo "$(date): ZIP dosyası indirilemedi" >> "$LOG_FILE"
    exit 1
fi

# ZIP dosyasını aç
unzip -o /etc/haproxy/IP2LOCATION-LITE-DB1.CSV.zip -d /etc/haproxy/ 2>> "$LOG_FILE"
if [ $? -ne 0 ]; then
    echo "$(date): ZIP dosyası açılamadı" >> "$LOG_FILE"
    exit 1
fi

# Python scriptini çalıştır
python3 /root/convert_ip2location.py 2>> "$LOG_FILE"
if [ $? -ne 0 ]; then
    echo "$(date): Python scripti başarısız oldu" >> "$LOG_FILE"
    exit 1
fi

# Map dosyasını kontrol et
if [ ! -s /etc/haproxy/tr-ip-list.map ]; then
    echo "$(date): Map dosyası oluşturulmadı veya boş" >> "$LOG_FILE"
    exit 1
fi

# Dosya izinlerini güncelle
chmod 644 /etc/haproxy/tr-ip-list.map >> "$LOG_FILE" 2>&1
chown haproxy:haproxy /etc/haproxy/tr-ip-list.map >> "$LOG_FILE" 2>&1

# HAProxy’yi yeniden yükle
systemctl reload haproxy >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    echo "$(date): HAProxy yeniden yüklenemedi" >> "$LOG_FILE"
    exit 1
fi

echo "$(date): Betik başarıyla tamamlandı" >> "$LOG_FILE"
