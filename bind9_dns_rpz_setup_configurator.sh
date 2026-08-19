#!/usr/bin/env bash

# ============================================================
# Nama       : INSTALL_BIND9_RPZ_SETUP_CONFIGURATOR.SH
# Deskripsi  : Skrip otomasi komprehensif untuk instalasi dan konfigurasi
#              BIND9 DNS Server terintegrasi dengan Response Policy Zone (RPZ).
#              Fitur utama meliputi:
#              - Deteksi OS (Ubuntu 22.04+ / Debian 11+) & tipe virtualisasi.
#              - Penanganan konflik Port 53 secara aman & idempoten.
#              - Pilihan multi-sumber sinkronisasi database RPZ (Alsyundawy / Komdigi / GitHub).
#              - Unduhan konfigurasi, binary RPZ, dan penjadwalan pembaruan (12 jam).
#              - Validasi konfigurasi BIND sebelum reload.
#              - Pemuatan ulang RPZ menggunakan rndc reload setelah RPZ berjalan.
#              - Perbaikan struktur jaringan dasar melalui /etc/resolv.conf.
# Penulis    : Harry Dertin Sutisna Alsyundawy
# Kontak     : alsyundawy@gmail.com, +628568515212 (WhatsApp/Telegram/Call)
# Homepage   : https://alsyundawy.com
# Repositori : https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary
# Dibuat     : 24 Januari 2025
# Diperbarui : 20 Agustus 2026
# Versi      : 2.5
# Lisensi    : MIT
# ============================================================
#
# DOCNOTE v2.5:
# - Default database RPZ dialihkan ke ALSYUNDAWY DATABASE (rpz-alsyundawy-database).
# - Nama file database RPZ sumber GitHub disesuaikan menjadi rpz-github-database.
# - Seluruh opsi sumber database (Alsyundawy / Komdigi / GitHub) otomatis disimpan dan dinamai sebagai binary lokal /usr/local/bin/rpz.
# - Skrip dibuat 100% idempoten; aman dijalankan ulang berkali-kali tanpa error konflik port.
# - Penanganan Port 53 kini mencakup penghentian sementara named/bind9 jika sudah berjalan saat konfigurasi ulang.
# - Pengunduhan konfigurasi BIND dilakukan secara atomik tanpa menghapus file target sebelumnya untuk mencegah data loss saat koneksi gagal.
# - Sistem trap pembersihan file sementara (cleanup trap) ditambahkan untuk menangani interupsi (SIGINT/SIGTERM/EXIT/ERR).
# - Deteksi OS diperluas untuk mendukung Debian Trixie (13+), Forky (14+), sid, serta Ubuntu 24.04+ dan 26.04+.
# - Virtualisasi KVM/QEMU dan VMware kini otomatis mengaktifkan (systemctl enable --now) guest agent terkait.
# - Deteksi entri hostname di /etc/hosts kini mengenali pola 127.0.1.1 bawaan Debian/Ubuntu.
# - Penanganan non-interaktif ditambahkan pada input read agar aman dijalankan via CI/CD, Ansible, atau Cloud-Init.
# - Auto-generate /etc/bind/rndc.key ditambahkan jika berkas kunci belum tersedia.
#
# CHANGELOG v2.5:
# - FEATURE : Pengalihan default database RPZ ke ALSYUNDAWY DATABASE (rpz-alsyundawy-database).
# - REFACTOR: Penyesuaian nama endpoint database GitHub menjadi rpz-github-database.
# - REFACTOR: Standardisasi penyimpanan seluruh varian database menjadi binary /usr/local/bin/rpz.
# - FIX     : Idempotensi handle_port53 diperbaiki agar tidak memblokir eksekusi saat named/bind9 sudah aktif.
# - FIX     : Potensi data loss pada download_bind_configs dihapus (tidak lagi menghapus file tujuan sebelum unduhan selesai).
# - FIX     : Deteksi Debian sid/testing tanpa VERSION_ID numerik ditangani dengan aman.
# - FIX     : fix_hostname kini mengenali entri 127.0.1.1 bawaan Debian/Ubuntu agar tidak membuat duplikasi.
# - FIX     : Deteksi TTY pada perintah read agar tidak gagal saat dieksekusi secara non-interaktif.
# - SECURITY: Penambahan trap pembersihan (cleanup handler) untuk seluruh file sementara mktemp.
# - SECURITY: Otomatisasi verifikasi & pembuatan /etc/bind/rndc.key dengan permission 640 (root:bind).
# - SECURITY: Standarisasi izin berkas /etc/resolv.conf ke 644 (root:root) setelah modifikasi.
# - OPTIMIZE: Aktivasi langsung open-vm-tools dan qemu-guest-agent via systemctl enable --now.
# - OPTIMIZE: Pengaturan set -Eeuo pipefail untuk inheritance trap pada subshell/fungsi.
#
# ============================================================

# Pengaturan keamanan eksekusi:
#   -E          : fungsi dan subshell mewarisi trap ERR
#   -e          : hentikan skrip jika ada perintah yang gagal
#   -u          : cegah penggunaan variabel yang belum diatur
#   -o pipefail : pipeline gagal jika salah satu bagian gagal
set -Eeuo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------
# Variabel warna untuk output terminal (dinonaktifkan jika non-TTY)
# ------------------------------------------------------------
if [ -t 1 ]; then
    readonly CYAN='\033[1;36m'
    readonly YELLOW='\033[1;33m'
    readonly GREEN='\033[1;32m'
    readonly MAGENTA='\033[1;35m'
    readonly RED='\033[1;31m'
    readonly NC='\033[0m'
else
    readonly CYAN=''
    readonly YELLOW=''
    readonly GREEN=''
    readonly MAGENTA=''
    readonly RED=''
    readonly NC=''
fi

# ------------------------------------------------------------
# Lokasi direktori dan URL yang digunakan
# ------------------------------------------------------------
readonly BIND_DIR="/etc/bind"
readonly ZONES_DIR="${BIND_DIR}/zones"
readonly RPZ_BINARY="/usr/local/bin/rpz"
readonly LOG_FILE="/var/log/install_bind9_rpz.log"
readonly REPO_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind"
RPZ_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/rpz-alsyundawy-database"

# Daftar berkas konfigurasi yang akan diambil dari repositori
readonly -a CONFIG_FILES=(
    "named.conf.local"
    "named.conf.options"
    "zones/alsyundawy_safesearch.zones"
    "zones/alsyundawy_whitelist.zones"
)

# Opsi APT non-interaktif yang tetap mempertahankan konfigurasi lokal lama bila ada konflik.
readonly -a APT_OPTS=(
    -y
    -qq
    -o Dpkg::Options::=--force-confdef
    -o Dpkg::Options::=--force-confold
)

# Array penampung file sementara untuk pembersihan otomatis via trap
declare -a TEMP_FILES=()

cleanup_temp_files() {
    local status=$?
    for tmp in "${TEMP_FILES[@]}"; do
        if [ -n "${tmp}" ] && [ -e "${tmp}" ]; then
            rm -rf "${tmp}" 2>/dev/null || true
        fi
    done
    if [ "${status}" -ne 0 ] && [ "${status}" -ne 130 ]; then
        printf '\n%b[ERROR]%b Terjadi kegagalan pada skrip (Exit code: %d). Silakan periksa log: %s\n' "${RED}" "${NC}" "${status}" "${LOG_FILE}" >&2
    fi
}

trap cleanup_temp_files EXIT
trap 'exit 130' INT TERM

# ============================================================
# Fungsi bantuan (logging dan validasi)
# ============================================================

log() {
    local level="$1"
    local message="$2"
    local color="${3:-$NC}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [ "${level}" = "ERROR" ]; then
        printf '%b[%s]%b %s\n' "${color}" "${level}" "${NC}" "${message}" >&2
    else
        printf '%b[%s]%b %s\n' "${color}" "${level}" "${NC}" "${message}"
    fi

    printf '[%s] [%s] %s\n' "${timestamp}" "${level}" "${message}" >> "${LOG_FILE}" 2>/dev/null || true
}

info()    { log "INFO" "$1" "$CYAN"; }
warn()    { log "WARN" "$1" "$YELLOW"; }
success() { log "OK"   "$1" "$GREEN"; }
error_exit() {
    log "ERROR" "$1" "$MAGENTA"
    exit 1
}

backup_file() {
    local target="$1"
    if [ -e "${target}" ] || [ -L "${target}" ]; then
        local backup
        backup="${target}.bak.$(date '+%Y%m%d-%H%M%S')"
        cp -a "${target}" "${backup}" || error_exit "Gagal membuat backup: ${backup}"
        success "Backup dibuat: ${backup}"
    fi
}

check_url() {
    local url="$1"
    info "Memeriksa URL: ${url}"

    if curl --head --silent --fail --location --connect-timeout 10 --max-time 20 "${url}" > /dev/null 2>&1; then
        return 0
    fi

    # Fallback untuk endpoint yang menolak HTTP HEAD tetapi menerima GET.
    if curl --silent --fail --location --connect-timeout 10 --max-time 20 --range 0-0 "${url}" > /dev/null 2>&1; then
        return 0
    fi

    error_exit "URL tidak dapat diakses atau tidak valid: ${url}"
}

download_file() {
    local url="$1"
    local destination="$2"
    local dir
    local tmp_file

    dir=$(dirname "${destination}")
    mkdir -p "${dir}" || error_exit "Gagal membuat direktori: ${dir}"

    tmp_file=$(mktemp "${dir}/.download.XXXXXX") || error_exit "Gagal membuat file sementara di: ${dir}"
    TEMP_FILES+=("${tmp_file}")

    info "Mengunduh: ${url} -> ${destination}"

    if ! wget --quiet --timeout=30 --tries=3 "${url}" -O "${tmp_file}"; then
        # Fallback ke curl jika wget gagal
        if ! curl --silent --fail --location --connect-timeout 15 --max-time 60 "${url}" -o "${tmp_file}"; then
            rm -f "${tmp_file}"
            error_exit "Gagal mengunduh file dari: ${url}"
        fi
    fi

    if [ ! -s "${tmp_file}" ]; then
        rm -f "${tmp_file}"
        error_exit "File hasil unduhan kosong: ${url}"
    fi

    mv -f "${tmp_file}" "${destination}" || {
        rm -f "${tmp_file}"
        error_exit "Gagal memindahkan file sementara ke: ${destination}"
    }
}

set_permissions() {
    local target="$1"
    local owner="$2"
    local permissions="$3"

    info "Mengatur izin ${permissions} dan kepemilikan ${owner} untuk: ${target}"
    chown "${owner}" "${target}"       || error_exit "Gagal mengatur kepemilikan untuk: ${target}"
    chmod "${permissions}" "${target}" || error_exit "Gagal mengatur izin untuk: ${target}"
}

# ============================================================
# Pemasangan dependensi otomatis
# ============================================================

ensure_command() {
    local cmd="$1"
    local pkg="$2"

    if command -v "${cmd}" > /dev/null 2>&1; then
        info "Perintah '${cmd}' tersedia."
        return 0
    fi

    warn "Perintah '${cmd}' tidak ditemukan. Akan diinstal dari paket '${pkg}'..."
    apt-get "${APT_OPTS[@]}" install "${pkg}" || \
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
    ensure_command "fuser"     "psmisc"
    ensure_command "crontab"   "cron"
}

# ============================================================
# Validasi sistem operasi
# ============================================================

check_os_version() {
    if [ ! -f /etc/os-release ]; then
        warn "Tidak dapat mendeteksi distribusi (/etc/os-release tidak ada). Melanjutkan dengan asumsi kompatibel..."
        return
    fi

    # shellcheck disable=SC1091
    . /etc/os-release

    local os_id="${ID:-unknown}"
    local version_id="${VERSION_ID:-}"
    local major_version="${version_id%%.*}"

    case "${os_id}" in
        debian)
            if [ -z "${major_version}" ] || ! [[ "${major_version}" =~ ^[0-9]+$ ]]; then
                # Penanganan Debian testing/sid atau rolling release
                local codename="${VERSION_CODENAME:-unknown}"
                warn "Debian rolling/testing (${codename}) terdeteksi. Memenuhi syarat."
                return 0
            fi

            if [ "${major_version}" -lt 11 ]; then
                error_exit "Debian versi ${version_id} tidak didukung. Minimal Debian 11 (Bullseye). Debian 10 ke bawah ditolak."
            fi
            if [ "${major_version}" -lt 12 ]; then
                warn "Debian ${version_id} (Bullseye) terdeteksi. Didukung, namun disarankan Debian 12 (Bookworm) atau Debian 13 (Trixie) ke atas."
            else
                success "Debian ${version_id} memenuhi syarat."
            fi
            ;;
        ubuntu)
            if [ -z "${major_version}" ] || ! [[ "${major_version}" =~ ^[0-9]+$ ]]; then
                error_exit "Ubuntu VERSION_ID tidak valid atau tidak terbaca: ${version_id}"
            fi

            if [ "${major_version}" -lt 22 ]; then
                error_exit "Ubuntu versi ${version_id} tidak didukung. Minimal Ubuntu 22.04 LTS (Jammy). Rekomendasi Ubuntu 24.04 LTS atau lebih tinggi."
            fi
            if [ "${major_version}" -lt 24 ]; then
                warn "Ubuntu ${version_id} terdeteksi. Didukung, namun rekomendasi operasional adalah Ubuntu 24.04 LTS ke atas untuk BIND 9.18+."
            else
                success "Ubuntu ${version_id} memenuhi syarat."
            fi
            ;;
        *)
            error_exit "Distribusi '${os_id}' tidak didukung. Skrip ini hanya mendukung Debian 11+ dan Ubuntu 22.04+."
            ;;
    esac
}

# ============================================================
# Deteksi virtualisasi dan instalasi guest tools
# ============================================================

detect_virtualization() {
    info "Mendeteksi lingkungan virtualisasi..."
    local virt=""

    # Cek menggunakan systemd-detect-virt jika tersedia.
    if command -v systemd-detect-virt > /dev/null 2>&1; then
        virt=$(systemd-detect-virt 2>/dev/null || true)
        if [ "${virt}" = "none" ]; then
            virt=""
        fi
    fi

    # Jika tidak terdeteksi, coba baca dari DMI.
    if [ -z "${virt}" ] && [ -f /sys/class/dmi/id/product_name ]; then
        local product
        product=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
        case "${product,,}" in
            *vmware*)     virt="vmware" ;;
            *kvm*|*qemu*) virt="kvm" ;;
            *proxmox*)    virt="kvm" ;;
        esac
    fi

    if [ -z "${virt}" ] && command -v lscpu > /dev/null 2>&1; then
        local lscpu_out
        lscpu_out=$(lscpu 2>/dev/null || true)
        if printf '%s\n' "${lscpu_out}" | grep -qi "hypervisor vendor"; then
            local hv
            hv=$(printf '%s\n' "${lscpu_out}" | awk -F: 'tolower($1) ~ /hypervisor vendor/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit}')
            case "${hv,,}" in
                *vmware*) virt="vmware" ;;
                *kvm*|*qemu*) virt="kvm" ;;
            esac
        fi
    fi

    case "${virt}" in
        vmware)
            success "Terdeteksi VMware. Memasang dan mengaktifkan open-vm-tools..."
            apt-get "${APT_OPTS[@]}" install open-vm-tools || \
                warn "Gagal memasang open-vm-tools, lanjut tanpa tools tamu."
            systemctl enable --now open-vm-tools > /dev/null 2>&1 || true
            ;;
        kvm|qemu|bochs)
            success "Terdeteksi KVM/QEMU/Proxmox. Memasang dan mengaktifkan qemu-guest-agent..."
            apt-get "${APT_OPTS[@]}" install qemu-guest-agent || \
                warn "Gagal memasang qemu-guest-agent, lanjut tanpa agen tamu."
            systemctl enable --now qemu-guest-agent > /dev/null 2>&1 || true
            ;;
        *)
            success "Mesin fisik (baremetal) atau tipe virtualisasi umum tidak memerlukan guest tools khusus."
            ;;
    esac
}

# ============================================================
# Pemilihan sumber RPZ
# ============================================================

choose_rpz_source() {
    echo ""
    info "PILIH SUMBER DATABASE RPZ YANG AKAN DIGUNAKAN:"
    info "  1) ALSYUNDAWY DATABASE (DEFAULT)"
    info "  2) KOMDIGI"
    info "  3) GITHUB"

    local rpz_choice=""
    if [ -t 0 ] && [ -r /dev/tty ]; then
        read -rp "Masukkan pilihan [1/2/3, default: 1]: " rpz_choice < /dev/tty 2>/dev/null || rpz_choice="1"
    else
        rpz_choice="1"
    fi
    rpz_choice="${rpz_choice:-1}"

    case "${rpz_choice}" in
        2)
            info "MENGGUNAKAN DATABASE RPZ DARI KOMDIGI."
            RPZ_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/rpz-komdigi-database"
            ;;
        3)
            info "MENGGUNAKAN DATABASE RPZ DARI GITHUB."
            RPZ_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/rpz-github-database"
            ;;
        *)
            info "MENGGUNAKAN DATABASE RPZ DARI ALSYUNDAWY DATABASE (DEFAULT)."
            RPZ_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/rpz-alsyundawy-database"
            ;;
    esac
}

# ============================================================
# Tahapan instalasi dan konfigurasi
# ============================================================

check_root() {
    if [ "${EUID}" -ne 0 ]; then
        if ! command -v sudo > /dev/null 2>&1; then
            printf 'ERROR: Skrip ini memerlukan hak akses root dan sudo tidak tersedia. Jalankan sebagai root.\n' >&2
            exit 1
        fi
        warn "Skrip ini memerlukan hak akses root. Meminta elevasi via sudo..."
        exec sudo -E bash "${BASH_SOURCE[0]}" "$@"
    fi
}

show_banner() {
    local script_name="INSTALL_BIND9_RPZ_SETUP_CONFIGURATOR.SH"
    local os_info="Unknown OS"
    local kernel_info

    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        os_info=$(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-Unknown OS}")
    fi
    kernel_info=$(uname -r)

    printf '%b' "${MAGENTA}"
    echo "============================================================"
    echo "  PROGRAM : BIND9 DNS Server + RPZ Installer & Configurator"
    echo "  SCRIPT  : ${script_name}"
    echo "  DESC    : Skrip otomasi instalasi & konfigurasi BIND9"
    echo "            terintegrasi RPZ dengan dukungan multi-sumber,"
    echo "            penanganan port 53, setup resolv.conf,"
    echo "            auto-reload layanan setelah RPZ berjalan,"
    echo "            deteksi OS (Ubuntu 22.04+ / Debian 11+),"
    echo "            dan tipe virtualisasi."
    echo "------------------------------------------------------------"
    echo "  AUTHOR  : Harry Dertin Sutisna Alsyundawy"
    echo "  LICENSE : MIT License (Free & Open Source)"
    echo "  REPOS   : github.com/alsyundawy/TrustPositif-To-RPZ-Binary"
    echo "------------------------------------------------------------"
    echo "  CONTACT : alsyundawy@gmail.com"
    echo "            +628568515212 (WhatsApp/Telegram/Call)"
    echo "  HOMEPAGE: https://alsyundawy.com"
    echo "------------------------------------------------------------"
    echo "  VERSION : 2.5"
    echo "  UPDATED : 20 Agustus 2026"
    echo "  CREATED : 24 Januari 2025"
    echo "  TARGET  : Debian >=11, Ubuntu >=22.04, BIND9 + RPZ"
    echo "------------------------------------------------------------"
    echo "  SYSTEM  : ${os_info}"
    echo "  KERNEL  : ${kernel_info}"
    echo "  LOGFILE : ${LOG_FILE}"
    echo "============================================================"
    printf '%b\n' "${NC}"
}

fix_hostname() {
    info "Memeriksa entri hostname di /etc/hosts..."
    local host
    host=$(hostname 2>/dev/null || uname -n)

    if [ -z "${host}" ]; then
        warn "Hostname tidak dapat ditentukan. Melewati fix_hostname."
        return 0
    fi

    # Cek apakah hostname sudah ada di mapping 127.0.0.1 atau 127.0.1.1
    if ! awk -v h="${host}" '($1 == "127.0.0.1" || $1 == "127.0.1.1") { for (i = 2; i <= NF; i++) if ($i == h) found = 1 } END { exit found ? 0 : 1 }' /etc/hosts 2>/dev/null; then
        info "Menambahkan hostname '${host}' ke /etc/hosts..."
        printf '127.0.0.1 %s\n' "${host}" >> /etc/hosts || error_exit "Gagal memperbarui /etc/hosts."
        success "Hostname '${host}' berhasil ditambahkan ke /etc/hosts."
    else
        success "Hostname '${host}' sudah ada di /etc/hosts."
    fi
}

update_system() {
    info "Memperbarui daftar repositori..."
    apt-get update -qq || error_exit "Gagal memperbarui repositori apt."

    info "Memperbarui paket yang terinstal..."
    apt-get "${APT_OPTS[@]}" upgrade || error_exit "Gagal melakukan upgrade."

    info "Distribusi upgrade (jika diperlukan)..."
    apt-get "${APT_OPTS[@]}" dist-upgrade || error_exit "Gagal melakukan dist-upgrade."

    info "Membersihkan paket tidak terpakai..."
    apt-get "${APT_OPTS[@]}" --purge autoremove
    apt-get clean -qq
    apt-get autoclean -qq

    info "Memeriksa dan memperbaiki dependensi..."
    apt-get "${APT_OPTS[@]}" install -f || error_exit "Gagal memperbaiki dependensi."

    success "Sistem berhasil diperbarui."
}

install_bind9() {
    info "Menginstal paket BIND9, alat bantu, dan utilitas jaringan..."
    
    # Paket inti BIND9 dan diagnostik DNS
    local -a core_pkgs=(
        bind9
        bind9-dnsutils
        bind9-utils
    )

    # Paket pendukung dan utilitas jaringan
    local -a util_pkgs=(
        bc
        git
        htop
        iftop
        telnet
        traceroute
        rsync
        screen
        whois
        fping
        ipcalc
        idn2
        libidn2-0
    )

    apt-get "${APT_OPTS[@]}" install "${core_pkgs[@]}" "${util_pkgs[@]}" || {
        warn "Pemasangan gabungan gagal, mencoba memasang paket inti BIND9 terlebih dahulu..."
        apt-get "${APT_OPTS[@]}" install "${core_pkgs[@]}" || error_exit "Gagal menginstal paket inti BIND9."
        apt-get "${APT_OPTS[@]}" install "${util_pkgs[@]}" || warn "Beberapa utilitas sekunder tidak dapat diinstal."
    }

    success "Semua paket BIND9 dan utilitas siap."
}

setup_zones_dir() {
    info "Menyiapkan direktori zone: ${ZONES_DIR}"
    mkdir -p "${ZONES_DIR}" || error_exit "Gagal membuat direktori: ${ZONES_DIR}"
    set_permissions "${ZONES_DIR}" "root:bind" "755"

    # Verifikasi keberadaan rndc.key; buat baru jika belum ada
    if [ ! -f "${BIND_DIR}/rndc.key" ] && command -v rndc-confgen > /dev/null 2>&1; then
        info "Berkas rndc.key tidak ditemukan. Membuat kunci RNDC otomatis..."
        rndc-confgen -a -r /dev/urandom > /dev/null 2>&1 || true
        if [ -f "${BIND_DIR}/rndc.key" ]; then
            set_permissions "${BIND_DIR}/rndc.key" "root:bind" "640"
        fi
    fi

    success "Direktori zone siap."
}

download_bind_configs() {
    info "Mengambil file konfigurasi BIND9 dari repositori..."
    for file in "${CONFIG_FILES[@]}"; do
        local destination="${BIND_DIR}/${file}"
        local url="${REPO_URL}/${file}"

        if [[ "${file}" == "named.conf.local" || "${file}" == "named.conf.options" ]]; then
            backup_file "${destination}"
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

validate_bind_config_with_zones() {
    info "Memvalidasi konfigurasi BIND dan test-load zone primary..."
    if ! named-checkconf -z; then
        error_exit "Konfigurasi BIND9 atau zone tidak valid. Periksa konfigurasi dan file zone di ${BIND_DIR}."
    fi
    success "Konfigurasi BIND9 dan zone valid."
}

port53_in_use() {
    if ss -tuln 2>/dev/null | grep -qE '(^|[[:space:]])(tcp|udp).*:53[[:space:]]'; then
        return 0
    fi
    return 1
}

show_port53_users() {
    warn "Daftar proses/listener port 53 saat ini:"
    ss -tulpen 2>/dev/null | grep -E '(^|[[:space:]])(tcp|udp).*:53[[:space:]]' || true
}

handle_port53() {
    info "Memeriksa port 53..."
    if ! port53_in_use; then
        success "Port 53 tersedia."
        return 0
    fi

    warn "Port 53 sedang dipakai. Menyiapkan layanan DNS untuk konfigurasi bersih..."
    show_port53_users

    # Tangani layanan DNS konflik, termasuk named/bind9 jika re-run skrip
    local svc
    for svc in systemd-resolved dnsmasq unbound named bind9; do
        if systemctl list-unit-files "${svc}.service" > /dev/null 2>&1 && systemctl is-active --quiet "${svc}.service"; then
            if [[ "${svc}" == "named" || "${svc}" == "bind9" ]]; then
                info "Menghentikan sementara ${svc}.service untuk persiapan instalasi ulang..."
                systemctl stop "${svc}.service" || warn "Gagal menghentikan ${svc}.service"
            else
                systemctl stop "${svc}.service" || warn "Gagal menghentikan ${svc}.service"
                systemctl disable "${svc}.service" --quiet || warn "Gagal menonaktifkan ${svc}.service"
                warn "${svc}.service dihentikan dan dinonaktifkan."
            fi
        fi
    done

    sleep 2

    if port53_in_use; then
        show_port53_users
        error_exit "Port 53 masih dipakai oleh proses lain. Hentikan proses tersebut secara manual agar BIND9 dapat bind ke port 53."
    fi

    success "Port 53 berhasil dibersihkan dan siap digunakan."
}

get_bind_service() {
    if systemctl list-unit-files named.service > /dev/null 2>&1; then
        printf 'named'
        return 0
    fi
    if systemctl list-unit-files bind9.service > /dev/null 2>&1; then
        printf 'bind9'
        return 0
    fi
    printf 'named'
}

restart_bind9() {
    local bind_service
    bind_service=$(get_bind_service)

    info "Menyalakan ulang BIND9 (${bind_service})..."
    systemctl restart "${bind_service}" || error_exit "Gagal menjalankan BIND9 melalui service ${bind_service}."
    systemctl enable "${bind_service}" --quiet || error_exit "Gagal mengaktifkan ${bind_service} saat boot."

    if ! systemctl is-active --quiet "${bind_service}"; then
        error_exit "Service ${bind_service} tidak aktif setelah restart."
    fi

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
    local rndc_cmd
    local cron_entry
    local tmp_cron

    rndc_cmd=$(command -v rndc 2>/dev/null || printf '/usr/sbin/rndc')
    cron_entry="0 */12 * * * ${RPZ_BINARY} >> ${LOG_FILE} 2>&1 && ${rndc_cmd} reload >> ${LOG_FILE} 2>&1"
    
    tmp_cron=$(mktemp) || error_exit "Gagal membuat file sementara cron."
    TEMP_FILES+=("${tmp_cron}")

    { crontab -l 2>/dev/null || true; } | grep -vF "${RPZ_BINARY}" > "${tmp_cron}" || true
    printf '%s\n' "${cron_entry}" >> "${tmp_cron}"

    crontab "${tmp_cron}" || {
        rm -f "${tmp_cron}"
        error_exit "Gagal menambahkan cron job."
    }
    rm -f "${tmp_cron}"

    success "Cron job berhasil diset: ${cron_entry}"
}

configure_resolv_conf() {
    info "Mengonfigurasi /etc/resolv.conf untuk menggunakan 127.0.0.1 di urutan pertama..."
    backup_file "/etc/resolv.conf"

    if [ -L /etc/resolv.conf ]; then
        warn "/etc/resolv.conf adalah symlink, menggantinya dengan file reguler..."
        local real_file
        real_file=$(readlink -f /etc/resolv.conf || true)
        rm -f /etc/resolv.conf
        if [ -n "${real_file}" ] && [ -f "${real_file}" ]; then
            cp "${real_file}" /etc/resolv.conf
        else
            touch /etc/resolv.conf
        fi
    fi

    # Hapus entri 127.0.0.1 lama jika ada
    sed -i '/^[[:space:]]*nameserver[[:space:]]*127\.0\.0\.1[[:space:]]*$/d' /etc/resolv.conf 2>/dev/null || true

    local tmp_resolv
    tmp_resolv=$(mktemp) || error_exit "Gagal membuat file sementara resolv.conf."
    TEMP_FILES+=("${tmp_resolv}")

    printf 'nameserver 127.0.0.1\n' > "${tmp_resolv}"
    cat /etc/resolv.conf >> "${tmp_resolv}" 2>/dev/null || true
    cat "${tmp_resolv}" > /etc/resolv.conf
    rm -f "${tmp_resolv}"

    set_permissions "/etc/resolv.conf" "root:root" "644"
    success "nameserver 127.0.0.1 berhasil ditambahkan di awal baris /etc/resolv.conf."
}

run_rpz() {
    info "Menjalankan RPZ untuk sinkronisasi awal..."
    "${RPZ_BINARY}" || error_exit "Gagal menjalankan binary RPZ: ${RPZ_BINARY}"

    validate_bind_config_with_zones

    info "Menjalankan rndc reload setelah RPZ berjalan..."
    rndc reload || error_exit "Gagal menjalankan rndc reload setelah RPZ."
    success "RPZ berhasil dijalankan dan BIND berhasil di-reload."
}

# ============================================================
# Jalur utama skrip
# ============================================================

main() {
    check_root "$@"

    mkdir -p "$(dirname "${LOG_FILE}")"
    touch "${LOG_FILE}"

    show_banner
    choose_rpz_source

    if ! command -v apt-get > /dev/null 2>&1; then
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

    # Konfirmasi menjalankan RPZ.
    echo ""
    info "Proses instalasi selesai. Apakah Anda ingin langsung menjalankan binary RPZ sekarang?"
    local answer=""
    if [ -t 0 ] && [ -r /dev/tty ]; then
        read -rp "    Jalankan RPZ? [Y/n] " answer < /dev/tty 2>/dev/null || answer="y"
    else
        answer="y"
    fi
    answer="${answer:-y}"

    case "${answer:0:1}" in
        y|Y|"")
            run_rpz
            ;;
        *)
            info "RPZ tidak dijalankan saat ini. Anda dapat menjalankannya nanti dengan perintah:"
            info "  ${RPZ_BINARY} && rndc reload"
            ;;
    esac

    echo ""
    info "Tips pengujian DNS dengan nslookup / dig:"
    info "  - Uji dari server ini:  dig @127.0.0.1 google.com +short"
    info "  - Uji dari klien    :  dig @<alamat-IP-server> google.com +short"
    info "  - Uji blokir RPZ    :  dig @127.0.0.1 pornhub.com +short"
    info "  - Uji blokir klien  :  dig @<alamat-IP-server> pornhub.com +short"
    info "  Jika domain diblokir RPZ, respon akan dialihkan ke IP sinkhole atau NXDOMAIN."
    info "  Pastikan klien diarahkan ke DNS server ini agar RPZ aktif."
}

main "$@"
