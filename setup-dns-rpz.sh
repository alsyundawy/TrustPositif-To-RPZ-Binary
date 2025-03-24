
#!/usr/bin/env bash

# Script ini digunakan untuk menginstal dan mengonfigurasi BIND9 DNS server
# yang digunakan untuk mengelola DNS dengan konfigurasi RPZ (Response Policy Zone).
# Script ini mengunduh dan mengonfigurasi file konfigurasi BIND9 serta 
# mengunduh dan mengonfigurasi file RPZ binary untuk digunakan dalam sistem.
# Dibuat oleh: Alsyundawy
# Tanggal: 24 Januari 2025


# Warna untuk teks (4 warna terang)
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
MAGENTA='\033[1;35m'
NC='\033[0m' # No Color

# Konfigurasi
BIND_DIR="/etc/bind"
ZONES_DIR="${BIND_DIR}/zones"
RPZ_BINARY="/usr/local/bin/rpz"
CONFIG_FILES=(
    "named.conf.local"
    "named.conf.options"
    "zones/safesearch.zones"
    "zones/whitelist.zones"
)
REPO_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/refs/heads/main/bind"
RPZ_URL="https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/raw/refs/heads/main/rpz"

# Fungsi untuk menampilkan pesan error dan keluar
error_exit() {
    echo -e "${MAGENTA}[ERROR] $1${NC}" >&2
    exit 1
}

# Fungsi untuk mengecek status perintah terakhir
check_status() {
    if [ $? -ne 0 ]; then
        error_exit "$1"
    fi
}

# Fungsi untuk memeriksa apakah URL valid
check_url() {
    if ! curl --head --silent --fail "$1" > /dev/null; then
        error_exit "URL tidak valid: $1"
    fi
}

# Fungsi untuk mengunduh file
download_file() {
    local url="$1"
    local destination="$2"
    echo -e "${CYAN}Mengunduh file dari $url ke $destination...${NC}"
    wget -cq "$url" -O "$destination"
    check_status "Gagal mengunduh file dari $url."
}

# Fungsi untuk mengatur kepemilikan dan izin
set_permissions() {
    local target="$1"
    local owner="$2"
    local permissions="$3"
    echo -e "${CYAN}Mengatur kepemilikan dan izin untuk $target...${NC}"
    chown "$owner" "$target"
    check_status "Gagal mengatur kepemilikan untuk $target."
    chmod "$permissions" "$target"
    check_status "Gagal mengatur izin untuk $target."
}

# Memeriksa apakah script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Script ini memerlukan hak akses root. Meminta elevasi...${NC}"
    exec sudo bash "$0" "$@"
    exit
fi

# Menampilkan informasi script
echo -e "${CYAN}# Script ini digunakan untuk menginstal dan mengonfigurasi BIND9 DNS server${NC}"
echo -e "${CYAN}# dengan konfigurasi RPZ (Response Policy Zone).${NC}"
echo -e "${YELLOW}# Dibuat oleh: Alsyundawy${NC}"
echo -e "${YELLOW}# Tanggal: 13 Januari 2025${NC}"

# Memperbaiki masalah hostname
echo -e "${CYAN}Memperbaiki masalah hostname...${NC}"
if ! grep -q "$(hostname)" /etc/hosts; then
    echo "127.0.0.1 $(hostname)" | tee -a /etc/hosts > /dev/null
    check_status "Gagal memperbaiki konfigurasi /etc/hosts."
fi

# Memperbarui sistem secara komprehensif
echo -e "${CYAN}Memperbarui sistem...${NC}"
apt-get update
check_status "Gagal memperbarui repositori."
apt-get upgrade -y
check_status "Gagal melakukan upgrade paket."
apt-get dist-upgrade -y
check_status "Gagal melakukan dist-upgrade."
apt-get full-upgrade -y
check_status "Gagal melakukan full-upgrade."
apt-get --purge autoremove -y
check_status "Gagal membersihkan paket yang tidak terpakai."

# Membersihkan cache paket yang rusak
echo -e "${CYAN}Membersihkan cache paket yang rusak...${NC}"
apt-get clean
apt-get autoclean
apt-get autoremove -y

# Memperbaiki dependency yang rusak
echo -e "${CYAN}Memperbaiki dependency yang rusak...${NC}"
apt-get install -f -y
check_status "Gagal memperbaiki dependency."

# Menginstal paket bind9 dan dnsutils
echo -e "${CYAN}Menginstal paket bind9 dan dnsutils...${NC}"
apt-get install -y bind9 dnsutils
check_status "Gagal menginstal paket yang diperlukan."

# Memastikan folder /etc/bind/zones ada
echo -e "${CYAN}Memastikan folder $ZONES_DIR ada...${NC}"
mkdir -p "$ZONES_DIR"
check_status "Gagal membuat direktori $ZONES_DIR."
set_permissions "$ZONES_DIR" "root:bind" "755"

# Mengunduh dan mengonfigurasi file konfigurasi BIND
echo -e "${YELLOW}Mengunduh dan mengonfigurasi file konfigurasi BIND...${NC}"
for file in "${CONFIG_FILES[@]}"; do
    destination="${BIND_DIR}/${file}"
    url="${REPO_URL}/${file}"
    check_url "$url"
    download_file "$url" "$destination"
    set_permissions "$destination" "root:bind" "644"
done

# Memeriksa konfigurasi BIND9
echo -e "${GREEN}Memeriksa konfigurasi BIND9...${NC}"
named-checkconf
check_status "Konfigurasi BIND tidak valid."

# Memeriksa port 53
echo -e "${CYAN}Memeriksa port 53...${NC}"
if netstat -tuln | grep -q ':53 '; then
    echo -e "${YELLOW}Port 53 sudah digunakan. Menghentikan layanan yang menggunakan port 53...${NC}"
    fuser -k 53/udp 53/tcp
    check_status "Gagal mengosongkan port 53."
fi

# Menjalankan ulang layanan BIND9
echo -e "${GREEN}Menjalankan ulang layanan BIND9...${NC}"
systemctl restart named
check_status "Gagal menjalankan ulang layanan BIND9."

# Mengunduh binary RPZ dan membuatnya dapat dieksekusi
echo -e "${YELLOW}Mengunduh binary RPZ dan membuatnya dapat dieksekusi...${NC}"
check_url "$RPZ_URL"
download_file "$RPZ_URL" "$RPZ_BINARY"
set_permissions "$RPZ_BINARY" "root:root" "755"

# Menambahkan cron job untuk menjalankan RPZ setiap 12 jam
echo -e "${GREEN}Menambahkan cron job untuk menjalankan RPZ setiap 12 jam...${NC}"
(crontab -l 2>/dev/null; echo "0 */12 * * * $RPZ_BINARY > /dev/null 2>&1") | crontab -
check_status "Gagal menambahkan cron job."

# Menjalankan RPZ binary
echo -e "${MAGENTA}Menjalankan RPZ binary...${NC}"
"$RPZ_BINARY"
check_status "Gagal menjalankan binary RPZ."

echo -e "${GREEN}Script selesai dijalankan.${NC}"
