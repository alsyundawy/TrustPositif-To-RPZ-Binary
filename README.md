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
# - Sistem trap pembersihan file sementara (cleanup trap) ditambahkan untuk menangani interupsi (SIGINT/SIGTERM/EXIT/ERR).
# - Deteksi OS diperluas untuk mendukung Debian Trixie (13+), Forky (14+), sid, serta Ubuntu 24.04+ dan 26.04+.
# - Virtualisasi KVM/QEMU dan VMware kini otomatis mengaktifkan (systemctl enable --now) guest agent terkait.
# - Deteksi entri hostname di /etc/hosts kini mengenali pola 127.0.1.1 bawaan Debian/Ubuntu.
# - Auto-generate /etc/bind/rndc.key ditambahkan jika berkas kunci belum tersedia.
# - Menu pemilihan sumber RPZ (choose_rpz_source) kini selalu ditampilkan ke terminal via /dev/tty,
#   aman dijalankan via sudo, pipe, curl|bash, maupun Cloud-Init/CI tanpa kehilangan prompt interaktif.
# - Konfirmasi "Jalankan RPZ?" di akhir skrip juga menggunakan /dev/tty langsung (bukan stdin).
# - Binary RPZ lama di /usr/local/bin/rpz selalu dihapus (rm -f) sebelum download ulang agar
#   overwrite dijamin berhasil meskipun file sebelumnya terkunci atau memiliki atribut immutable.
# - Fungsi download_file menggunakan /tmp sebagai staging area (bukan direktori tujuan) sehingga
#   aman lintas filesystem/mount point; menggunakan cp -f (bukan mv) agar overwrite selalu atomik.
# - Verifikasi ukuran file hasil unduhan ditambahkan (minimal 10 bytes) sebelum ditulis ke tujuan.
# - Log setup_rpz_binary kini menampilkan URL sumber aktif, ukuran file, dan 5 baris pertama isi
#   binary sebagai bukti visual bahwa sumber yang dipilih benar-benar terunduh dan diterapkan.
#
# CHANGELOG v2.5:
# - FEATURE : Pengalihan default database RPZ ke ALSYUNDAWY DATABASE (rpz-alsyundawy-database).
# - REFACTOR: Penyesuaian nama endpoint database GitHub menjadi rpz-github-database.
# - REFACTOR: Standardisasi penyimpanan seluruh varian database menjadi binary /usr/local/bin/rpz.
# - FIX     : Idempotensi handle_port53 diperbaiki agar tidak memblokir eksekusi saat named/bind9 sudah aktif.
# - FIX     : Potensi data loss pada download_bind_configs dihapus (tidak lagi menghapus file tujuan sebelum unduhan selesai).
# - FIX     : Deteksi Debian sid/testing tanpa VERSION_ID numerik ditangani dengan aman.
# - FIX     : fix_hostname kini mengenali entri 127.0.1.1 bawaan Debian/Ubuntu agar tidak membuat duplikasi.
# - FIX     : choose_rpz_source tidak menampilkan menu saat dijalankan via sudo/pipe; diperbaiki dengan
#             menulis menu dan prompt langsung ke /dev/tty, menggantikan syarat [ -t 0 ] yang tidak reliable.
# - FIX     : Konfirmasi "Jalankan RPZ?" di main() diperbaiki dengan cara yang sama (tulis/baca /dev/tty).
# - FIX     : setup_rpz_binary tidak meng-overwrite binary RPZ lama; diperbaiki dengan rm -f eksplisit
#             + chattr -i sebelum download, dan cp -f atomik setelah unduhan selesai.
# - FIX     : download_file menggunakan temp file di /tmp (bukan direktori tujuan) untuk menghindari
#             kegagalan mv lintas mount point; fallback wget→curl kini menggunakan flag download_ok
#             agar aman dengan set -Eeuo pipefail.
# - FIX     : Validasi ukuran file hasil unduhan (< 10 bytes dianggap gagal) ditambahkan di download_file.
# - SECURITY: Penambahan trap pembersihan (cleanup handler) untuk seluruh file sementara mktemp.
# - SECURITY: Otomatisasi verifikasi & pembuatan /etc/bind/rndc.key dengan permission 640 (root:bind).
# - SECURITY: Standarisasi izin berkas /etc/resolv.conf ke 644 (root:root) setelah modifikasi.
# - OPTIMIZE: Aktivasi langsung open-vm-tools dan qemu-guest-agent via systemctl enable --now.
# - OPTIMIZE: Pengaturan set -Eeuo pipefail untuk inheritance trap pada subshell/fungsi.
# - OPTIMIZE: setup_rpz_binary kini menampilkan ukuran file dan 5 baris pertama isi binary sebagai
#             konfirmasi visual sumber RPZ yang aktif setelah setiap proses download.
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

    # Gunakan /tmp sebagai lokasi temp agar tidak ada hambatan dari filesystem tujuan
    tmp_file=$(mktemp /tmp/.rpz_download.XXXXXX) || error_exit "Gagal membuat file sementara di /tmp"
    TEMP_FILES+=("${tmp_file}")

    info "Mengunduh: ${url} -> ${destination}"

    local download_ok=0
    if wget --quiet --timeout=30 --tries=3 "${url}" -O "${tmp_file}" 2>/dev/null; then
        download_ok=1
    elif curl --silent --fail --location --connect-timeout 15 --max-time 60 "${url}" -o "${tmp_file}" 2>/dev/null; then
        download_ok=1
    fi

    if [ "${download_ok}" -eq 0 ]; then
        rm -f "${tmp_file}"
        error_exit "Gagal mengunduh file dari: ${url}"
    fi

    if [ ! -s "${tmp_file}" ]; then
        rm -f "${tmp_file}"
        error_exit "File hasil unduhan kosong dari: ${url}"
    fi

    local filesize
    filesize=$(wc -c < "${tmp_file}" 2>/dev/null || echo 0)
    if [ "${filesize}" -lt 10 ]; then
        rm -f "${tmp_file}"
        error_exit "File hasil unduhan terlalu kecil (${filesize} bytes), kemungkinan gagal: ${url}"
    fi

    # Salin ke tujuan lalu hapus tmp (cp aman lintas filesystem, mv bisa gagal jika beda mount)
    cp -f "${tmp_file}" "${destination}" || {
        rm -f "${tmp_file}"
        error_exit "Gagal menyalin file ke: ${destination}"
    }
    rm -f "${tmp_file}"
    success "Berhasil mengunduh ke: ${destination} (${filesize} bytes)"
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
    # Tampilkan menu selalu ke terminal (tulis ke /dev/tty agar tampil meski stdin di-redirect)
    if [ -w /dev/tty ]; then
        {
            echo ""
            printf '%b[INFO]%b PILIH SUMBER DATABASE RPZ YANG AKAN DIGUNAKAN:\n' "${CYAN}" "${NC}"
            printf '%b[INFO]%b   1) ALSYUNDAWY DATABASE (DEFAULT)\n' "${CYAN}" "${NC}"
            printf '%b[INFO]%b   2) KOMDIGI\n' "${CYAN}" "${NC}"
            printf '%b[INFO]%b   3) GITHUB\n' "${CYAN}" "${NC}"
            echo ""
        } > /dev/tty
    else
        echo ""
        info "PILIH SUMBER DATABASE RPZ YANG AKAN DIGUNAKAN:"
        info "  1) ALSYUNDAWY DATABASE (DEFAULT)"
        info "  2) KOMDIGI"
        info "  3) GITHUB"
        echo ""
    fi

    local rpz_choice=""
    if [ -r /dev/tty ] && [ -w /dev/tty ]; then
        printf 'Masukkan pilihan [1/2/3, default: 1]: ' > /dev/tty
        read -r rpz_choice < /dev/tty || rpz_choice="1"
    else
        rpz_choice="1"
        warn "Tidak ada terminal interaktif, menggunakan pilihan default: 1 (ALSYUNDAWY DATABASE)"
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
    info "======================================================"
    info "DOWNLOAD BINARY RPZ DARI SUMBER YANG DIPILIH:"
    info "  Sumber : ${RPZ_URL}"
    info "  Tujuan : ${RPZ_BINARY}"
    info "======================================================"

    check_url "${RPZ_URL}"

    # Hapus atribut immutable jika ada, lalu hapus file lama secara eksplisit
    if [ -f "${RPZ_BINARY}" ]; then
        if command -v chattr > /dev/null 2>&1; then
            chattr -i "${RPZ_BINARY}" 2>/dev/null || true
        fi
        rm -f "${RPZ_BINARY}" || error_exit "Gagal menghapus binary RPZ lama: ${RPZ_BINARY}"
        info "File lama ${RPZ_BINARY} berhasil dihapus."
    fi

    download_file "${RPZ_URL}" "${RPZ_BINARY}"
    set_permissions "${RPZ_BINARY}" "root:root" "755"

    # Verifikasi: pastikan file baru benar-benar ada dan tidak kosong
    if [ ! -s "${RPZ_BINARY}" ]; then
        error_exit "Binary RPZ tidak ditemukan atau kosong setelah download: ${RPZ_BINARY}"
    fi

    local rpz_size
    rpz_size=$(wc -c < "${RPZ_BINARY}" 2>/dev/null || echo 0)
    success "======================================================"
    success "Binary RPZ BERHASIL diperbarui!"
    success "  File   : ${RPZ_BINARY}"
    success "  Ukuran : ${rpz_size} bytes"
    success "  Sumber : ${RPZ_URL}"
    success "======================================================"

    info "Isi awal binary RPZ (5 baris pertama):"
    head -5 "${RPZ_BINARY}" 2>/dev/null | while IFS= read -r line; do
        info "  ${line}"
    done || true
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
    if [ -r /dev/tty ] && [ -w /dev/tty ]; then
        printf '    Jalankan RPZ? [Y/n] ' > /dev/tty
        read -r answer < /dev/tty || answer="y"
    else
        answer="y"
        warn "Tidak ada terminal interaktif, RPZ dijalankan otomatis."
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
