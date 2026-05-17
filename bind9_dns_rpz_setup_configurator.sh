#!/usr/bin/env bash

# ============================================================
# Nama       : INSTALL_BIND9_RPZ_SETUP_CONFIGURATOR.SH
# Deskripsi  : Instalasi dan konfigurasi BIND9 sebagai DNS server
#              yang dilengkapi Response Policy Zone (RPZ).
#              Skrip mengunduh berkas konfigurasi dan binary RPZ
#              dari repositori, lalu menyiapkan cron job agar
#              pembaruan berjalan otomatis setiap 12 jam.
#              Dirancang untuk BIND versi 9.18 ke atas.
# Penulis    : Harry Dertin Sutisna Alsyundawy
# Kontak     : alsyundawy@gmail.com, +628568515212 (WhatsApp/Telegram/Call)
# Homepage   : https://alsyundawy.com
# Repositori : https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary
# Dibuat     : 24 Januari 2025
# Diperbarui : 17 Mei 2026
# Versi      : 2.2
# Lisensi    : MIT
# ============================================================

# Pengaturan keamanan eksekusi:
#   -e          : hentikan skrip jika ada perintah yang gagal
#   -u          : cegah penggunaan variabel yang belum diatur
#   -o pipefail : pipeline gagal jika salah satu bagian gagal
set -euo pipefail

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

check_status() {
    if [ "${PIPESTATUS[0]:-$?}" -ne 0 ]; then
        error_exit "$1"
    fi
}

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
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${pkg}" || \
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
            error_exit "Distribusi '${ID}' tidak didukung. Skrip ini hanya mendukung minimal Ubuntu 22.04 dan Debian 12."
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
            *vmware*) virt="vmware" ;;
            *kvm*|*qemu*) virt="kvm" ;;
            *proxmox*) virt="kvm" ;;
        esac
    fi

    if [ -z "${virt}" ]; then
        # Fallback: cek dengan lscpu (mungkin tidak ada)
        if command -v lscpu &>/dev/null; then
            if lscpu | grep -qi "hypervisor vendor"; then
                local hv
                hv=$(lscpu | grep "Hypervisor vendor" | awk -F: '{print $2}' | xargs)
                case "${hv,,}" in
                    *vmware*) virt="vmware" ;;
                    *kvm*) virt="kvm" ;;
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
    read -rp "Masukkan pilihan [1/2, default: 1]: " rpz_choice

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
        exit 1
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
    echo "  UPDATED : 17 May 2026"
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

    if ! command -v apt-get &> /dev/null; then
        error_exit "apt-get tidak ditemukan. Skrip hanya bekerja pada distribusi Debian/Ubuntu."
    fi

    install_dependencies
    check_os_version
    detect_virtualization

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

    echo ""
    success "============================================================"
    success " Instalasi BIND9 + RPZ selesai dengan sukses!"
    success " Log kegiatan tersimpan di: ${LOG_FILE}"
    success "============================================================"

    # Konfirmasi menjalankan RPZ
    echo ""
    info "Proses instalasi selesai. Apakah Anda ingin langsung menjalankan binary RPZ sekarang?"
    read -rp "    Jalankan RPZ? [Y/n] " answer
    case "${answer:0:1}" in
        y|Y|"")
            run_rpz
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
