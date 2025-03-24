# TrustPositif To RPZ Binary


**TrustPositif To RPZ Binary** adalah file biner yang mengonversi daftar domain TrustPositif dari Kominfo menjadi format DNS RPZ. Mendukung fitur WhiteList dan Google SafeSearch (terbaru!). 
Aplikasi ini dirancang khusus untuk digunakan pada DNS BIND9 di distribusi Linux Debian atau Ubuntu. Saat ini, belum diuji pada Unbound atau distribusi Linux lainnya. Spesifikasi minimum: CPU 2 Core, RAM 8GB. Disarankan menggunakan CPU 4 Core dan RAM 16GB atau lebih untuk performa yang lebih optimal.


[![Latest Version](https://img.shields.io/github/v/release/alsyundawy/TrustPositif-To-RPZ-Binary)](https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/releases)
[![Maintenance Status](https://img.shields.io/maintenance/yes/9999)](https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/)
[![License](https://img.shields.io/github/license/alsyundawy/TrustPositif-To-RPZ-Binary)](https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/blob/master/LICENSE)
[![GitHub Issues](https://img.shields.io/github/issues/alsyundawy/TrustPositif-To-RPZ-Binary)](https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/alsyundawy/TrustPositif-To-RPZ-Binary)](https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/pulls)
[![Donate with PayPal](https://img.shields.io/badge/PayPal-donate-orange)](https://www.paypal.me/alsyundawy)
[![Sponsor with GitHub](https://img.shields.io/badge/GitHub-sponsor-orange)](https://github.com/sponsors/alsyundawy)
[![GitHub Stars](https://img.shields.io/github/stars/alsyundawy/TrustPositif-To-RPZ-Binary?style=social)](https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/alsyundawy/TrustPositif-To-RPZ-Binary?style=social)](https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/network/members)
[![GitHub Contributors](https://img.shields.io/github/contributors/alsyundawy/TrustPositif-To-RPZ-Binary?style=social)](https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/graphs/contributors)

## Stargazers over time
[![Stargazers over time](https://starchart.cc/alsyundawy/TrustPositif-To-RPZ-Binary.svg?variant=adaptive)](https://starchart.cc/alsyundawy/TrustPositif-To-RPZ-Binary)

**Membuat DNS Recursive + Filter TrustPositif Sendiri Seperti Yang Selayaknya Di Gunakan Oleh Internet Service Provider (ISP) Di Indonesia**


## Debian / Ubuntu , Install ISC Bind9 

````

#!/usr/bin/env bash

# Script ini digunakan untuk menginstal dan mengonfigurasi BIND9 DNS server
# yang digunakan untuk mengelola DNS dengan konfigurasi RPZ (Response Policy Zone).
# Script ini mengunduh dan mengonfigurasi file konfigurasi BIND9 serta 
# mengunduh dan mengonfigurasi file RPZ binary untuk digunakan dalam sistem.
# Dibuat oleh: Alsyundawy
# Tanggal: 24 Januari 2025


# Warna untuk teks (4 warna terang)
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
MAGENTA='\033[1;35m'
NC='\033[0m' # No Color

# Konfigurasi
BIND_DIR="/etc/bind"
ZONES_DIR="${BIND_DIR}/zones"
RPZ_BINARY="/usr/local/bin/rpz"
CONFIG_FILES=(
    "named.conf.local"
    "named.conf.options"
    "zones/safesearch.zones"
    "zones/whitelist.zones"
)
REPO_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind"
RPZ_URL="https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/raw/refs/heads/main/rpz"

# Fungsi untuk menampilkan pesan error dan keluar
error_exit() {
    echo -e "${MAGENTA}[ERROR] $1${NC}" >&2
    exit 1
}

# Fungsi untuk mengecek status perintah terakhir
check_status() {
    if [ $? -ne 0 ]; then
        error_exit "$1"
    fi
}

# Fungsi untuk memeriksa apakah URL valid
check_url() {
    if ! curl --head --silent --fail "$1" > /dev/null; then
        error_exit "URL tidak valid: $1"
    fi
}

# Fungsi untuk mengunduh file
download_file() {
    local url="$1"
    local destination="$2"
    echo -e "${CYAN}Mengunduh file dari $url ke $destination...${NC}"
    wget -cq "$url" -O "$destination"
    check_status "Gagal mengunduh file dari $url."
}

# Fungsi untuk mengatur kepemilikan dan izin
set_permissions() {
    local target="$1"
    local owner="$2"
    local permissions="$3"
    echo -e "${CYAN}Mengatur kepemilikan dan izin untuk $target...${NC}"
    chown "$owner" "$target"
    check_status "Gagal mengatur kepemilikan untuk $target."
    chmod "$permissions" "$target"
    check_status "Gagal mengatur izin untuk $target."
}

# Memeriksa apakah script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Script ini memerlukan hak akses root. Meminta elevasi...${NC}"
    exec sudo bash "$0" "$@"
    exit
fi

# Menampilkan informasi script
echo -e "${CYAN}# Script ini digunakan untuk menginstal dan mengonfigurasi BIND9 DNS server${NC}"
echo -e "${CYAN}# dengan konfigurasi RPZ (Response Policy Zone).${NC}"
echo -e "${YELLOW}# Dibuat oleh: Alsyundawy${NC}"
echo -e "${YELLOW}# Tanggal: 13 Januari 2025${NC}"

# Memperbaiki masalah hostname
echo -e "${CYAN}Memperbaiki masalah hostname...${NC}"
if ! grep -q "$(hostname)" /etc/hosts; then
    echo "127.0.0.1 $(hostname)" | tee -a /etc/hosts > /dev/null
    check_status "Gagal memperbaiki konfigurasi /etc/hosts."
fi

# Memperbarui sistem secara komprehensif
echo -e "${CYAN}Memperbarui sistem...${NC}"
apt-get update
check_status "Gagal memperbarui repositori."
apt-get upgrade -y
check_status "Gagal melakukan upgrade paket."
apt-get dist-upgrade -y
check_status "Gagal melakukan dist-upgrade."
apt-get full-upgrade -y
check_status "Gagal melakukan full-upgrade."
apt-get --purge autoremove -y
check_status "Gagal membersihkan paket yang tidak terpakai."

# Membersihkan cache paket yang rusak
echo -e "${CYAN}Membersihkan cache paket yang rusak...${NC}"
apt-get clean
apt-get autoclean
apt-get autoremove -y

# Memperbaiki dependency yang rusak
echo -e "${CYAN}Memperbaiki dependency yang rusak...${NC}"
apt-get install -f -y
check_status "Gagal memperbaiki dependency."

# Menginstal paket bind9 dan dnsutils
echo -e "${CYAN}Menginstal paket bind9 dan dnsutils...${NC}"
apt-get install -y bind9 dnsutils
check_status "Gagal menginstal paket yang diperlukan."

# Memastikan folder /etc/bind/zones ada
echo -e "${CYAN}Memastikan folder $ZONES_DIR ada...${NC}"
mkdir -p "$ZONES_DIR"
check_status "Gagal membuat direktori $ZONES_DIR."
set_permissions "$ZONES_DIR" "root:bind" "755"

# Mengunduh dan mengonfigurasi file konfigurasi BIND
echo -e "${YELLOW}Mengunduh dan mengonfigurasi file konfigurasi BIND...${NC}"
for file in "${CONFIG_FILES[@]}"; do
    destination="${BIND_DIR}/${file}"
    url="${REPO_URL}/${file}"
    check_url "$url"
    download_file "$url" "$destination"
    set_permissions "$destination" "root:bind" "644"
done

# Memeriksa konfigurasi BIND9
echo -e "${GREEN}Memeriksa konfigurasi BIND9...${NC}"
named-checkconf
check_status "Konfigurasi BIND tidak valid."

# Memeriksa port 53
echo -e "${CYAN}Memeriksa port 53...${NC}"
if netstat -tuln | grep -q ':53 '; then
    echo -e "${YELLOW}Port 53 sudah digunakan. Menghentikan layanan yang menggunakan port 53...${NC}"
    fuser -k 53/udp 53/tcp
    check_status "Gagal mengosongkan port 53."
fi

# Menjalankan ulang layanan BIND9
echo -e "${GREEN}Menjalankan ulang layanan BIND9...${NC}"
systemctl restart named
check_status "Gagal menjalankan ulang layanan BIND9."

# Mengunduh binary RPZ dan membuatnya dapat dieksekusi
echo -e "${YELLOW}Mengunduh binary RPZ dan membuatnya dapat dieksekusi...${NC}"
check_url "$RPZ_URL"
download_file "$RPZ_URL" "$RPZ_BINARY"
set_permissions "$RPZ_BINARY" "root:root" "755"

# Menambahkan cron job untuk menjalankan RPZ setiap 12 jam
echo -e "${GREEN}Menambahkan cron job untuk menjalankan RPZ setiap 12 jam...${NC}"
(crontab -l 2>/dev/null; echo "0 */12 * * * $RPZ_BINARY > /dev/null 2>&1") | crontab -
check_status "Gagal menambahkan cron job."

# Menjalankan RPZ binary
echo -e "${MAGENTA}Menjalankan RPZ binary...${NC}"
"$RPZ_BINARY"
check_status "Gagal menjalankan binary RPZ."

echo -e "${GREEN}Script selesai dijalankan.${NC}"

````

## Setup Crontab Auto Update Database Setiap 12 Jam

````

crontab -e

* */12 * * * /usr/local/bin/rpz > /dev/null 2>&1

````

## Script untuk Auto Install & Konfig

````

curl -sSL https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind9_dns_rpz_setup_configurator.sh | bash

````
<img width="997" alt="image" src="https://github.com/user-attachments/assets/09c1db0f-d0bc-40fe-b89a-63291e8a000c" />
-


# Access Control Lists (ACLs) Pada Files named.conf.options & IP, sesuaikan dengan ip server dan network

````

// Definisi ACL (Access Control List) untuk jaringan yang diizinkan
acl localnet {
    // Jaringan private IPv4 (RFC 1918)
    10.0.0.0/8;      // Blok IP privat kelas A
    172.16.0.0/12;   // Blok IP privat kelas B
    192.168.0.0/16;  // Blok IP privat kelas C

    // Loopback (localhost)
    127.0.0.0/8;     // Loopback IPv4
    ::1/128;         // Loopback IPv6
    localhost;       // Alias untuk loopback

    // Contoh alamat IPv4 dan IPv6 publik (dikomentari)
    // 202.88.254.0/22; // Contoh blok IPv4 publik
    // 2001:6f83::/32;  // Contoh blok IPv6 publik
};

// Pengaturan global untuk server BIND
options {
    // Direktori untuk menyimpan file cache dan zona
    directory "/var/cache/bind";

    // Mendengarkan permintaan DNS pada port 53 untuk semua IPv4 dan IPv6
    listen-on port 53 { any; };       // Mendengarkan pada port 53 untuk semua IPv4
    listen-on-v6 port 53 { any; };    // Mendengarkan pada port 53 untuk semua IPv6

    // Contoh mendengarkan pada alamat IPv4 dan IPv6 tertentu (dikomentari)
    // listen-on port 53 { 127.0.0.1; 192.168.254.254; 202.88.254.254; }; // IPv4 (loopback, privat, dan publik)
    // listen-on-v6 port 53 { ::1; 2001:6f83:88:99:202:88:254:254; };    // IPv6 (loopback dan publik)

    // Membatasi akses query dan rekursi hanya untuk jaringan yang didefinisikan di `localnet`
    allow-query { localnet; };        // Hanya izinkan query dari `localnet`
    allow-query-on { localnet; };     // Hanya izinkan query pada antarmuka jaringan `localnet`
    allow-recursion { localnet; };    // Hanya izinkan rekursi untuk `localnet`
    allow-recursion-on { localnet; }; // Hanya izinkan rekursi pada antarmuka jaringan `localnet`
    allow-query-cache { localnet; };  // Hanya izinkan query cache untuk `localnet`
    allow-query-cache-on { localnet; }; // Hanya izinkan query cache pada antarmuka jaringan `localnet`
````

# Troubleshooting DNS Dengan Perindah Dasar NSLOOKUP (Support Semua Operations System)

````

#Basic Perintah dasar NSLOOKUP Domain dan IP

nslookup domain/ip ipmesindns

nslookup domain.tld
nslookup domain.tld 127.0.0.1
nslookup domain.tld 192.168.254.254

nslookup 192.168.254.254
nslookup 192.168.254.254 127.0.0.1
nslookup 192.168.254.254 192.168.254.254

#Perintah NSLOOKUP Dengan Menanyakan Query Ke DNS PUBLIK
nslookup domain.tld 8.8.8.8
nslookup domain.tld 1.1.1.1
nslookup domain.tld 9.9.9.9

#Contoh Beberapa Perintah NSLOOKUP
nslookup -query=any example.com
nslookup -query=ns example.com
nslookup -query=a example.com
nslookup -query=aaaa example.com
nslookup -query=mx example.com
nslookup -query=soa example.com


#Perintah NSLOOKUP apabila DNS Server Menggunakan Port Lain Misal Port 5353
nslookup -port=5353 example.com

````


# Konsep Dasar DNS Master Dan Slave

![image](https://github.com/user-attachments/assets/3dc63900-13c3-4bf3-a1bc-0cf97cb39d88)
-
![image](https://github.com/user-attachments/assets/46a2e24e-75f0-4053-b486-0b9ac9ef6200)



**Jika Anda merasa terbantu dan ingin mendukung proyek ini, pertimbangkan untuk berdonasi melalui https://www.paypal.me/alsyundawy. Terima kasih atas dukungannya!**


**Anda bebas untuk mengubah, mendistribusikan script ini untuk keperluan anda**


### Anda Memang Luar Biasa | Harry DS Alsyundawy | Kaum Rebahan Garis Keras & Militan

![Alt](https://repobeats.axiom.co/api/embed/75c94e83220b44df08a86f6dab16eb33d11cfab8.svg "Repobeats analytics image")
