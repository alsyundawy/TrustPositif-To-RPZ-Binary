# TrustPositif To RPZ Binary

**TrustPositif To RPZ Binary** adalah file biner yang mengonversi daftar domain TrustPositif dari Kominfo menjadi format DNS RPZ. Mendukung fitur WhiteList dan Google SafeSearch (terbaru!). 
Aplikasi ini dirancang khusus untuk digunakan pada DNS BIND9 di distribusi Linux Debian atau Ubuntu. Saat ini, belum diuji pada Unbound atau distribusi Linux lainnya. Spesifikasi minimum: CPU 2 Core, RAM 4GB. Disarankan menggunakan CPU 4 Core dan RAM 8GB hingga 16GB untuk performa yang lebih optimal.


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



## Debian / Ubuntu , Install ISC Bind9 

````

#!/bin/bash

# Script ini digunakan untuk menginstal dan mengonfigurasi BIND9 DNS server
# yang digunakan untuk mengelola DNS dengan konfigurasi RPZ (Response Policy Zone).
# Script ini mengunduh dan mengonfigurasi file konfigurasi BIND9 serta 
# mengunduh dan mengonfigurasi file RPZ binary untuk digunakan dalam sistem.
# Dibuat oleh: Alsyundawy
# Tanggal: 3 Januari 2025

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

# Mengunduh binary RPZ dan membuatnya dapat dieksekusi
sudo wget -cq https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/raw/refs/heads/main/rpz -O /usr/local/bin/rpz
sudo chmod +x /usr/local/bin/rpz

# Menjalankan RPZ binary
sudo rpz


````




## Setup Crontab Auto Update Database Setiap 12 Jam

````

crontab -e

* */12 * * * /usr/local/bin/rpz > /dev/null 2>&1

````

<img width="997" alt="image" src="https://github.com/user-attachments/assets/09c1db0f-d0bc-40fe-b89a-63291e8a000c" />


**Jika Anda merasa terbantu dan ingin mendukung proyek ini, pertimbangkan untuk berdonasi melalui https://www.paypal.me/alsyundawy. Terima kasih atas dukungannya!**


**Anda bebas untuk mengubah, mendistribusikan script ini untuk keperluan anda**


### Anda Memang Luar Biasa | Harry DS Alsyundawy | Kaum Rebahan Garis Keras & Militan

![Alt](https://repobeats.axiom.co/api/embed/75c94e83220b44df08a86f6dab16eb33d11cfab8.svg "Repobeats analytics image")



