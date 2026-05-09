#!/bin/bash
# ============================================
# Script: trustpositif-rpz.sh
# ============================================
# Deskripsi:
#   Script ini mengunduh daftar blokir TrustPositif, mengkonversinya ke format
#   Response Policy Zone (RPZ) untuk BIND9, kemudian me-reload layanan named.
#
# Fitur:
#   - Download dengan timeout dan retry
#   - Proses cepat menggunakan awk
#   - Serial SOA otomatis (format YYYYMMDDHHMM)
#   - Validasi file setelah download
#   - Pengecekan direktori output
#   - Logging yang lebih informatif
#   - Error handling yang lebih baik
#
# Pembuat     		: Harry DS Alsyundawy
# Tanggal Pembuatan	: 14 Januari 2025
# Diperbaiki  		: 09 May 2026
# ============================================

set -o errexit  # Exit jika ada error
set -o pipefail # Exit jika pipeline gagal

# ================== WARNA ANSI ==================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ================== KONFIGURASI ==================
INPUT_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/alsyundawy-blocklist/alsyundawy_blacklist.txt" #gunakan link lain apabila tidak ada
OUTPUT_FILE="/etc/bind/zones/trustpositif.zones"
TEMP_FILE="/tmp/domains_isp_$$.txt"          # Gunakan PID agar unik
TTL="3600"

# ================== FUNGSI ==================

print_header() {
    echo -e "${BLUE}# ============================================"
    echo -e "# Script: ${CYAN}trustpositif-rpz.sh${RESET}"
    echo -e "# Deskripsi : Konversi TrustPositif ? RPZ BIND9"
    echo -e "# Pembuat   : ${MAGENTA}HARRY DS ALSYUNDAWY${RESET}"
    echo -e "# Dioptimasi: ${YELLOW}Grok${RESET}"
    echo -e "# ============================================${RESET}"
}

generate_serial() {
    date +%Y%m%d%H%M
}

check_directory() {
    local dir
    dir=$(dirname "$OUTPUT_FILE")
    if [[ ! -d "$dir" ]]; then
        echo -e "${YELLOW}Membuat direktori: ${dir}${RESET}"
        mkdir -p "$dir" || { echo -e "${RED}Gagal membuat direktori ${dir}${RESET}"; exit 1; }
    fi
}

# ================== MAIN PROCESS ==================

print_header

echo -e "${CYAN}Mengunduh daftar domain TrustPositif...${RESET}"
curl --fail --silent --show-error \
     --max-time 60 \
     --retry 3 \
     --retry-delay 5 \
     -o "$TEMP_FILE" "$INPUT_URL"

if [[ ! -s "$TEMP_FILE" ]]; then
    echo -e "${RED}Gagal mengunduh file atau file kosong.${RESET}"
    rm -f "$TEMP_FILE"
    exit 1
fi

DOMAIN_COUNT=$(wc -l < "$TEMP_FILE")
echo -e "${GREEN}Berhasil mengunduh ${YELLOW}$DOMAIN_COUNT${GREEN} domain.${RESET}"

check_directory

SERIAL=$(generate_serial)
CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${CYAN}Membuat file RPZ: ${YELLOW}$OUTPUT_FILE${RESET}"

{
    cat <<EOF
; =============================================
; File RPZ TrustPositif
; Dihasilkan otomatis pada : $CURRENT_TIME
; Jumlah domain            : $DOMAIN_COUNT
; =============================================

\$TTL $TTL
@ IN SOA localhost. root.localhost. (
    $SERIAL     ; Serial
    10800       ; Refresh
    120         ; Retry
    604800      ; Expire
    3600        ; Minimum TTL
)
@ IN NS lamanlabuh.resolver.id.

EOF

    # Proses domain (sangat cepat)
    awk -v ttl="$TTL" '
        NF > 0 && !/^#/ && !/^[[:space:]]*$/ {
            gsub(/\r/, "");  # hapus CR jika ada
            print $0, ttl, "IN CNAME lamanlabuh.resolver.id."
            print "*." $0, ttl, "IN CNAME lamanlabuh.resolver.id."
        }
    ' "$TEMP_FILE"

} > "$OUTPUT_FILE"

# Bersihkan temporary file
rm -f "$TEMP_FILE"

echo -e "${GREEN}Konversi selesai. Total ${YELLOW}$((DOMAIN_COUNT * 2))${GREEN} record RPZ dibuat.${RESET}"

# Reload BIND
echo -e "${CYAN}Melakukan reload konfigurasi BIND...${RESET}"

if systemctl restart named; then
    if rndc reload >/dev/null 2>&1; then
        echo -e "${GREEN}? BIND berhasil direstart dan RPZ berhasil dimuat ulang.${RESET}"
    else
        echo -e "${YELLOW}? named restart berhasil, tapi rndc reload gagal.${RESET}"
    fi
else
    echo -e "${RED}? Gagal merestart layanan named.${RESET}"
    exit 1
fi

echo -e "${MAGENTA}Script selesai dijalankan dengan sukses.${RESET}"