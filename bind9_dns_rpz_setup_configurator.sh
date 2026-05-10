#!/usr/bin/env bash

# ============================================================
# SCRIPT     : INSTALL_BIND9_RPZ_SETUP_CONFIGURATOR.SH
# DESKRIPSI  : MENGINSTAL DAN MENGONFIGURASI BIND9 DNS SERVER
#              DENGAN KONFIGURASI RPZ (RESPONSE POLICY ZONE).
#              SCRIPT INI MENGUNDUH FILE KONFIGURASI BIND9 DAN
#              BINARY RPZ DARI REPOSITORI GITHUB, KEMUDIAN
#              MENGONFIGURASI CRON JOB UNTUK PEMBARUAN BERKALA.
# PEMBUAT    : HARRY DERTIN SUTISNA ALSYUNDAWY
# TANGGAL    : 24 JANUARI 2025
# DIPERBAIKI : 09 MAY 2026
# VERSI      : 2.0
# LISENSI    : MIT
# ============================================================

# [BARU] set -euo pipefail:
#   -e  ? Script berhenti otomatis jika ada perintah yang gagal
#   -u  ? Error jika variabel tidak terdefinisi (cegah typo variabel)
#   -o pipefail ? Pipeline dianggap gagal jika salah satu bagiannya gagal
set -euo pipefail

# ------------------------------------------------------------
# Warna untuk output terminal
# ------------------------------------------------------------
# [BARU] Semua variabel warna dijadikan readonly agar tidak bisa
#        diubah secara tidak sengaja selama eksekusi script.
# [PERBAIKAN] Escape sequence diperbaiki dari '\\033' ? '\033'
#             agar warna benar-benar tampil di terminal.
# [BARU] Ditambahkan warna RED untuk keperluan masa depan.
readonly CYAN='\033[1;36m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[1;32m'
readonly MAGENTA='\033[1;35m'
readonly RED='\033[1;31m'
readonly NC='\033[0m' # Reset warna

# ------------------------------------------------------------
# Konfigurasi direktori dan URL
# ------------------------------------------------------------
# [BARU] Semua variabel konfigurasi dijadikan readonly.
# [BARU] Ditambahkan LOG_FILE untuk menyimpan log ke file.
readonly BIND_DIR="/etc/bind"
readonly ZONES_DIR="${BIND_DIR}/zones"
readonly RPZ_BINARY="/usr/local/bin/rpz"
readonly LOG_FILE="/var/log/install_bind9_rpz.log"
readonly REPO_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind"
readonly RPZ_URL="https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/raw/refs/heads/main/rpz"

# Daftar file konfigurasi BIND yang akan diunduh
# [BARU] Ditambahkan readonly -a untuk array agar tidak bisa diubah
readonly -a CONFIG_FILES=(
    "named.conf.local"
    "named.conf.options"
    "zones/alsyundawy_safesearch.zones"
    "zones/alsyundawy_whitelist.zones"
)

# ============================================================
# FUNGSI UTILITAS
# ============================================================

# ------------------------------------------------------------
# [BARU] Sistem logging terpusat
# Semua output ditulis ke terminal (dengan warna) DAN ke file log
# dengan format: [YYYY-MM-DD HH:MM:SS] [LEVEL] pesan
# ------------------------------------------------------------
log() {
    local level="$1"
    local message="$2"
    local color="${3:-$NC}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${color}[${level}] ${message}${NC}"
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
}

# Menampilkan pesan informasi (warna cyan)
info() {
    log "INFO" "$1" "$CYAN"
}

# Menampilkan pesan peringatan (warna kuning)
warn() {
    log "WARN" "$1" "$YELLOW"
}

# Menampilkan pesan sukses (warna hijau)
success() {
    log "OK" "$1" "$GREEN"
}

# Menampilkan pesan error ke stderr dan menghentikan script
error_exit() {
    log "ERROR" "$1" "$MAGENTA"
    exit 1
}

# ------------------------------------------------------------
# Mengecek status exit perintah terakhir — fallback manual
# [CATATAN] Dengan set -e, fungsi ini hanya diperlukan dalam
#           konteks khusus (misal: di dalam blok if/while).
# ------------------------------------------------------------
check_status() {
    if [ "${PIPESTATUS[0]:-$?}" -ne 0 ]; then
        error_exit "$1"
    fi
}

# ------------------------------------------------------------
# Memeriksa apakah URL dapat diakses
# [PERBAIKAN] Ditambahkan --location agar mengikuti redirect HTTP/HTTPS
# [PERBAIKAN] Ditambahkan --max-time 15 agar tidak hang selamanya
# ------------------------------------------------------------
check_url() {
    local url="$1"
    info "Memeriksa URL: ${url}"
    if ! curl --head --silent --fail --location --max-time 15 "${url}" > /dev/null 2>&1; then
        error_exit "URL tidak dapat diakses atau tidak valid: ${url}"
    fi
}

# ------------------------------------------------------------
# Mengunduh file dari URL ke path tujuan
# [PERBAIKAN] Ditambahkan --timeout=30 dan --tries=3 untuk retry otomatis
# [BARU] Direktori tujuan dibuat otomatis jika belum ada (mkdir -p)
# ------------------------------------------------------------
download_file() {
    local url="$1"
    local destination="$2"
    local dir
    dir=$(dirname "${destination}")

    # Buat direktori tujuan jika belum ada
    mkdir -p "${dir}" || error_exit "Gagal membuat direktori: ${dir}"

    info "Mengunduh: ${url} ? ${destination}"
    if ! wget --continue --quiet --timeout=30 --tries=3 "${url}" -O "${destination}"; then
        error_exit "Gagal mengunduh file dari: ${url}"
    fi
}

# ------------------------------------------------------------
# Mengatur kepemilikan (chown) dan izin (chmod) file/direktori
# ------------------------------------------------------------
set_permissions() {
    local target="$1"
    local owner="$2"
    local permissions="$3"
    info "Mengatur izin ${permissions} dan kepemilikan ${owner} untuk: ${target}"
    chown "${owner}" "${target}" || error_exit "Gagal mengatur kepemilikan untuk: ${target}"
    chmod "${permissions}" "${target}" || error_exit "Gagal mengatur izin untuk: ${target}"
}

# ------------------------------------------------------------
# [BARU] Memastikan perintah/program tersedia sebelum digunakan
# Memberikan pesan error yang jelas jika dependensi tidak ada
# ------------------------------------------------------------
require_command() {
    local cmd="$1"
    if ! command -v "${cmd}" &> /dev/null; then
        error_exit "Perintah '${cmd}' tidak ditemukan. Pastikan sistem mendukung perintah ini."
    fi
}

# ============================================================
# FUNGSI TAHAPAN INSTALASI
# ============================================================

# ------------------------------------------------------------
# Pemeriksaan hak akses root
# [PERBAIKAN] Menggunakan exec sudo agar proses digantikan (bukan fork baru)
# [PERBAIKAN] exit 1 sebagai fallback jika exec gagal
# ------------------------------------------------------------
check_root() {
    if [ "${EUID}" -ne 0 ]; then
        warn "Script ini memerlukan hak akses root. Meminta elevasi dengan sudo..."
        exec sudo bash "$0" "$@"
        exit 1
    fi
}

# ------------------------------------------------------------
# [BARU] Banner informasi script yang tampil di awal eksekusi
# Menampilkan nama script, versi, pembuat, dan lokasi log
# ------------------------------------------------------------
show_banner() {
    echo -e "${CYAN}"
    echo "============================================================"
    echo "  BIND9 DNS Server + RPZ Installer"
    echo "  Pembuat : Alsyundawy"
    echo "  Tanggal : 24 Januari 2025 | Versi: 2.0"
    echo "  Log     : ${LOG_FILE}"
    echo "============================================================"
    echo -e "${NC}"
}

# ------------------------------------------------------------
# Memperbaiki entri hostname di /etc/hosts
# [PERBAIKAN] Menggunakan grep -qE dengan regex yang tepat untuk
#             mencocokkan format "127.0.0.1 <hostname>" secara akurat
#             (versi lama hanya grep -q yang bisa false positive)
# ------------------------------------------------------------
fix_hostname() {
    info "Memeriksa konfigurasi hostname di /etc/hosts..."
    local host
    host=$(hostname)
    if ! grep -qE "^\s*127\.0\.0\.1\s+${host}" /etc/hosts; then
        info "Menambahkan entri hostname '${host}' ke /etc/hosts..."
        echo "127.0.0.1 ${host}" >> /etc/hosts || error_exit "Gagal memperbarui /etc/hosts."
        success "Hostname '${host}' berhasil ditambahkan ke /etc/hosts."
    else
        success "Hostname '${host}' sudah terdaftar di /etc/hosts."
    fi
}

# ------------------------------------------------------------
# Memperbarui dan membersihkan sistem menggunakan apt
# [BARU] DEBIAN_FRONTEND=noninteractive mencegah prompt interaktif
#        yang bisa membekukan script di lingkungan non-GUI
# [PERBAIKAN] Flag -qq (quiet) mengurangi output verbose apt
# ------------------------------------------------------------
update_system() {
    info "Memperbarui daftar repositori..."
    apt-get update -qq || error_exit "Gagal memperbarui repositori apt."

    info "Melakukan upgrade paket..."
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq \
        || error_exit "Gagal melakukan upgrade paket."

    info "Melakukan dist-upgrade..."
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -qq \
        || error_exit "Gagal melakukan dist-upgrade."

    info "Membersihkan paket yang tidak terpakai..."
    apt-get --purge autoremove -y -qq
    apt-get clean -qq
    apt-get autoclean -qq

    info "Memperbaiki dependency yang rusak..."
    DEBIAN_FRONTEND=noninteractive apt-get install -f -y -qq \
        || error_exit "Gagal memperbaiki dependency."

    success "Sistem berhasil diperbarui dan dibersihkan."
}

# ------------------------------------------------------------
# Menginstal BIND9 dan dnsutils
# [BARU] DEBIAN_FRONTEND=noninteractive agar tidak ada prompt
# ------------------------------------------------------------
install_bind9() {
    info "Menginstal paket BIND9 dan dnsutils..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq bind9 bind9-dnsutils bind9-utils \
        || error_exit "Gagal menginstal bind9 dan dnsutils."
    success "BIND9 dan dnsutils berhasil diinstal."
}

# ------------------------------------------------------------
# Membuat direktori zones dan mengatur izin yang benar
# ------------------------------------------------------------
setup_zones_dir() {
    info "Memastikan direktori zones ada: ${ZONES_DIR}"
    mkdir -p "${ZONES_DIR}" || error_exit "Gagal membuat direktori: ${ZONES_DIR}"
    set_permissions "${ZONES_DIR}" "root:bind" "755"
    success "Direktori zones siap."
}

# ------------------------------------------------------------
# Mengunduh semua file konfigurasi BIND9 dari repositori
# File diunduh satu per satu, dicek URL-nya, lalu diatur izinnya
# ------------------------------------------------------------
download_bind_configs() {
    info "Mengunduh file konfigurasi BIND9 dari repositori..."
    for file in "${CONFIG_FILES[@]}"; do
        local destination="${BIND_DIR}/${file}"
        local url="${REPO_URL}/${file}"
        check_url "${url}"
        download_file "${url}" "${destination}"
        set_permissions "${destination}" "root:bind" "644"
        success "File '${file}' berhasil diunduh dan dikonfigurasi."
    done
}

# ------------------------------------------------------------
# Validasi sintaks konfigurasi BIND9 menggunakan named-checkconf
# [PERBAIKAN] Memberikan pesan error yang lebih informatif
#             dengan menyebut lokasi direktori konfigurasi
# ------------------------------------------------------------
validate_bind_config() {
    info "Memvalidasi konfigurasi BIND9 dengan named-checkconf..."
    if ! named-checkconf; then
        error_exit "Konfigurasi BIND9 tidak valid. Periksa file konfigurasi di ${BIND_DIR}."
    fi
    success "Konfigurasi BIND9 valid."
}

# ------------------------------------------------------------
# Menangani konflik port 53
# [BARU] Menggunakan ss sebagai pengganti modern netstat
# [BARU] Mendeteksi dan menonaktifkan systemd-resolved secara otomatis
#        (penyebab paling umum konflik port 53 di Ubuntu modern)
# [PERBAIKAN] fuser -k dijalankan dengan || true agar tidak trigger
#             set -e jika tidak ada proses yang dibunuh
# [BARU] sleep 2 memberi waktu sistem membebaskan port setelah kill
# ------------------------------------------------------------
handle_port53() {
    info "Memeriksa apakah port 53 sedang digunakan..."
    # ss adalah pengganti modern netstat; fallback ke netstat jika ss tidak ada
    if ss -tuln 2>/dev/null | grep -q ':53 ' || \
       netstat -tuln 2>/dev/null | grep -q ':53 '; then

        warn "Port 53 sedang digunakan. Menghentikan proses yang menempati port 53..."

        # Tangani systemd-resolved (penyebab umum di Ubuntu 18.04+)
        if systemctl is-active --quiet systemd-resolved; then
            systemctl stop systemd-resolved
            systemctl disable systemd-resolved
            warn "systemd-resolved dihentikan dan dinonaktifkan."
        fi

        # Paksa kosongkan port 53 jika masih ada proses lain
        fuser -k 53/udp 2>/dev/null || true
        fuser -k 53/tcp 2>/dev/null || true
        sleep 2
        success "Port 53 berhasil dikosongkan."
    else
        success "Port 53 tidak digunakan oleh proses lain."
    fi
}

# ------------------------------------------------------------
# Menjalankan ulang dan mengaktifkan layanan BIND9
# [BARU] Ditambahkan systemctl enable agar BIND9 otomatis aktif
#        saat sistem reboot (versi lama tidak menjamin ini)
# ------------------------------------------------------------
restart_bind9() {
    info "Menjalankan ulang layanan BIND9 (named)..."
    systemctl restart named || error_exit "Gagal menjalankan ulang layanan BIND9."
    systemctl enable named --quiet
    success "Layanan BIND9 berhasil dijalankan ulang dan diaktifkan saat boot."
}

# ------------------------------------------------------------
# Mengunduh binary RPZ dan mengatur izin eksekusi
# ------------------------------------------------------------
setup_rpz_binary() {
    info "Mengunduh binary RPZ dari repositori..."
    check_url "${RPZ_URL}"
    download_file "${RPZ_URL}" "${RPZ_BINARY}"
    set_permissions "${RPZ_BINARY}" "root:root" "755"
    success "Binary RPZ berhasil diunduh ke: ${RPZ_BINARY}"
}

# ------------------------------------------------------------
# Menambahkan cron job pembaruan RPZ setiap 12 jam
# [BARU] Cek duplikasi sebelum menambah — script aman dijalankan
#        berulang kali tanpa membuat cron entry ganda
# [PERBAIKAN] Output cron diarahkan ke LOG_FILE (bukan /dev/null)
#             sehingga hasil eksekusi terjadwal bisa dimonitor
# ------------------------------------------------------------
setup_cron() {
    info "Mengonfigurasi cron job pembaruan RPZ setiap 12 jam..."
    local cron_entry="0 */12 * * * ${RPZ_BINARY} >> ${LOG_FILE} 2>&1"

    if crontab -l 2>/dev/null | grep -qF "${RPZ_BINARY}"; then
        warn "Cron job untuk RPZ sudah ada. Melewati langkah ini."
    else
        ( crontab -l 2>/dev/null; echo "${cron_entry}" ) | crontab -
        success "Cron job berhasil ditambahkan: ${cron_entry}"
    fi
}

# ------------------------------------------------------------
# Menjalankan binary RPZ untuk pertama kali setelah instalasi
# ------------------------------------------------------------
run_rpz() {
    info "Menjalankan binary RPZ untuk pertama kali..."
    "${RPZ_BINARY}" || error_exit "Gagal menjalankan binary RPZ: ${RPZ_BINARY}"
    success "Binary RPZ berhasil dijalankan."
}

# ============================================================
# FUNGSI UTAMA — Orkestrasi seluruh tahapan instalasi
# ============================================================
main() {
    # Inisialisasi file log (buat direktori jika belum ada)
    mkdir -p "$(dirname "${LOG_FILE}")"
    touch "${LOG_FILE}"

    # Pastikan script berjalan sebagai root
    check_root "$@"

    # Tampilkan banner
    show_banner

    # [BARU] Verifikasi dependensi awal sebelum mulai eksekusi
    require_command curl
    require_command wget
    require_command apt-get
    require_command systemctl

    # Jalankan setiap tahapan secara berurutan
    fix_hostname
    update_system
    install_bind9
    setup_zones_dir
    download_bind_configs
    validate_bind_config
    handle_port53
    restart_bind9
    setup_rpz_binary
    setup_cron
    run_rpz

    echo ""
    success "============================================================"
    success " Instalasi dan konfigurasi BIND9 + RPZ selesai dengan sukses!"
    success " Log tersimpan di: ${LOG_FILE}"
    success "============================================================"
}

# Panggil fungsi utama dan teruskan semua argumen script
main "$@"