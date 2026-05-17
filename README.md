# 🛡️ TrustPositif To RPZ Binary

**TrustPositif To RPZ Binary** adalah file biner yang mengonversi daftar domain TrustPositif dari Kominfo menjadi format DNS RPZ. Mendukung fitur WhiteList dan Google SafeSearch (terbaru!). ✨
Aplikasi ini dirancang khusus untuk digunakan pada DNS BIND9 di distribusi Linux Debian atau Ubuntu (minimum Debian 12 / Ubuntu 22.04). Saat ini, belum diuji pada Unbound atau distribusi Linux lainnya. Spesifikasi minimum: CPU 2 Core, RAM 8GB. Disarankan menggunakan CPU 4 Core dan RAM 16GB atau lebih untuk performa yang lebih optimal.

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

## 📈 Stargazers over time

[![Stargazers over time](https://starchart.cc/alsyundawy/TrustPositif-To-RPZ-Binary.svg?variant=adaptive)](https://starchart.cc/alsyundawy/TrustPositif-To-RPZ-Binary)

**Membuat DNS Recursive + Filter TrustPositif Sendiri Seperti Yang Selayaknya Di Gunakan Oleh Internet Service Provider (ISP) Di Indonesia** 🌐

## ⚡ Script untuk Auto Install & Konfig, minimum Debian 12 / Ubuntu 22.04 , Install ISC Bind9

Anda dapat mengunduh dan mengeksekusi skrip instalasi secara otomatis dengan menggunakan salah satu perintah di bawah ini (silakan pilih salah satu, `curl` atau `wget`).

**Menggunakan `curl` (Rekomendasi):** 📥

```bash
curl -sSL https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind9_dns_rpz_setup_configurator.sh | bash
```

**Menggunakan `wget` (Alternative):** 📥

```bash
wget -qO- https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind9_dns_rpz_setup_configurator.sh | bash
```

**Source Code dari file bind9_dns_rpz_setup_configurator.sh:** 💻

```bash
#!/usr/bin/env bash

# ============================================================
# Nama       : INSTALL_BIND9_RPZ_SETUP_CONFIGURATOR.SH
# Deskripsi  : Skrip otomasi komprehensif untuk instalasi dan konfigurasi 
#              BIND9 DNS Server terintegrasi dengan Response Policy Zone (RPZ).
#              Fitur utama meliputi:
#              - Deteksi OS (Ubuntu 22.04+ / Debian 12+) & tipe Virtualisasi.
#              - Penanganan otomatis konflik Port 53 & penyesuaian resolv.conf.
#              - Pilihan multi-sumber sinkronisasi database RPZ (GitHub / Komdigi).
#              - Unduhan konfigurasi, binary RPZ, dan penjadwalan pembaruan (12 Jam).
#              - Pemuatan ulang layanan dinamis dan perbaikan struktur jaringan dasar.
# Penulis    : Harry Dertin Sutisna Alsyundawy
# Kontak     : alsyundawy@gmail.com, +628568515212 (WhatsApp/Telegram/Call)
# Homepage   : https://alsyundawy.com
# Repositori : https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary
# Dibuat     : 24 Januari 2025
# Diperbarui : 18 Mei 2026
# Versi      : 2.2
# Lisensi    : MIT
# ============================================================

# Pengaturan keamanan eksekusi:
#   -e          : hentikan skrip jika ada perintah yang gagal
#   -u          : cegah penggunaan variabel yang belum diatur
#   -o pipefail : pipeline gagal jika salah satu bagian gagal
set -euo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------
# Variabel warna untuk output terminal
# ------------------------------------------------------------
readonly CYAN='\033[1;36m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[1;32m'
readonly MAGENTA='\033[1;35m'
readonly NC='\033[0m'

# ------------------------------------------------------------
# Lokasi direktori dan URL yang digunakan
# ------------------------------------------------------------
readonly BIND_DIR="/etc/bind"
readonly ZONES_DIR="${BIND_DIR}/zones"
readonly RPZ_BINARY="/usr/local/bin/rpz"
readonly LOG_FILE="/var/log/install_bind9_rpz.log"
readonly REPO_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind"
RPZ_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/rpz"

# Daftar berkas konfigurasi yang akan diambil dari repositori
readonly -a CONFIG_FILES=(
    "named.conf.local"
    "named.conf.options"
    "zones/alsyundawy_safesearch.zones"
    "zones/alsyundawy_whitelist.zones"
)

# ============================================================
# Fungsi bantuan (logging dan validasi)
# ============================================================

log() {
    local level="$1"
    local message="$2"
    local color="${3:-$NC}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${color}[${level}] ${message}${NC}"
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
}

info()    { log "INFO" "$1" "$CYAN"; }
warn()    { log "WARN" "$1" "$YELLOW"; }
success() { log "OK"   "$1" "$GREEN"; }
error_exit() {
    log "ERROR" "$1" "$MAGENTA"
    exit 1
}

# check_status tidak digunakan secara aktif; dihapus untuk kebersihan kode.

check_url() {
    local url="$1"
    info "Memeriksa URL: ${url}"
    if ! curl --head --silent --fail --location --max-time 15 "${url}" > /dev/null 2>&1; then
        error_exit "URL tidak dapat diakses atau tidak valid: ${url}"
    fi
}

download_file() {
    local url="$1"
    local destination="$2"
    local dir
    dir=$(dirname "${destination}")

    mkdir -p "${dir}" || error_exit "Gagal membuat direktori: ${dir}"

    info "Mengunduh: ${url} -> ${destination}"
    if ! wget --quiet --timeout=30 --tries=3 "${url}" -O "${destination}"; then
        error_exit "Gagal mengunduh file dari: ${url}"
    fi
}

set_permissions() {
    local target="$1"
    local owner="$2"
    local permissions="$3"
    info "Mengatur izin ${permissions} dan kepemilikan ${owner} untuk: ${target}"
    chown "${owner}" "${target}"     || error_exit "Gagal mengatur kepemilikan untuk: ${target}"
    chmod "${permissions}" "${target}" || error_exit "Gagal mengatur izin untuk: ${target}"
}

# ============================================================
# Pemasangan dependensi otomatis
# ============================================================

ensure_command() {
    local cmd="$1"
    local pkg="$2"

    if command -v "${cmd}" &> /dev/null; then
        info "Perintah '${cmd}' tersedia."
        return 0
    fi

    warn "Perintah '${cmd}' tidak ditemukan. Akan diinstal dari paket '${pkg}'..."
    apt-get install -y -qq "${pkg}" || \
        error_exit "Gagal menginstal paket '${pkg}' yang menyediakan '${cmd}'."
    success "Paket '${pkg}' berhasil diinstal."
}

install_dependencies() {
    info "Memperbarui cache paket untuk keperluan dependensi awal..."
    apt-get update -qq || error_exit "Gagal menjalankan apt-get update. Periksa koneksi dan repositori."

    ensure_command "curl"      "curl"
    ensure_command "wget"      "wget"
    ensure_command "systemctl" "systemd"
    ensure_command "ss"        "iproute2"
    ensure_command "netstat"   "net-tools"
    ensure_command "fuser"     "psmisc"
    ensure_command "crontab"   "cron"
}

# ============================================================
# Validasi sistem operasi
# ============================================================

check_os_version() {
    if [ ! -f /etc/os-release ]; then
        warn "Tidak dapat mendeteksi distribusi. Melewati pemeriksaan versi."
        return
    fi

    # shellcheck disable=SC1091
    . /etc/os-release

    case "${ID}" in
        debian)
            if [ "${VERSION_ID}" -lt 12 ]; then
                error_exit "Debian versi ${VERSION_ID} tidak didukung. Minimal Debian 12 (Bookworm). Rekomendasi Debian 13 atau lebih tinggi."
            fi
            if [ "${VERSION_ID}" -lt 13 ]; then
                warn "Debian 12 terdeteksi. Rekomendasi Debian 13 atau lebih tinggi agar memperoleh BIND versi lebih baru."
            else
                success "Debian ${VERSION_ID} memenuhi syarat."
            fi
            ;;
        ubuntu)
            local major_version="${VERSION_ID%.*}"
            if [ "${major_version}" -lt 22 ]; then
                error_exit "Ubuntu versi ${VERSION_ID} tidak didukung. Minimal Ubuntu 22.04 (Jammy). Rekomendasi Ubuntu 24.04 atau lebih tinggi."
            fi
            if [ "${major_version}" -lt 24 ]; then
                warn "Ubuntu ${VERSION_ID} terdeteksi. Rekomendasi Ubuntu 24.04 atau lebih tinggi untuk BIND 9.18+."
            else
                success "Ubuntu ${VERSION_ID} memenuhi syarat."
            fi
            ;;
        *)
            error_exit "Distribusi '${ID}' tidak didukung. Skrip ini hanya mendukung minimal Ubuntu 22.04 (Jammy) dan Debian 12 (Bookworm)."
            ;;
    esac
}

# ============================================================
# Deteksi virtualisasi dan instalasi guest tools
# ============================================================

detect_virtualization() {
    info "Mendeteksi lingkungan virtualisasi..."
    local virt=""
    # Cek menggunakan systemd-detect-virt jika tersedia
    if command -v systemd-detect-virt &>/dev/null; then
        virt=$(systemd-detect-virt 2>/dev/null || true)
    fi

    # Jika tidak terdeteksi, coba baca dari DMI
    if [ -z "${virt}" ] && [ -f /sys/class/dmi/id/product_name ]; then
        local product
        product=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
        case "${product,,}" in
            *vmware*)         virt="vmware" ;;
            *kvm*|*qemu*)    virt="kvm" ;;
            *proxmox*)        virt="kvm" ;;
        esac
    fi

    if [ -z "${virt}" ]; then
        # Fallback: cek dengan lscpu (mungkin tidak ada)
        if command -v lscpu &>/dev/null; then
            local lscpu_out
            lscpu_out=$(lscpu 2>/dev/null || true)
            if echo "${lscpu_out}" | grep -qi "hypervisor vendor"; then
                local hv
                hv=$(echo "${lscpu_out}" | grep -i "Hypervisor vendor" | awk -F: '{print $2}' | xargs)
                case "${hv,,}" in
                    *vmware*) virt="vmware" ;;
                    *kvm*)    virt="kvm" ;;
                esac
            fi
        fi
    fi

    case "${virt}" in
        vmware)
            success "Terdeteksi VMware. Memasang open-vm-tools..."
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq open-vm-tools || \
                warn "Gagal memasang open-vm-tools, lanjut tanpa tools tamu."
            ;;
        kvm)
            success "Terdeteksi KVM/QEMU (Proxmox VE mungkin). Memasang qemu-guest-agent..."
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq qemu-guest-agent || \
                warn "Gagal memasang qemu-guest-agent, lanjut tanpa agen tamu."
            ;;
        *)
            success "Mesin fisik (baremetal) atau virtualisasi tidak teridentifikasi. Melewati instalasi guest tools."
            ;;
    esac
}

# ============================================================
# Pemilihan sumber RPZ
# ============================================================

choose_rpz_source() {
    echo ""
    info "PILIH SUMBER DATABASE RPZ YANG AKAN DIGUNAKAN:"
    info "  1) GITHUB (DEFAULT)"
    info "  2) KOMDIGI"
    read -rp "Masukkan pilihan [1/2, default: 1]: " rpz_choice </dev/tty || rpz_choice=1
    rpz_choice="${rpz_choice:-1}"

    case "${rpz_choice}" in
        2)
            info "MENGGUNAKAN DATABASE RPZ DARI KOMDIGI."
            RPZ_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/rpz-komdigi-database"
            ;;
        *)
            info "MENGGUNAKAN DATABASE RPZ DARI GITHUB (DEFAULT)."
            RPZ_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/rpz"
            ;;
    esac
}

# ============================================================
# Tahapan instalasi dan konfigurasi
# ============================================================

check_root() {
    if [ "${EUID}" -ne 0 ]; then
        warn "Skrip ini memerlukan hak akses root. Meminta elevasi..."
        exec sudo bash "$0" "$@"
        # exec mengganti proses; baris setelah ini tidak akan pernah tercapai
    fi
}

show_banner() {
    local script_name="INSTALL_BIND9_RPZ_SETUP_CONFIGURATOR.SH"
    local os_info
    # shellcheck disable=SC1091
    os_info=$(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-Unknown OS}")
    local kernel_info
    kernel_info=$(uname -r)

    echo -e "${MAGENTA}"
    echo "============================================================"
    echo "  PROGRAM : BIND9 DNS Server + RPZ Installer & Configurator"
    echo "  SCRIPT  : ${script_name}"
    echo "  DESC    : Skrip otomasi instalasi & konfigurasi BIND9"
    echo "            terintegrasi RPZ dengan dukungan multi-sumber,"
    echo "            penanganan port 53, setup resolv.conf,"
    echo "            serta auto-reload layanan,"
    echo "            deteksi OS (Ubuntu 22.04+ / Debian 12+),"
    echo "            dan tipe Virtualisasi."
    echo "------------------------------------------------------------"
    echo "  AUTHOR  : Harry Dertin Sutisna Alsyundawy"
    echo "  LICENSE : MIT License (Free & Open Source)"
    echo "  REPOS   : github.com/alsyundawy/TrustPositif-To-RPZ-Binary"
    echo "------------------------------------------------------------"
    echo "  CONTACT : alsyundawy@gmail.com"
    echo "            +628568515212 (WhatsApp/Telegram/Call)"
    echo "  HOMEPAGE: https://alsyundawy.com"
    echo "------------------------------------------------------------"
    echo "  VERSION : 2.2"
    echo "  UPDATED : 18 May 2026"
    echo "  CREATED : 24 Januari 2025"
    echo "  TARGET  : BIND 9.18 ke atas (Debian >=12, Ubuntu >=22.04)"
    echo "------------------------------------------------------------"
    echo "  SYSTEM  : ${os_info}"
    echo "  KERNEL  : ${kernel_info}"
    echo "  LOGFILE : ${LOG_FILE}"
    echo "============================================================"
    echo -e "${NC}"
}

fix_hostname() {
    info "Memeriksa entri hostname di /etc/hosts..."
    local host
    host=$(hostname)
    if ! grep -qE "^\s*127\.0\.0\.1\s+${host}" /etc/hosts; then
        info "Menambahkan hostname '${host}' ke /etc/hosts..."
        echo "127.0.0.1 ${host}" >> /etc/hosts || error_exit "Gagal memperbarui /etc/hosts."
        success "Hostname '${host}' berhasil ditambahkan."
    else
        success "Hostname '${host}' sudah ada di /etc/hosts."
    fi
}

update_system() {
    info "Memperbarui daftar repositori..."
    apt-get update -qq || error_exit "Gagal memperbarui repositori apt."

    info "Memperbarui paket yang terinstal..."
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq \
        || error_exit "Gagal melakukan upgrade."

    info "Distribusi upgrade (jika diperlukan)..."
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -qq \
        || error_exit "Gagal melakukan dist-upgrade."

    info "Membersihkan paket tidak terpakai..."
    apt-get --purge autoremove -y -qq
    apt-get clean -qq
    apt-get autoclean -qq

    info "Memeriksa dan memperbaiki dependensi..."
    DEBIAN_FRONTEND=noninteractive apt-get install -f -y -qq \
        || error_exit "Gagal memperbaiki dependensi."

    success "Sistem berhasil diperbarui."
}

install_bind9() {
    info "Menginstal paket BIND9, alat bantu, dan utilitas jaringan..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        bind9 bind9-dnsutils bind9-utils \
        bc git htop iftop telnet traceroute rsync screen whois fping ipcalc subnetcalc 'libidn*' \
        || error_exit "Gagal menginstal paket-paket yang diperlukan."
    success "Semua paket (BIND9, dnsutils, dan utilitas) terinstal."
}

setup_zones_dir() {
    info "Menyiapkan direktori zone: ${ZONES_DIR}"
    mkdir -p "${ZONES_DIR}" || error_exit "Gagal membuat direktori: ${ZONES_DIR}"
    set_permissions "${ZONES_DIR}" "root:bind" "755"
    success "Direktori zone siap."
}

download_bind_configs() {
    info "Mengambil file konfigurasi BIND9 dari repositori..."
    for file in "${CONFIG_FILES[@]}"; do
        local destination="${BIND_DIR}/${file}"
        local url="${REPO_URL}/${file}"
        
        if [[ "$file" == "named.conf.local" || "$file" == "named.conf.options" ]]; then
            if [ -f "${destination}" ]; then
                warn "File ${destination} sudah ada. Membuat backup ke ${destination}.bak"
                cp -a "${destination}" "${destination}.bak" || error_exit "Gagal membuat backup."
                rm -f "${destination}"
            fi
        fi

        check_url "${url}"
        download_file "${url}" "${destination}"
        set_permissions "${destination}" "root:bind" "644"
        success "File '${file}' berhasil dikonfigurasi."
    done
}

validate_bind_config() {
    info "Memvalidasi konfigurasi BIND..."
    if ! named-checkconf; then
        error_exit "Konfigurasi BIND9 tidak valid. Silakan periksa file di ${BIND_DIR}."
    fi
    success "Konfigurasi BIND9 valid."
}

handle_port53() {
    info "Memeriksa port 53..."
    if ss -tuln 2>/dev/null | grep -q ':53 ' || \
       netstat -tuln 2>/dev/null | grep -q ':53 '; then

        warn "Port 53 sedang dipakai. Menghentikan proses yang menggunakan..."

        if systemctl is-active --quiet systemd-resolved; then
            systemctl stop systemd-resolved
            systemctl disable systemd-resolved
            warn "systemd-resolved dihentikan dan dinonaktifkan."
        fi

        fuser -k 53/udp 2>/dev/null || true
        fuser -k 53/tcp 2>/dev/null || true
        sleep 2
        success "Port 53 berhasil dibersihkan."
    else
        success "Port 53 tersedia."
    fi
}

restart_bind9() {
    info "Menyalakan ulang BIND9 (named)..."
    systemctl restart named || error_exit "Gagal menjalankan BIND9."
    systemctl enable named --quiet
    success "BIND9 aktif dan dijadwalkan menyala saat boot."
}

setup_rpz_binary() {
    info "Mengunduh binary RPZ..."
    check_url "${RPZ_URL}"
    download_file "${RPZ_URL}" "${RPZ_BINARY}"
    set_permissions "${RPZ_BINARY}" "root:root" "755"
    success "Binary RPZ siap di ${RPZ_BINARY}"
}

setup_cron() {
    info "Menyiapkan cron job untuk RPZ (tiap 12 jam)..."
    local cron_entry="0 */12 * * * ${RPZ_BINARY} >> ${LOG_FILE} 2>&1"

    if { crontab -l 2>/dev/null || true; } | grep -qF "${RPZ_BINARY}"; then
        warn "Cron job RPZ sudah ada, lewati."
    else
        ( crontab -l 2>/dev/null || true; echo "${cron_entry}" ) | crontab - \
            || error_exit "Gagal menambahkan cron job."
        success "Cron job berhasil ditambahkan: ${cron_entry}"
    fi
}

configure_resolv_conf() {
    info "Mengonfigurasi /etc/resolv.conf untuk menggunakan 127.0.0.1 di urutan pertama..."
    if [ -L /etc/resolv.conf ]; then
        warn "/etc/resolv.conf adalah symlink, menggantinya dengan file reguler..."
        local real_file
        real_file=$(readlink -f /etc/resolv.conf)
        rm -f /etc/resolv.conf
        if [ -f "${real_file}" ]; then
            cp "${real_file}" /etc/resolv.conf
        else
            touch /etc/resolv.conf
        fi
    fi
    sed -i '/^[[:space:]]*nameserver[[:space:]]*127\.0\.0\.1[[:space:]]*$/d' /etc/resolv.conf 2>/dev/null || true
    local tmp_resolv
    tmp_resolv=$(mktemp)
    echo "nameserver 127.0.0.1" > "${tmp_resolv}"
    cat /etc/resolv.conf >> "${tmp_resolv}" 2>/dev/null || true
    cat "${tmp_resolv}" > /etc/resolv.conf
    rm -f "${tmp_resolv}"
    success "nameserver 127.0.0.1 berhasil ditambahkan di awal baris /etc/resolv.conf."
}

run_rpz() {
    info "Menjalankan RPZ untuk sinkronisasi awal..."
    "${RPZ_BINARY}" || error_exit "Gagal menjalankan binary RPZ: ${RPZ_BINARY}"
    success "RPZ berhasil dijalankan."
}

# ============================================================
# Jalur utama skrip
# ============================================================
main() {
    mkdir -p "$(dirname "${LOG_FILE}")"
    touch "${LOG_FILE}"

    check_root "$@"
    show_banner
    choose_rpz_source

    if ! command -v apt-get &>/dev/null; then
        error_exit "apt-get tidak ditemukan. Skrip hanya bekerja pada distribusi Debian/Ubuntu."
    fi

    check_os_version
    fix_hostname
    update_system
    install_dependencies
    detect_virtualization
    
    handle_port53
    install_bind9
    setup_zones_dir
    download_bind_configs
    validate_bind_config
    restart_bind9
    setup_rpz_binary
    setup_cron
    configure_resolv_conf

    echo ""
    success "============================================================"
    success " Instalasi BIND9 + RPZ selesai dengan sukses!"
    success " Log kegiatan tersimpan di: ${LOG_FILE}"
    success "============================================================"

    # Konfirmasi menjalankan RPZ
    echo ""
    info "Proses instalasi selesai. Apakah Anda ingin langsung menjalankan binary RPZ sekarang?"
    read -rp "    Jalankan RPZ? [Y/n] " answer </dev/tty || answer="y"
    answer="${answer:-y}"
    case "${answer:0:1}" in
        y|Y|"")
            run_rpz
            info "Memuat ulang layanan BIND9..."
            rndc reload || warn "rndc reload gagal atau belum dikonfigurasi."
            systemctl reload-or-restart named || error_exit "Gagal memuat ulang layanan BIND9."
            success "Layanan BIND9 berhasil dimuat ulang."
            ;;
        *)
            info "RPZ tidak dijalankan. Anda dapat menjalankannya nanti dengan perintah:"
            info "  ${RPZ_BINARY}"
            ;;
    esac

    echo ""
    info "Tips pengujian DNS dengan nslookup:"
    info "  - Uji dari server ini:  nslookup google.com 127.0.0.1"
    info "  - Uji dari klien    :  nslookup google.com <alamat IP server ini>"
    info "  - Uji dari server ini:  nslookup pornhub.com 127.0.0.1"
    info "  - Uji dari klien    :  nslookup pornhub.com <alamat IP server ini>"
    info "  Jika RPZ memblokir domain tertentu, respon akan berbeda."
    info "  Pastikan klien menggunakan DNS server ini agar RPZ aktif."
}

main "$@"
```

## 🚀 Panduan Instalasi Kernel Zabbly (Ubuntu / Debian)

Untuk mendapatkan performa yang optimal, peningkatan stabilitas, dan keamanan tingkat lanjut (*security*) baik pada lingkungan *baremetal* maupun virtualisasi, sangat disarankan untuk menggunakan **Kernel Zabbly** terbaru.

### 1️⃣ Unduh dan Simpan GPG Key
Anda dapat menggunakan `curl` atau `wget` untuk menyimpan kunci otentikasi Zabbly:

**Menggunakan `curl` (Rekomendasi):** 📥
```bash
mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc
```

**Menggunakan `wget` (Alternative):** 📥
```bash
mkdir -p /etc/apt/keyrings/
wget -q https://pkgs.zabbly.com/key.asc -O /etc/apt/keyrings/zabbly.asc
```

### 2️⃣ Tambahkan Repositori Stabil
Jalankan perintah berikut untuk menambahkan repositori Zabbly ke sistem Anda:

```bash
sh -c 'cat <<EOF > /etc/apt/sources.list.d/zabbly-kernel-stable.sources
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/kernel/stable
Suites: $(. /etc/os-release && echo ${VERSION_CODENAME})
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/zabbly.asc
EOF'
```

### 3️⃣ Install Kernel Zabbly
Setelah repositori ditambahkan, perbarui daftar paket dan instal kernel Zabbly:

```bash
apt-get update
apt-get install linux-zabbly -y
```

> 💡 **Catatan:** Setelah instalasi selesai, pastikan untuk melakukan *reboot* pada server Anda agar sistem memuat dan menggunakan kernel baru.

## ⚙️ Cara Install BIND Versi 9.20 / 9.21

Untuk memperoleh BIND versi lebih baru (9.20 atau 9.21) yang tidak tersedia di repositori bawaan distribusi, Anda dapat menggunakan sumber paket tambahan berikut.

### 🟠 Ubuntu (22.04 / 24.04) — Menggunakan PPA Resmi ISC

ISC menyediakan PPA (Personal Package Archive) resmi untuk Ubuntu yang berisi BIND versi terbaru:

- Stabil (9.20): `ppa:isc/bind`
- Pengembangan (9.21): `ppa:isc/bind-dev`

```bash
# Tambahkan PPA (pilih salah satu)
sudo add-apt-repository ppa:isc/bind        # Versi stabil 9.20
# sudo add-apt-repository ppa:isc/bind-dev  # Versi pengembangan 9.21

# Perbarui daftar paket
sudo apt update

# Install BIND beserta utilitas pendukung
sudo apt install bind9 bind9-dnsutils bind9-utils
```

### 🔴 Debian (12 / 13) — Menggunakan Repositori deb.sury.org

Untuk Debian, ISC merekomendasikan repositori yang dikelola oleh Ondrej Surý di `packages.sury.org`. Repositori ini menyediakan paket BIND yang lebih baru dibandingkan repositori bawaan Debian:

```bash
# Install dependensi
sudo apt update
sudo apt install -y lsb-release ca-certificates curl

# Unduh dan pasang kunci GPG repositori
sudo curl -sSLo /tmp/debsuryorg-archive-keyring.deb \
  https://packages.sury.org/debsuryorg-archive-keyring.deb
sudo dpkg -i /tmp/debsuryorg-archive-keyring.deb

# Tambahkan repositori BIND (pilih salah satu)

# Versi stabil 9.20:
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/bind/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/bind.list'

# Versi pengembangan 9.21:
# sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/bind-dev/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/bind-dev.list'

# Perbarui daftar paket dan install
sudo apt update
sudo apt install bind9 bind9-dnsutils bind9-utils
```

### 📌 Catatan

- Versi 9.21 adalah cabang pengembangan (development) dan ditujukan untuk pengujian, bukan untuk lingkungan produksi.
- Untuk server produksi, gunakan versi stabil 9.20.

### ⏰ Setup Crontab Auto Update Database Setiap 12 Jam

```bash

crontab -e

* */12 * * * /usr/local/bin/rpz > /dev/null 2>&1
```

![image](https://github.com/user-attachments/assets/09c1db0f-d0bc-40fe-b89a-63291e8a000c)

## 🔒 Access Control Lists (ACLs) Pada Files named.conf.options & IP, sesuaikan dengan ip server dan network

```conf

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
    allow-recursion { localnet; };    // Hanya izinkan rekursi untuk `localnet`
    allow-query-cache { localnet; };  // Hanya izinkan query cache untuk `localnet`
```

## 🛠️ Troubleshooting DNS Dengan Perintah Dasar NSLOOKUP (Support Semua Operating System)

```bash
#BASIC PERINTAH DASAR NSLOOKUP DOMAIN DAN IP (WAJIB DIKETAHUI UNTUK TROBLESHOTING DNS!)

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
```

## 🏗️ Konsep Dasar DNS Master Dan Slave

![image](https://github.com/user-attachments/assets/3dc63900-13c3-4bf3-a1bc-0cf97cb39d88)

![image](https://github.com/user-attachments/assets/46a2e24e-75f0-4053-b486-0b9ac9ef6200)

**Jika Anda merasa terbantu dan ingin mendukung proyek ini, pertimbangkan untuk berdonasi melalui <https://www.paypal.me/alsyundawy>. Terima kasih atas dukungannya!** ☕

**Jika Anda merasa terbantu dan ingin mendukung proyek ini, pertimbangkan untuk berdonasi melalui QRIS. Terima kasih atas dukungannya!** ☕

![image](https://github.com/user-attachments/assets/a0126f28-6dde-43da-ba14-d7c9a27de0df)

**Anda bebas untuk mengubah, mendistribusikan script ini untuk keperluan anda** 📝

**Jangan semangat tetap putus asa, tetaplah mengeluh meski gak ada yang pedulikan. Ketika yang lain bisa kenapa harus saya, ketika yang lain tidak bisa apalagi saya. Tetaplah hidup meski tidak berguna, maju tak gentar membela yang bayar !!!! Yoi, ya begitulah .....** 🤣

### ✨ Anda Memang Luar Biasa | Harry DS Alsyundawy | Kaum Rebahan Garis Keras & Militan ✨

## 💡 SAYA HANYA HOBBY NGOPREK BUKAN ORANG KOMDIGI

![Alt](https://repobeats.axiom.co/api/embed/75c94e83220b44df08a86f6dab16eb33d11cfab8.svg "Repobeats analytics image")
