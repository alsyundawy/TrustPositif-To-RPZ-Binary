#!/usr/bin/env bash

# Script ini digunakan untuk menginstal dan mengonfigurasi BIND9 DNS server
# yang digunakan untuk mengelola DNS dengan konfigurasi RPZ (Response Policy Zone).
# Script ini mengunduh dan mengonfigurasi file konfigurasi BIND9 serta 
# mengunduh dan mengonfigurasi file RPZ binary untuk digunakan dalam sistem.
# Dibuat oleh: Alsyundawy
# Tanggal: 13 Januari 2025

# Warna untuk teks
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fungsi untuk menampilkan pesan error dan keluar
error_exit() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

# Fungsi untuk mengecek status perintah terakhir
check_status() {
    if [ $? -ne 0 ]; then
        error_exit "$1"
    fi
}

# Menampilkan informasi dengan warna
echo -e "${CYAN}# Script ini digunakan untuk menginstal dan mengonfigurasi BIND9 DNS server${NC}"
echo -e "${CYAN}# yang digunakan untuk mengelola DNS dengan konfigurasi RPZ (Response Policy Zone).${NC}"
echo -e "${CYAN}# Script ini mengunduh dan mengonfigurasi file konfigurasi BIND9 serta ${NC}"
echo -e "${CYAN}# mengunduh dan mengonfigurasi file RPZ binary untuk digunakan dalam sistem.${NC}"
echo -e "${YELLOW}# Dibuat oleh: Alsyundawy${NC}"
echo -e "${YELLOW}# Tanggal: 24 Januari 2025${NC}"

# Memperbarui repositori dan menginstal paket yang diperlukan
echo -e "${BLUE}Memperbarui repositori dan menginstal paket yang diperlukan...${NC}"
sudo apt-get update;sudo apt-get upgrade -y;sudo apt-get dist-upgrade -y;sudo apt-get full-upgrade -y; sudo apt-get --purge autoremove -y

check_status "Gagal memperbarui repositori."
sudo apt install -y bind9 dnsutils
check_status "Gagal menginstal paket yang diperlukan."

# Mengaktifkan dan memulai layanan BIND9
echo -e "${BLUE}Mengaktifkan dan memulai layanan BIND9...${NC}"
sudo systemctl enable --now named
check_status "Gagal mengaktifkan atau memulai layanan BIND9."

# Mengunduh dan mengonfigurasi file konfigurasi BIND
echo -e "${YELLOW}Mengunduh dan mengonfigurasi file konfigurasi BIND...${NC}"
declare -A config_files=(
    ["named.conf.local"]="/etc/bind/named.conf.local"
    ["named.conf.options"]="/etc/bind/named.conf.options"
    ["safesearch.zones"]="/etc/bind/zones/safesearch.zones"
    ["whitelist.zones"]="/etc/bind/zones/whitelist.zones"
)

for file in "${!config_files[@]}"; do
    url="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind/${file}"
    destination="${config_files[$file]}"
    sudo wget -cq "$url" -O "$destination"
    check_status "Gagal mengunduh atau menyimpan file ${file}."
done

# Periksa konfigurasi dan menjalankan ulang layanan BIND9
echo -e "${GREEN}Memeriksa konfigurasi dan menjalankan ulang layanan BIND9...${NC}"
sudo named-checkconf
check_status "Konfigurasi BIND tidak valid."
sudo rndc reload
check_status "Gagal memuat ulang konfigurasi BIND."
sudo systemctl restart named
check_status "Gagal menjalankan ulang layanan BIND9."

# Mengunduh binary RPZ dan membuatnya dapat dieksekusi
echo -e "${YELLOW}Mengunduh binary RPZ dan membuatnya dapat dieksekusi...${NC}"
rpz_url="https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/raw/refs/heads/main/rpz"
rpz_destination="/usr/local/bin/rpz"
sudo wget -cq "$rpz_url" -O "$rpz_destination"
check_status "Gagal mengunduh atau menyimpan binary RPZ."
sudo chmod +x "$rpz_destination"
check_status "Gagal membuat binary RPZ dapat dieksekusi."

# Menambahkan cron job untuk menjalankan RPZ setiap 12 jam
echo -e "${GREEN}Menambahkan cron job untuk menjalankan RPZ setiap 12 jam...${NC}"
(crontab -l 2>/dev/null; echo "0 */12 * * * /usr/local/bin/rpz > /dev/null 2>&1") | sudo crontab -
check_status "Gagal menambahkan cron job."

# Menjalankan RPZ binary
echo -e "${RED}Menjalankan RPZ binary...${NC}"
sudo "$rpz_destination"
check_status "Gagal menjalankan binary RPZ."

echo -e "${GREEN}Script selesai dijalankan.${NC}"
