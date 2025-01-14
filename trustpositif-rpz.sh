#!/bin/bash

# ============================================
# Script: trustpositif-rpz.sh
# Fungsi: 
#   - Mengunduh daftar domain dari URL "https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/alsyundawy-blocklist/alsyundawy_blacklist.txt"
#   - Mengonversi daftar domain tersebut menjadi format RPZ untuk digunakan dengan BIND DNS
#   - Menghasilkan file zona DNS dengan konfigurasi SOA dan NS, serta menambahkan CNAME untuk setiap domain
#   - Menggunakan curl untuk mengunduh file dengan melewati verifikasi SSL
#   - Menghasilkan serial SOA secara acak dan menulisnya ke dalam file output
#   - Melakukan restart layanan named dan reload konfigurasi DNS setelah file selesai dibuat
#
# Pembuat: Harry DS Alsyundawy
# Tanggal Pembuatan: 14 Januari 2025
# ============================================

# Warna ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Header dengan warna
echo -e "${BLUE}# ============================================"
echo -e "# Script: ${CYAN}trustpositif-rpz.sh${RESET}"
echo -e "# Fungsi:"
echo -e "#   - ${GREEN}Mengunduh daftar domain dari URL \"https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/alsyundawy-blocklist/alsyundawy_blacklist.txt\"${RESET}"
echo -e "#   - ${GREEN}Mengonversi daftar domain tersebut menjadi format RPZ untuk digunakan dengan BIND DNS${RESET}"
echo -e "#   - ${GREEN}Menghasilkan file zona DNS dengan konfigurasi SOA dan NS, serta menambahkan CNAME untuk setiap domain${RESET}"
echo -e "#   - ${GREEN}Menggunakan curl untuk mengunduh file dengan melewati verifikasi SSL${RESET}"
echo -e "#   - ${GREEN}Menghasilkan serial SOA secara acak dan menulisnya ke dalam file output${RESET}"
echo -e "#   - ${GREEN}Melakukan restart layanan named dan reload konfigurasi DNS setelah file selesai dibuat${RESET}"
echo -e "#"
echo -e "# Pembuat: ${MAGENTA}HARRY DS ALSYUNDAWY${RESET}"
echo -e "# Tanggal Pembuatan: ${YELLOW}14 Januari 2025${RESET}"
echo -e "# ============================================${RESET}"

# Nama file input
INPUT_FILE_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/alsyundawy-blocklist/alsyundawy_blacklist.txt"
OUTPUT_FILE="/etc/bind/zones/trustpositif.zones"
TEMP_INPUT_FILE="/tmp/domains_isp.txt"

# Fungsi untuk menghasilkan serial SOA random
generate_serial_soa() {
    date +%Y%m%d$(( RANDOM % 99 + 1 ))
}

# Mengunduh file input dengan curl dan bypass SSL
echo -e "${CYAN}Mengunduh file dari URL:${RESET} ${YELLOW}$INPUT_FILE_URL${RESET}"
curl -s --insecure -o "$TEMP_INPUT_FILE" "$INPUT_FILE_URL"

# Cek jika file berhasil diunduh
if [ ! -f "$TEMP_INPUT_FILE" ]; then
    echo -e "${RED}Gagal mengunduh file input dari ${INPUT_FILE_URL}${RESET}"
    exit 1
fi

# Generate serial SOA random
SERIAL_SOA=$(generate_serial_soa)
CURRENT_TIME=$(date)

# Menulis header ke file output
echo -e "${CYAN}Menulis konfigurasi zona ke file output:${RESET} ${YELLOW}$OUTPUT_FILE${RESET}"
{
    echo "; File ini dihasilkan pada: $CURRENT_TIME"
    echo "; Authors: Harry DS Alsyundawy"
    echo ""
    echo "\$TTL 300"
    echo "@ IN SOA localhost. root.localhost. ("
    echo "    $SERIAL_SOA ; Serial"
    echo "    10800      ; Refresh"
    echo "    120        ; Retry"
    echo "    604800     ; Expire"
    echo "    3600       ; Minimum TTL"
    echo ")"
    echo "@ IN NS lamanlabuh.resolver.id."
} > "$OUTPUT_FILE"

# Menggunakan awk untuk membaca file input dan menulis ke file output
awk '
{
    print $0 " CNAME lamanlabuh.resolver.id."
    print "*." $0 " CNAME lamanlabuh.resolver.id."
}' "$TEMP_INPUT_FILE" >> "$OUTPUT_FILE"

# Menghapus file sementara
rm -f "$TEMP_INPUT_FILE"
echo -e "${GREEN}Konversi selesai. File output disimpan sebagai:${RESET} ${YELLOW}$OUTPUT_FILE${RESET}"

# Restart named dan reload konfigurasi
echo -e "${CYAN}Restarting named service and reloading DNS configuration...${RESET}"
systemctl restart named
rndc reload

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Layanan named berhasil direstart dan konfigurasi DNS berhasil dimuat ulang.${RESET}"
else
    echo -e "${RED}Gagal merestart layanan named atau memuat ulang konfigurasi DNS.${RESET}"
    exit 1
fi

echo -e "${MAGENTA}Script selesai dijalankan.${RESET}"
