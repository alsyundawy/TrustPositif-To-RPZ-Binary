#!/bin/bash

# ============================================
# Script: trustpositif-rpz.sh
# Fungsi: 
#   - Mengunduh daftar domain dari URL "https://trustpositif.kominfo.go.id/assets/db/domains_isp"
#   - Mengonversi daftar domain tersebut menjadi format RPZ untuk digunakan dengan BIND DNS
#   - Menghasilkan file zona DNS dengan konfigurasi SOA dan NS, serta menambahkan CNAME untuk setiap domain
#   - Menggunakan curl untuk mengunduh file dengan melewati verifikasi SSL
#   - Menghasilkan serial SOA secara acak dan menulisnya ke dalam file output
#   - Melakukan restart layanan named dan reload konfigurasi DNS setelah file selesai dibuat
#
# Pembuat: Harry DS Alsyundawy
# Tanggal Pembuatan: 13 Januari 2025
# ============================================

# Nama file input
INPUT_FILE_URL="https://trustpositif.kominfo.go.id/assets/db/domains_isp"
# Nama file output
OUTPUT_FILE="/etc/bind/zones/trustpositif-rpz.zones"
# Tempat menyimpan file sementara untuk input
TEMP_INPUT_FILE="/tmp/domains_isp.txt"

# Fungsi untuk menghasilkan serial SOA random
generate_serial_soa() {
    date +%Y%m%d$(( RANDOM % 99 + 1 ))
}

# Mengunduh file input dengan curl dan bypass SSL
curl -s --insecure -o "$TEMP_INPUT_FILE" "$INPUT_FILE_URL"

# Cek jika file berhasil diunduh
if [ ! -f "$TEMP_INPUT_FILE" ]; then
    echo "Gagal mengunduh file input dari $INPUT_FILE_URL"
    exit 1
fi

# Generate serial SOA random
SERIAL_SOA=$(generate_serial_soa)
# Mendapatkan waktu sekarang
CURRENT_TIME=$(date)

# Menulis header ke file output
{
    echo "; File ini dihasilkan pada: $CURRENT_TIME"
    echo "; Authors: Harry DS Alsyundawy"
    echo ""
    echo "\$TTL 300"
    echo "@ IN SOA localhost. root.localhost. ("
    echo "    $SERIAL_SOA ; Serial"
    echo "    10800      ; Refresh"
    echo "    120        ; Retry"
    echo "    604800     ; Expire"
    echo "    3600       ; Minimum TTL"
    echo ")"
    echo "@ IN NS lamanlabuh.resolver.id."
} > "$OUTPUT_FILE"

# Menggunakan awk untuk membaca file input dan menulis ke file output
awk '
{
    print $0 " CNAME lamanlabuh.resolver.id."
    print "*." $0 " CNAME lamanlabuh.resolver.id."
}' "$TEMP_INPUT_FILE" >> "$OUTPUT_FILE"

# Menghapus file sementara
rm -f "$TEMP_INPUT_FILE"

echo "Konversi selesai. File output disimpan sebagai $OUTPUT_FILE."

# Restart named dan reload konfigurasi
systemctl restart named
rndc reload
