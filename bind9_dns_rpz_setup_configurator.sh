#!/usr/bin/env bash

# ============================================================
# Nama       : INSTALL_BIND9_RPZ_SETUP_CONFIGURATOR.SH
# Deskripsi  : Skrip otomasi komprehensif untuk instalasi dan konfigurasi
#              BIND9 DNS Server terintegrasi dengan Response Policy Zone (RPZ).
#              Fitur utama meliputi:
#              - Deteksi OS (Ubuntu 22.04+ / Debian 11+) & tipe virtualisasi.
#              - Penanganan konflik Port 53 secara lebih aman.
#              - Pilihan multi-sumber sinkronisasi database RPZ (GitHub / Komdigi).
#              - Unduhan konfigurasi, binary RPZ, dan penjadwalan pembaruan (12 jam).
#              - Validasi konfigurasi BIND sebelum reload.
#              - Pemuatan ulang RPZ menggunakan rndc reload setelah RPZ berjalan.
#              - Perbaikan struktur jaringan dasar melalui /etc/resolv.conf.
# Penulis    : Harry Dertin Sutisna Alsyundawy
# Kontak     : alsyundawy@gmail.com, +628568515212 (WhatsApp/Telegram/Call)
# Homepage   : https://alsyundawy.com
# Repositori : https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary
# Dibuat     : 24 Januari 2025
# Diperbarui : 13 Juni 2026
# Versi      : 2.3
# Lisensi    : MIT
# ============================================================
#
# DOCNOTE v2.3:
# - Debian minimal dikunci ke Debian 11 (Bullseye); Debian 10 ke bawah ditolak.
# - Ubuntu minimal tetap Ubuntu 22.04 (Jammy); Ubuntu 20.04 ke bawah ditolak.
# - Struktur utama skrip dipertahankan agar kompatibel dengan alur v2.2.
# - Reload BIND setelah RPZ berjalan dilakukan dengan rndc reload.
# - Konfigurasi BIND divalidasi sebelum restart/reload untuk mencegah named gagal load.
#
# CHANGELOG v2.3:
# - FIX     : Banner diselaraskan dari Debian 12+ menjadi Debian 11+.
# - FIX     : check_root dipindahkan lebih awal agar non-root tidak gagal saat membuat log.
# - FIX     : Logging dibuat lebih aman; gagal menulis log tidak menghentikan skrip.
# - FIX     : Validasi versi OS dibuat lebih robust menggunakan angka major version.
# - FIX     : Duplikasi pesan sukses RPZ dihapus.
# - SECURITY: Download file dilakukan atomik melalui file sementara sebelum overwrite target.
# - SECURITY: File konfigurasi utama dibackup dengan timestamp agar tidak tertimpa backup lama.
# - SECURITY: Penanganan port 53 tidak lagi membunuh proses unknown secara brutal.
# - SECURITY: /etc/resolv.conf dibackup sebelum diubah.
# - LOGIC   : Service BIND dideteksi otomatis antara named/bind9.
# - LOGIC   : Cron RPZ diperbarui agar menjalankan RPZ lalu rndc reload.
# - LOGIC   : named-checkconf -z dijalankan setelah RPZ untuk test-load zone primary.
# - CLEANUP : Paket wildcard libidn* diganti paket eksplisit idn2/libidn2-0.
#
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

# Opsi APT non-interaktif yang tetap mempertahankan konfigurasi lokal lama bila ada konflik.
readonly -a APT_OPTS=(
    -y
    -qq
    -o Dpkg::Options::=--force-confdef
    -o Dpkg::Options::=--force-confold
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

    printf '%b[%s] %s%b\n' "${color}" "${level}" "${message}" "${NC}"
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
        local backup="${target}.bak.$(date '+%Y%m%d-%H%M%S')"
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
    info "Mengunduh: ${url} -> ${destination}"

    if ! wget --quiet --timeout=30 --tries=3 "${url}" -O "${tmp_file}"; then
        rm -f "${tmp_file}"
        error_exit "Gagal mengunduh file dari: ${url}"
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

    local os_id="${ID:-unknown}"
    local version_id="${VERSION_ID:-0}"
    local major_version="${version_id%%.*}"

    if ! [[ "${major_version}" =~ ^[0-9]+$ ]]; then
        error_exit "VERSION_ID tidak valid atau tidak numerik: ${version_id}"
    fi

    case "${os_id}" in
        debian)
            if [ "${major_version}" -lt 11 ]; then
                error_exit "Debian versi ${version_id} tidak didukung. Minimal Debian 11 (Bullseye). Debian 10 ke bawah ditolak."
            fi
            if [ "${major_version}" -lt 13 ]; then
                warn "Debian ${version_id} terdeteksi. Didukung, namun rekomendasi operasional tetap Debian 13 atau lebih tinggi agar memperoleh BIND versi lebih baru."
            else
                success "Debian ${version_id} memenuhi syarat."
            fi
            ;;
        ubuntu)
            if [ "${major_version}" -lt 22 ]; then
                error_exit "Ubuntu versi ${version_id} tidak didukung. Minimal Ubuntu 22.04 (Jammy). Rekomendasi Ubuntu 24.04 atau lebih tinggi."
            fi
            if [ "${major_version}" -lt 24 ]; then
                warn "Ubuntu ${version_id} terdeteksi. Didukung, namun rekomendasi operasional tetap Ubuntu 24.04 atau lebih tinggi untuk BIND 9.18+."
            else
                success "Ubuntu ${version_id} memenuhi syarat."
            fi
            ;;
        *)
            error_exit "Distribusi '${os_id}' tidak didukung. Skrip ini hanya mendukung minimal Ubuntu 22.04 (Jammy) dan Debian 11 (Bullseye)."
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
    fi

    # Jika tidak terdeteksi, coba baca dari DMI.
    if [ -z "${virt}" ] && [ -f /sys/class/dmi/id/product_name ]; then
        local product
        product=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
        case "${product,,}" in
            *vmware*)        virt="vmware" ;;
            *kvm*|*qemu*)    virt="kvm" ;;
            *proxmox*)       virt="kvm" ;;
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
                *kvm*)    virt="kvm" ;;
            esac
        fi
    fi

    case "${virt}" in
        vmware)
            success "Terdeteksi VMware. Memasang open-vm-tools..."
            apt-get "${APT_OPTS[@]}" install open-vm-tools || \
                warn "Gagal memasang open-vm-tools, lanjut tanpa tools tamu."
            ;;
        kvm)
            success "Terdeteksi KVM/QEMU (Proxmox VE mungkin). Memasang qemu-guest-agent..."
            apt-get "${APT_OPTS[@]}" install qemu-guest-agent || \
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
    info "  3) ALSYUNDAWY DATABASE"

    local rpz_choice
    read -rp "Masukkan pilihan [1/2/3, default: 1]: " rpz_choice </dev/tty || rpz_choice=1
    rpz_choice="${rpz_choice:-1}"

    case "${rpz_choice}" in
        2)
            info "MENGGUNAKAN DATABASE RPZ DARI KOMDIGI."
            RPZ_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/rpz-komdigi-database"
            ;;
        3)
            info "MENGGUNAKAN DATABASE RPZ DARI ALSYUNDAWY DATABASE."
            RPZ_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/rpz-alsyundawy-database"
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
        if ! command -v sudo > /dev/null 2>&1; then
            printf 'ERROR: Skrip ini memerlukan hak akses root dan sudo tidak tersedia. Jalankan sebagai root.\n' >&2
            exit 1
        fi
        warn "Skrip ini memerlukan hak akses root. Meminta elevasi..."
        exec sudo -E bash "$0" "$@"
        # exec mengganti proses; baris setelah ini tidak akan pernah tercapai.
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

    echo -e "${MAGENTA}"
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
    echo "  VERSION : 2.3"
    echo "  UPDATED : 13 Juni 2026"
    echo "  CREATED : 24 Januari 2025"
    echo "  TARGET  : Debian >=11, Ubuntu >=22.04, BIND9 + RPZ"
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

    if ! awk -v h="${host}" '$1 == "127.0.0.1" { for (i = 2; i <= NF; i++) if ($i == h) found = 1 } END { exit found ? 0 : 1 }' /etc/hosts 2>/dev/null; then
        info "Menambahkan hostname '${host}' ke /etc/hosts..."
        printf '127.0.0.1 %s\n' "${host}" >> /etc/hosts || error_exit "Gagal memperbarui /etc/hosts."
        success "Hostname '${host}' berhasil ditambahkan."
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
    apt-get "${APT_OPTS[@]}" install \
        bind9 bind9-dnsutils bind9-utils \
        bc git htop iftop telnet traceroute rsync screen whois fping ipcalc subnetcalc idn2 libidn2-0 \
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

        if [[ "${file}" == "named.conf.local" || "${file}" == "named.conf.options" ]]; then
            backup_file "${destination}"
            rm -f "${destination}"
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
    if netstat -tuln 2>/dev/null | grep -qE '(^|[[:space:]])(tcp|udp).*:53[[:space:]]'; then
        return 0
    fi
    return 1
}

show_port53_users() {
    warn "Daftar proses/listener port 53 saat ini:"
    ss -tulpen 2>/dev/null | grep -E '(^|[[:space:]])(tcp|udp).*:53[[:space:]]' || true
    netstat -tulpen 2>/dev/null | grep -E '(^|[[:space:]])(tcp|udp).*:53[[:space:]]' || true
}

handle_port53() {
    info "Memeriksa port 53..."
    if ! port53_in_use; then
        success "Port 53 tersedia."
        return 0
    fi

    warn "Port 53 sedang dipakai. Mencoba menghentikan layanan DNS lokal yang umum..."
    show_port53_users

    local svc
    for svc in systemd-resolved dnsmasq unbound; do
        if systemctl list-unit-files "${svc}.service" > /dev/null 2>&1 && systemctl is-active --quiet "${svc}.service"; then
            systemctl stop "${svc}.service" || warn "Gagal menghentikan ${svc}.service"
            systemctl disable "${svc}.service" --quiet || warn "Gagal menonaktifkan ${svc}.service"
            warn "${svc}.service dihentikan dan dinonaktifkan."
        fi
    done

    sleep 2

    if port53_in_use; then
        show_port53_users
        error_exit "Port 53 masih dipakai oleh proses lain. Hentikan proses tersebut secara manual agar BIND9 dapat bind ke port 53."
    fi

    success "Port 53 berhasil dibersihkan."
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

    sed -i '/^[[:space:]]*nameserver[[:space:]]*127\.0\.0\.1[[:space:]]*$/d' /etc/resolv.conf 2>/dev/null || true

    local tmp_resolv
    tmp_resolv=$(mktemp) || error_exit "Gagal membuat file sementara resolv.conf."
    printf 'nameserver 127.0.0.1\n' > "${tmp_resolv}"
    cat /etc/resolv.conf >> "${tmp_resolv}" 2>/dev/null || true
    cat "${tmp_resolv}" > /etc/resolv.conf
    rm -f "${tmp_resolv}"

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
    local answer
    read -rp "    Jalankan RPZ? [Y/n] " answer </dev/tty || answer="y"
    answer="${answer:-y}"

    case "${answer:0:1}" in
        y|Y|"")
            run_rpz
            ;;
        *)
            info "RPZ tidak dijalankan. Anda dapat menjalankannya nanti dengan perintah:"
            info "  ${RPZ_BINARY} && rndc reload"
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
