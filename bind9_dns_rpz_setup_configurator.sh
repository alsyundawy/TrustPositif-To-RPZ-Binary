#!/bin/bash

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

# Menampilkan informasi dengan warna
echo -e "${CYAN}# Script ini digunakan untuk menginstal dan mengonfigurasi BIND9 DNS server${NC}"
echo -e "${CYAN}# yang digunakan untuk mengelola DNS dengan konfigurasi RPZ (Response Policy Zone).${NC}"
echo -e "${CYAN}# Script ini mengunduh dan mengonfigurasi file konfigurasi BIND9 serta ${NC}"
echo -e "${CYAN}# mengunduh dan mengonfigurasi file RPZ binary untuk digunakan dalam sistem.${NC}"
echo -e "${YELLOW}# Dibuat oleh: Alsyundawy${NC}"
echo -e "${YELLOW}# Tanggal: 13 Januari 2025${NC}"

echo -e "${BLUE}Memperbarui repositori dan menginstal paket yang diperlukan...${NC}"
sudo apt update
sudo apt install -y bind9 dnsutils

echo -e "${BLUE}Mengaktifkan dan memulai layanan BIND9...${NC}"
sudo systemctl enable --now named

echo -e "${YELLOW}Mengunduh dan mengonfigurasi file konfigurasi BIND...${NC}"
sudo wget -cq https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind/named.conf.local -O /etc/bind/named.conf.local
sudo wget -cq https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind/named.conf.options -O /etc/bind/named.conf.options
sudo wget -cq https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind/zones/safesearch.zones -O /etc/bind/zones/safesearch.zones
sudo wget -cq https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind/zones/whitelist.zones -O /etc/bind/zones/whitelist.zones

echo -e "${GREEN}Periksa konfigurasi dan Menjalankan ulang layanan BIND9...${NC}"
sudo named-checkconfig
sudo rndc reload
sudo systemctl restart named

echo -e "${YELLOW}Mengunduh binary RPZ dan membuatnya dapat dieksekusi...${NC}"
sudo wget -cq https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/raw/refs/heads/main/rpz -O /usr/local/bin/rpz
sudo chmod +x /usr/local/bin/rpz

echo -e "${GREEN}Menambahkan cron job untuk menjalankan RPZ setiap 12 jam...${NC}"
(crontab -l 2>/dev/null; echo "* */12 * * * /usr/local/bin/rpz > /dev/null 2>&1") | sudo crontab -

echo -e "${RED}Menjalankan RPZ binary...${NC}"
sudo rpz

