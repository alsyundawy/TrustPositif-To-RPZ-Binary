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
#
# setup-dns-rpz.sh
# Automatically install/configure BIND9 with RPZ, hardening, locale, and timezone
# Author       : HARRY DERTIN SUTISNA ALSYUNDAWY
# Date         : Jakarta, 12 Mei 2025

set -euo pipefail
IFS=$'\n\t'

# Banner
echo "========================================"
echo "  Starting DNS+RPZ Setup Script"
echo "========================================"

# Color definitions
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
MAGENTA="\033[1;35m"
NC="\033[0m"  # No Color

# Paths and URLs
BIND_DIR="/etc/bind"
ZONES_DIR="$BIND_DIR/zones"
RPZ_BINARY="/usr/local/bin/rpz"
RPZ_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/rpz"
declare -A CONFIG_URLS=(
  ["named.conf.local"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/named.conf.local"
  ["named.conf.options"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/named.conf.options"
  ["safesearch.zones"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/zones/safesearch.zones"
  ["whitelist.zones"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/zones/whitelist.zones"
)

# Helpers
echo_error(){ echo -e "${MAGENTA}[ERROR] $*${NC}" >&2; exit 1; }
echo_status(){ echo -e "${GREEN}[OK] $*${NC}"; }

# Check root privileges
ensure_root(){
  if [[ $EUID -ne 0 ]]; then
    echo_error "Must run as root. Use: sudo bash setup-dns-rpz.sh"
  fi
}

# Disable dash as /bin/sh
configure_dash(){
  echo -e "${CYAN}Disabling dash as /bin/sh...${NC}"
  echo "dash dash/sh boolean false" | debconf-set-selections
  dpkg-reconfigure -f noninteractive dash || echo_error "Failed to reconfigure dash"
  echo_status "dash unlinked from /bin/sh"
}

# Clear bash history secure
clear_history(){
  echo -e "${CYAN}Clearing bash history...${NC}"
  history -c && history -w
  echo_status "History cleared"
}

# Set timezone
set_timezone(){
  echo -e "${CYAN}Setting timezone to Asia/Jakarta...${NC}"
  timedatectl set-timezone Asia/Jakarta || echo_error "Timezone set failed"
  echo_status "Timezone set"
}

# Fix hosts
fix_hosts(){
  echo -e "${CYAN}Updating /etc/hosts...${NC}"
  hn=$(hostname)
  grep -qF "$hn" /etc/hosts || echo "127.0.0.1 $hn" >> /etc/hosts
  echo_status "/etc/hosts updated"
}

# Disable services
disable_conflicts(){
  echo -e "${CYAN}Disabling systemd-resolved & networkd-wait-online...${NC}"
  systemctl disable --now systemd-resolved systemd-networkd-wait-online.service 2>/dev/null || true
  echo_status "Conflicting services disabled"
}

# Configure resolv.conf
configure_resolv(){
  echo -e "${CYAN}Writing /etc/resolv.conf...${NC}"
  unlink /etc/resolv.conf 2>/dev/null || true
  cat <<EOF > /etc/resolv.conf
search google.com
nameserver 127.0.0.1
nameserver 43.247.23.161
nameserver 43.247.23.188
nameserver 1.1.1.2
EOF
  echo_status "resolv.conf configured"
}

# Update system
update_system(){
  echo -e "${CYAN}Updating package lists...${NC}"
  apt-get update
  echo -e "${CYAN}Upgrading packages...${NC}"
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
  DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
  apt-get autoremove -y
  apt-get clean
  echo_status "System updated"
}

# Prepare BIND dirs
prepare_directories(){
  echo -e "${CYAN}Creating zones directory...${NC}"
  mkdir -p "$ZONES_DIR"
  chown root:bind "$ZONES_DIR"
  chmod 755 "$ZONES_DIR"
  echo_status "$ZONES_DIR ready"
}

# Install BIND
install_bind(){
  echo -e "${CYAN}Installing bind9 & dnsutils...${NC}"
  DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 dnsutils || echo_error "Bind9 install failed"
  echo_status "Bind9 installed"
}

# Download helper
download_and_perms(){
  local url="$1" dest="$2" owner="$3" perms="$4"
  echo -e "${CYAN}Downloading $url${NC}"
  curl -# -fSL "$url" -o "$dest" || echo_error "Download failed"
  chown "$owner" "$dest"
  chmod "$perms" "$dest"
  echo_status "$dest ready"
}

# Deploy config files
deploy_configs(){
  echo -e "${CYAN}Deploying BIND configs...${NC}"
  for file in "${!CONFIG_URLS[@]}"; do
    download_and_perms "${CONFIG_URLS[$file]}" "$BIND_DIR/$file" root:bind 644
  done
}

# Restart BIND
restart_bind(){
  echo -e "${CYAN}Checking BIND config...${NC}"
  named-checkconf || echo_error "Invalid BIND config"
  echo -e "${CYAN}Restarting BIND9...${NC}"
  systemctl restart bind9 || echo_error "BIND restart failed"
  echo_status "BIND9 running"
}

# Setup RPZ
setup_rpz(){
  echo -e "${CYAN}Installing RPZ binary...${NC}"
  download_and_perms "$RPZ_URL" "$RPZ_BINARY" root:root 755
  echo -e "${CYAN}Adding cron job...${NC}"
  (crontab -l 2>/dev/null || true; echo "0 */12 * * * $RPZ_BINARY >/dev/null 2>&1") | crontab -
  echo_status "RPZ cron scheduled"
}

# Main
main(){
  ensure_root
  configure_dash
  clear_history
  set_timezone
  fix_hosts
  disable_conflicts
  configure_resolv
  update_system
  prepare_directories
  install_bind
  deploy_configs
  restart_bind
  setup_rpz
  echo -e "${GREEN}=== All tasks completed successfully! ===${NC}"
}

main "$@"

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
