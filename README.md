# HAProxy ile Türkiye IP'lerini Filtreleme

Bu proje, [IP2Location LITE DB1.LITE](https://lite.ip2location.com/) veritabanını kullanarak HAProxy ile yalnızca Türkiye IP adreslerinden gelen HTTP isteklerine izin vermek için otomatik bir çözüm sunar. Türkiye dışından gelen istekler, özelleştirilmiş bir 403 hata sayfasıyla engellenir. Proje, IP2Location veritabanını düzenli olarak indirip güncelleyen bir betik, CSV verisini HAProxy’nin anlayacağı CIDR formatına dönüştüren bir Python scripti ve bu süreci otomatikleştiren bir cron betiği içerir.

## Özellikler
- **Otomatik Güncelleme**: IP2Location LITE veritabanını aylık olarak indirir ve HAProxy map dosyasına dönüştürür.
- **Türkiye IP Filtresi**: Yalnızca Türkiye’den gelen IP adreslerine izin verir, diğerlerini engeller.
- **Hata Sayfası**: Türkiye dışından gelen istekler için özelleştirilmiş bir 403 hata sayfası gösterir.
- **Günlük Kaydı**: Güncelleme sürecinin takibi için ayrıntılı log dosyası oluşturur.
- **Hata Yönetimi**: İndirme, dönüştürme ve HAProxy yeniden yükleme adımlarında hata kontrolü yapar.

## Gereksinimler
- **HAProxy**: 2.4 veya üstü (test edildi: 2.4.24)
- **Python 3**: `ipaddress` modülü ile
- **Linux Araçları**: `wget`, `unzip`, `cron`
- **IP2Location LITE Download Token**: [IP2Location](https://lite.ip2location.com/) hesabınızdan ücretsiz bir token alın
- **SSL Sertifikası**: HTTPS için geçerli bir sertifika (örneğin, `/etc/haproxy/certs/cluster.crtlist`)
- **Hata Sayfası**: Özelleştirilmiş 403 hata sayfası (örneğin, `/etc/haproxy/errors/403-turkey-only.html`)

## Kurulum Adımları

### 1. HAProxy Yapılandırmasını Ayarlayın
HAProxy yapılandırması, Türkiye IP’lerini kontrol eden bir ACL kullanır ve Türkiye dışından gelen istekleri engeller.

1. Örnek yapılandırma dosyasını (`haproxy.cfg`) `/etc/haproxy/haproxy.cfg` yoluna kopyalayın:
   ```bash
   sudo cp haproxy.cfg /etc/haproxy/haproxy.cfg
   ```
2. SSL sertifikanızı `/etc/haproxy/certs/cluster.crtlist` yoluna yerleştirin.
3. Özelleştirilmiş 403 hata sayfasını oluşturun:
   ```bash
   sudo mkdir -p /etc/haproxy/errors
   echo '<html><body><h1>403 Forbidden</h1><p>Bu siteye yalnızca Türkiye\'den erişilebilir.</p></body></html>' | sudo tee /etc/haproxy/errors/403-turkey-only.html
   ```
4. HAProxy yapılandırmasını test edin:
   ```bash
   sudo haproxy -c -f /etc/haproxy/haproxy.cfg
   ```

### 2. Python Scriptini Kurun
`convert_ip2location.py`, IP2Location CSV dosyasını HAProxy’nin anlayacağı CIDR formatında bir map dosyasına dönüştürür.

1. Scripti `/root/` dizinine kopyalayın:
   ```bash
   cp convert_ip2location.py /root/
   ```
2. Gerekli Python modülünü kurun:
   ```bash
   sudo apt-get install python3 python3-pip
   pip3 install ipaddress
   ```
3. Scripti test edin:
   ```bash
   python3 /root/convert_ip2location.py
   head /etc/haproxy/tr-ip-list.map
   ```
   **Beklenen Çıktı**:
   ```
   2.16.150.0/23
   2.17.0.0/22
   ...
   ```

### 3. Cron Betiğini Kurun
`update-ip2location.sh`, IP2Location veritabanını indirir, açar, dönüştürür ve HAProxy’yi yeniden yükler.

1. Betiği `/etc/cron.weekly/` dizinine kopyalayın:
   ```bash
   cp update-ip2location.sh /etc/cron.weekly/
   chmod +x /etc/cron.weekly/update-ip2location
   ```
2. Gerekli araçları kurun:
   ```bash
   sudo apt-get install wget unzip
   ```
3. Betiği test edin:
   ```bash
   /etc/cron.weekly/update-ip2location
   cat /var/log/update-ip2location.log
   ```
   **Beklenen Çıktı** (log dosyası):
   ```
   Fri Jun 27 13:47:00 +03 2025: Betik başladı
   Fri Jun 27 13:47:05 +03 2025: Betik başarıyla tamamlandı
   ```

### 4. Cron ile Otomatik Güncellemeyi Ayarlayın
Betiği haftalık çalıştırmak için `/etc/cron.weekly/` yeterlidir (sistem varsayılan olarak pazar sabah 06:47’de çalıştırır). Aylık çalıştırmak için `crontab`’a ekleyin:

1. `crontab`’ı düzenleyin:
   ```bash
   crontab -e
   ```
2. Aşağıdaki satırı ekleyin (her ayın 1’inde sabah 02:00):
   ```
   0 2 1 * * /etc/cron.weekly/update-ip2location
   ```
3. Çift çalıştırmayı önlemek için betiği `/etc/cron.weekly/`’den taşıyabilirsiniz:
   ```bash
   mv /etc/cron.weekly/update-ip2location /root/update-ip2location.sh
   ```
   Ardından `crontab`’ı güncelleyin:
   ```
   0 2 1 * * /root/update-ip2location.sh
   ```

### 5. HAProxy’yi Yeniden Başlatın
Yapılandırmayı uygulayın:
```bash
sudo systemctl restart haproxy
sudo systemctl status haproxy
```

## Dosyalar
- **`haproxy.cfg`**: HAProxy yapılandırması. Türkiye IP’lerini kontrol eder ve diğerlerini engeller.
- **`convert_ip2location.py`**: IP2Location CSV dosyasını CIDR formatında `/etc/haproxy/tr-ip-list.map` dosyasına dönüştürür.
- **`update-ip2location.sh`**: Veritabanını indirir, açar, dönüştürür ve HAProxy’yi yeniden yükler.

## Kullanım Senaryoları
- **Web Sitesi Kısıtlaması**: Türkiye dışından gelen istekleri engelleyerek yalnızca yerel kullanıcılara hizmet sunar.
- **Güvenlik**: Kötü niyetli User-Agent’ları (örneğin, `sqlmap`, `curl/7.0`, `wget`) engeller.
- **Otomasyon**: IP veritabanını düzenli olarak güncelleyerek manuel müdahaleyi ortadan kaldırır.

## Hata Giderme
- **Map Dosyası Oluşmadıysa**:
  ```bash
  python3 /root/convert_ip2location.py
  cat /var/log/update-ip2location.log
  ```
- **HAProxy Hataları**:
  ```bash
  sudo haproxy -c -f /etc/haproxy/haproxy.cfg
  ```
- **İndirme Sorunları**: IP2Location token’ınızı kontrol edin veya kota aşımı için yeni bir token alın.

## Log Yönetimi
Günlük dosyası (`/var/log/update-ip2location.log`) büyümesini önlemek için `logrotate` kullanın:
```bash
sudo nano /etc/logrotate.d/update-ip2location
```
İçerik:
```
/var/log/update-ip2location.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
```

## Lisans
Bu proje [MIT lisansı](LICENSE) altında dağıtılmaktadır. Ancak, IP2Location LITE veritabanı [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) lisansı altındadır. Veritabanını kullanırken IP2Location’a atıfta bulunmanız gerekir.

## Notlar
- **IP2Location Kısıtlamaları**: Veritabanı aylık indirilebilir. Kota aşımı durumunda [IP2Location](https://lite.ip2location.com/)’dan yeni token alın.
- **IPv6 Desteği**: IPv6 için `DB1LITEIPV6` dosyasını kullanabilirsiniz. `convert_ip2location.py` dosyasını buna göre güncelleyin.
- **Performans**: Büyük map dosyaları için HAProxy’nin bellek kullanımını izleyin (`stick-table size 1m` genellikle yeterlidir).
