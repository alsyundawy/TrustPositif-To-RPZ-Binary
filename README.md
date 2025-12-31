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


**If you find this project helpful and would like to support it, please consider donating via https://www.paypal.me/alsyundawy. Thank you for your support!**

**Jika Anda merasa terbantu dan ingin mendukung proyek ini, pertimbangkan untuk berdonasi melalui https://www.paypal.me/alsyundawy. Terima kasih atas dukungannya!**

**Jika Anda merasa terbantu dan ingin mendukung proyek ini, pertimbangkan untuk berdonasi melalui QRIS. Terima kasih atas dukungannya!**

<img width="1240" height="1748" alt="image" src="https://github.com/user-attachments/assets/8d29f4c0-b9a8-4a0d-b90b-0bf0aa2a16f3" />


**Membuat DNS Recursive + Filter TrustPositif Sendiri Seperti Yang Selayaknya Di Gunakan Oleh Internet Service Provider (ISP) Di Indonesia**


## Debian / Ubuntu , Install ISC Bind9 

````

#!/usr/bin/env bash
#
# setup-dns-rpz.sh
# Menginstal dan mengonfigurasi BIND9 dengan Response Policy Zone (RPZ), system hardening, pengaturan zona waktu Asia/Jakarta, dan integrasi daftar TrustPositif.
# Fitur:
#   - Memeriksa izin root sebelum eksekusi
#   - Konfirmasi instalasi DNS TrustPositif di awal
#   - Menonaktifkan layanan konflik (systemd-resolved, dll.)
#   - Mengatur file resolv.conf dan hosts
#   - Memperbarui sistem operasi
#   - Mengunduh dan mengatur konfigurasi BIND serta zona TrustPositif
#   - Menjadwalkan pembaruan RPZ melalui cron
# Penulis       : Harry Dertin Sutisna Alsyundawy
# Dibuat        : Jakarta, 25 November 2024
# Dimodifikasi  : Jakarta, 02 Juli 2025

set -euo pipefail
IFS=$'\n\t'

# Warna ANSI untuk tampilan
MERAH="\033[1;31m"
HIJAU="\033[1;32m"
KUNING="\033[1;33m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
BIRU="\033[1;34m"
PUTIH="\033[1;37m"
HITAM="\033[1;30m"
ABUABU="\033[1;90m"
MERAH_TUA="\033[1;91m"
HIJAU_TUA="\033[1;92m"
KUNING_TUA="\033[1;93m"
CYAN_TUA="\033[1;96m"
MAGENTA_TUA="\033[1;95m"
BIRU_TUA="\033[1;94m"
PUTIH_TUA="\033[1;97m"
RESET="\033[0m"

# Jalur dan URL yang digunakan
BIND_DIR="/etc/bind"
ZONES_DIR="$BIND_DIR/zones"
RPZ_BINARY="/usr/local/bin/rpz"
RPZ_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/rpz"
URL_TRUSTPOSITIF="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/alsyundawy-blocklist/alsyundawy_blacklist.txt"
FILE_TRUSTPOSITIF="/etc/bind/zones/trustpositif.zones"
CNAME_TRUSTPOSITIF="lamanlabuh.resolver.id."
TMP_TRUSTPOSITIF="/tmp/trustpositif_domains.txt"
declare -A CONFIG_URLS=(
  ["named.conf.local"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/named.conf.local"
  ["named.conf.options"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/named.conf.options"
  ["safesearch.zones"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/zones/safesearch.zones"
  ["whitelist.zones"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/zones/whitelist.zones"
)

# Fungsi untuk mencetak pesan dengan warna
cetak_pesan() {
    echo -e "$1$2${RESET}"
}

# Fungsi pembantu untuk pesan
echo_error() { cetak_pesan "$MERAH" "[KESALAHAN] $*" >&2; exit 1; }
echo_status() { cetak_pesan "$HIJAU" "[OK] $*"; }
echo_info() { cetak_pesan "$CYAN" "[INFO] $*"; }

# Konfirmasi instalasi DNS server TrustPositif
konfirmasi_instalasi() {
  cetak_pesan "$KUNING" "Apakah Anda ingin menginstal DNS server TrustPositif? (yes/y atau no/n): "
  read -r jawaban
  case "$jawaban" in
    [Yy]|[Yy][Ee][Ss])
      cetak_pesan "$HIJAU" "Melanjutkan instalasi..."
      ;;
    [Nn]|[Nn][Oo])
      cetak_pesan "$MERAH" "Instalasi dibatalkan."
      exit 0
      ;;
    *)
      echo_error "Jawaban tidak valid. Gunakan yes/y atau no/n."
      ;;
  esac
}

# Menampilkan banner awal
tampilkan_banner() {
  cetak_pesan "$BIRU_TUA" "========================================"
  cetak_pesan "$BIRU_TUA" "  Memulai Skrip Pengaturan DNS+RPZ"
  cetak_pesan "$BIRU_TUA" "========================================"
}

# Menampilkan pemberitahuan awal
tampilkan_pemberitahuan() {
  cetak_pesan "$MERAH_TUA" "######################################################################"
  cetak_pesan "$MERAH_TUA" "##                                                                  ##"
  cetak_pesan "$MERAH_TUA" "##  PEMBERITAHUAN, UNTUK KINERJA OPTIMAL SILAKAN GUNAKAN:           ##"
  cetak_pesan "$MERAH_TUA" "##  - ISC BIND versi 9.20.xx Atau 9.21.xx dari isc.org/download     ##"
  cetak_pesan "$MERAH_TUA" "##  - CPU minimal 4 inti                                            ##"
  cetak_pesan "$MERAH_TUA" "##  - RAM minimal 16GB                                              ##"
  cetak_pesan "$MERAH_TUA" "##  - OS Ubuntu/Debian dengan kernel Zabbly+ terbaru                ##"
  cetak_pesan "$MERAH_TUA" "##                                                                  ##"
  cetak_pesan "$MERAH_TUA" "######################################################################"
}

# Memastikan skrip dijalankan sebagai root
pastikan_root() {
  if [[ $EUID -ne 0 ]]; then
    echo_error "Harus dijalankan sebagai root. Gunakan: sudo bash setup-dns-rpz.sh"
  fi
}

# Menonaktifkan dash sebagai /bin/sh
konfigurasi_dash() {
  echo_info "Menonaktifkan dash sebagai /bin/sh..."
  echo "dash dash/sh boolean false" | debconf-set-selections
  dpkg-reconfigure -f noninteractive dash || echo_error "Gagal mengonfigurasi ulang dash"
  echo_status "dash diputuskan dari /bin/sh"
}

# Membersihkan riwayat bash
bersihkan_riwayat() {
  echo_info "Membersihkan riwayat bash..."
  history -c && history -w
  echo_status "Riwayat dibersihkan"
}

# Mengatur zona waktu ke Asia/Jakarta
atur_zona_waktu() {
  echo_info "Mengatur zona waktu ke Asia/Jakarta..."
  timedatectl set-timezone Asia/Jakarta || echo_error "Pengaturan zona waktu gagal"
  echo_status "Zona waktu diatur"
}

# Memperbaiki file /etc/hosts
perbaiki_hosts() {
  echo_info "Memperbarui /etc/hosts..."
  hn=$(hostname)
  grep -qF "$hn" /etc/hosts || echo "127.0.0.1 $hn" >> /etc/hosts
  echo_status "/etc/hosts diperbarui"
}

# Menonaktifkan layanan yang bertentangan
nonaktifkan_konflik() {
  echo_info "Menonaktifkan systemd-resolved & networkd-wait-online..."
  systemctl disable --now systemd-resolved systemd-networkd-wait-online.service 2>/dev/null || true
  echo_status "Layanan yang bertentangan dinonaktifkan"
}

# Mengatur file resolv.conf
konfigurasi_resolv() {
  echo_info "Menulis /etc/resolv.conf..."
  unlink /etc/resolv.conf 2>/dev/null || true
  cat <<EOF > /etc/resolv.conf
search google.com
nameserver 127.0.0.1
nameserver 43.247.23.161
nameserver 43.247.23.188
nameserver 1.1.1.2
EOF
  echo_status "resolv.conf dikonfigurasi"
}

# Memperbarui sistem operasi
perbarui_sistem() {
  echo_info "Memperbarui daftar paket..."
  apt-get update
  echo_info "Meningkatkan paket..."
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
  DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
  apt-get autoremove -y
  apt-get clean
  echo_status "Sistem diperbarui"
}

# Menginstal BIND9 dan dnsutils
instal_bind() {
  echo_info "Menginstal bind9 & dnsutils..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 dnsutils || echo_error "Instalasi Bind9 gagal"
  echo_status "Bind9 diinstal"
}

# Menyiapkan direktori untuk zona BIND
siapkan_direktori() {
  echo_info "Membuat direktori zona..."
  mkdir -p "$ZONES_DIR"
  chown root:bind "$ZONES_DIR"
  chmod 755 "$ZONES_DIR"
  echo_status "$ZONES_DIR siap"
}

# Fungsi untuk mengunduh file dan mengatur izin
unduh_dan_izin() {
  local url="$1" dest="$2" pemilik="$3" izin="$4"
  echo_info "Mengunduh $url"
  curl -# -fSL "$url" -o "$dest" || echo_error "Unduhan gagal: $url"
  chown "$pemilik" "$dest" || echo_error "Gagal mengubah kepemilikan pada $dest"
  chmod "$izin" "$dest"
  echo_status "$dest siap"
}

# Menyebarkan file konfigurasi BIND
sebarkan_konfigurasi() {
  echo_info "Menyebarkan konfigurasi BIND..."
  for file in "${!CONFIG_URLS[@]}"; do
    if [[ "$file" == *".zones" ]]; then
      dest_dir="$ZONES_DIR"
    else
      dest_dir="$BIND_DIR"
    fi
    unduh_dan_izin "${CONFIG_URLS[$file]}" "$dest_dir/$file" root:bind 644
  done
}

# Mengatur zona TrustPositif
atur_trustpositif() {
  echo_info "Mengatur zona TrustPositif..."
  unduh_dan_izin "$URL_TRUSTPOSITIF" "$TMP_TRUSTPOSITIF" root:root 644
  echo_info "Menghasilkan $FILE_TRUSTPOSITIF..."
  echo -e "\$TTL 86400\n@ IN SOA ns1.localhost. admin.localhost. ( $(date +%Y%m%d01) 3600 1800 604800 86400 )\n@ IN NS ns1.localhost." > "$FILE_TRUSTPOSITIF"
  while IFS= read -r domain; do
    [[ -z "$domain" || "$domain" =~ ^# ]] && continue
    echo "$domain CNAME $CNAME_TRUSTPOSITIF" >> "$FILE_TRUSTPOSITIF"
  done < "$TMP_TRUSTPOSITIF"
  chown root:bind "$FILE_TRUSTPOSITIF"
  chmod 644 "$FILE_TRUSTPOSITIF"
  rm -f "$TMP_TRUSTPOSITIF"
  echo_status "Zona TrustPositif dikonfigurasi"
}

# Memulai ulang layanan BIND
mulai_ulang_bind() {
  echo_info "Memeriksa konfigurasi BIND..."
  named-checkconf || echo_error "Konfigurasi BIND tidak valid"
  echo_info "Memulai ulang BIND9..."
  systemctl restart bind9 || echo_error "Mulai ulang BIND gagal"
  echo_status "BIND9 berjalan"
}

# Mengatur RPZ
atur_rpz() {
  echo_info "Menginstal biner RPZ..."
  unduh_dan_izin "$RPZ_URL" "$RPZ_BINARY" root:root 755
  echo_info "Menambahkan tugas cron..."
  (crontab -l 2>/dev/null || true; echo "0 */12 * * * $RPZ_BINARY >/dev/null 2>&1") | crontab -
  echo_status "Tugas cron RPZ dijadwalkan"
}

# Fungsi utama untuk menjalankan semua langkah
utama() {
  konfirmasi_instalasi
  pastikan_root
  tampilkan_banner
  tampilkan_pemberitahuan
  konfigurasi_dash
  bersihkan_riwayat
  atur_zona_waktu
  perbaiki_hosts
  nonaktifkan_konflik
  konfigurasi_resolv
  perbarui_sistem
  instal_bind
  siapkan_direktori
  sebarkan_konfigurasi
  atur_trustpositif
  mulai_ulang_bind
  atur_rpz

  cetak_pesan "$HIJAU_TUA" "=== Semua tugas selesai dengan sukses! ==="
}

# Menjalankan fungsi utama
utama "$@"


````

## Setup Crontab Auto Update Database Setiap 12 Jam

````

crontab -e

* */12 * * * /usr/local/bin/rpz > /dev/null 2>&1

````

## Script untuk Auto Install & Konfig

````

curl -sSL https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/setup-dns-rpz.sh | bash

````

![image](https://github.com/user-attachments/assets/b4d1a6fa-5bbe-4972-a93c-671072302bcb)

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
