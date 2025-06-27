import csv
import ipaddress
import sys

input_file = "/etc/haproxy/IP2LOCATION-LITE-DB1.CSV"
output_file = "/etc/haproxy/tr-ip-list.map"

def int_to_ip(ip_int):
    try:
        return str(ipaddress.IPv4Address(int(ip_int)))
    except ValueError as e:
        print(f"Hata: Geçersiz IP sayısı - {ip_int}: {e}")
        sys.exit(1)

print(f"[{sys.argv[0]}] Başladı: CSV dosyası ({input_file}) işleniyor...")

try:
    with open(input_file, "r") as csv_file, open(output_file, "w") as map_file:
        reader = csv.reader(csv_file)
        tr_count = 0
        for row in reader:
            if len(row) < 4:
                print(f"Uyarı: Geçersiz CSV satırı: {row}")
                continue
            ip_from, ip_to, country_code, country_name = row
            if country_code == "TR":
                try:
                    start_ip = int_to_ip(ip_from)
                    end_ip = int_to_ip(ip_to)
                    networks = ipaddress.summarize_address_range(ipaddress.IPv4Address(start_ip), ipaddress.IPv4Address(end_ip))
                    for net in networks:
                        map_file.write(f"{net}\n")
                        tr_count += 1
                except ValueError as e:
                    print(f"Hata: IP aralığı dönüştürülemedi ({ip_from}-{ip_to}): {e}")
        print(f"[{sys.argv[0]}] Başarıyla tamamlandı: {tr_count} Türkiye IP aralığı {output_file} dosyasına yazıldı.")
except FileNotFoundError as e:
    print(f"Hata: {input_file} dosyası bulunamadı: {e}")
    sys.exit(1)
except Exception as e:
    print(f"Hata: Beklenmeyen hata oluştu: {e}")
    sys.exit(1)
