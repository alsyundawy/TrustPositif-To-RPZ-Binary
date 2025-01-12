#!/bin/bash

# Script ini digunakan untuk menginstal dan mengonfigurasi BIND9 DNS server
# yang digunakan untuk mengelola DNS dengan konfigurasi RPZ (Response Policy Zone).
# Script ini mengunduh dan mengonfigurasi file konfigurasi BIND9 serta 
# mengunduh dan mengonfigurasi file RPZ binary untuk digunakan dalam sistem.
# Dibuat oleh: Alsyundawy
# Tanggal: 13 Januari 2025

# Memperbarui repositori dan menginstal paket yang diperlukan
sudo apt update
sudo apt install -y bind9 dnsutils

# Mengaktifkan dan memulai layanan BIND9
sudo systemctl enable --now named

# Mengunduh dan mengonfigurasi file konfigurasi BIND
sudo wget -cq https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind/named.conf.local -O /etc/bind/named.conf.local
sudo wget -cq https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind/named.conf.options -O /etc/bind/named.conf.options
sudo wget -cq https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind/zones/safesearch.zones -O /etc/bind/zones/safesearch.zones
sudo wget -cq https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind/zones/whitelist.zones -O /etc/bind/zones/whitelist.zones

# Periksa konfigurasi dan Menjalankan ulang layanan BIND9
sudo named-checkconfig
sudo rndc reload
sudo systemctl restart named

# Mengunduh binary RPZ dan membuatnya dapat dieksekusi
sudo wget -cq https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/raw/refs/heads/main/rpz -O /usr/local/bin/rpz
sudo chmod +x /usr/local/bin/rpz

(crontab -l 2>/dev/null; echo "* */12 * * * /usr/local/bin/rpz > /dev/null 2>&1") | sudo crontab -

# Menjalankan RPZ binary
sudo rpz
