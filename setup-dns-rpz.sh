#!/usr/bin/env bash
#
# setup-dns-rpz.sh
# Automatically install/configure BIND9 with RPZ, hardening, locale, and timezone
# Author       : HARRY DERTIN SUTISNA ALSYUNDAWY (modifikasi)
# Date         : Jakarta, 02 Juni 2025

set -euo pipefail
IFS=$'\n\t'

# Banner
echo "========================================"
echo "  Starting DNS+RPZ Setup Script"
echo "========================================"

# Color definitions
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
MAGENTA="\033[1;35m"
NC="\033[0m"  # No Color

# Paths and URLs
BIND_DIR="/etc/bind"
ZONES_DIR="$BIND_DIR/zones"
RPZ_BINARY="/usr/local/bin/rpz"
RPZ_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/rpz"
declare -A CONFIG_URLS=(
  ["named.conf.local"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/named.conf.local"
  ["named.conf.options"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/named.conf.options"
  ["safesearch.zones"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/zones/safesearch.zones"
  ["whitelist.zones"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/zones/whitelist.zones"
)

# Helpers
echo_error(){ echo -e "${MAGENTA}[ERROR] $*${NC}" >&2; exit 1; }
echo_status(){ echo -e "${GREEN}[OK] $*${NC}"; }

# Check root privileges
ensure_root(){
  if [[ $EUID -ne 0 ]]; then
    echo_error "Must run as root. Use: sudo bash setup-dns-rpz.sh"
  fi
}

# Disable dash as /bin/sh
configure_dash(){
  echo -e "${CYAN}Disabling dash as /bin/sh...${NC}"
  echo "dash dash/sh boolean false" | debconf-set-selections
  dpkg-reconfigure -f noninteractive dash || echo_error "Failed to reconfigure dash"
  echo_status "dash unlinked from /bin/sh"
}

# Clear bash history secure
clear_history(){
  echo -e "${CYAN}Clearing bash history...${NC}"
  history -c && history -w
  echo_status "History cleared"
}

# Set timezone
set_timezone(){
  echo -e "${CYAN}Setting timezone to Asia/Jakarta...${NC}"
  timedatectl set-timezone Asia/Jakarta || echo_error "Timezone set failed"
  echo_status "Timezone set"
}

# Fix hosts
fix_hosts(){
  echo -e "${CYAN}Updating /etc/hosts...${NC}"
  hn=$(hostname)
  grep -qF "$hn" /etc/hosts || echo "127.0.0.1 $hn" >> /etc/hosts
  echo_status "/etc/hosts updated"
}

# Disable services
disable_conflicts(){
  echo -e "${CYAN}Disabling systemd-resolved & networkd-wait-online...${NC}"
  systemctl disable --now systemd-resolved systemd-networkd-wait-online.service 2>/dev/null || true
  echo_status "Conflicting services disabled"
}

# Configure resolv.conf
configure_resolv(){
  echo -e "${CYAN}Writing /etc/resolv.conf...${NC}"
  unlink /etc/resolv.conf 2>/dev/null || true
  cat <<EOF > /etc/resolv.conf
search google.com
nameserver 127.0.0.1
nameserver 43.247.23.161
nameserver 43.247.23.188
nameserver 1.1.1.2
EOF
  echo_status "resolv.conf configured"
}

# Update system
update_system(){
  echo -e "${CYAN}Updating package lists...${NC}"
  apt-get update
  echo -e "${CYAN}Upgrading packages...${NC}"
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
  DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
  apt-get autoremove -y
  apt-get clean
  echo_status "System updated"
}

# Install BIND
install_bind(){
  echo -e "${CYAN}Installing bind9 & dnsutils...${NC}"
  DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 dnsutils || echo_error "Bind9 install failed"
  echo_status "Bind9 installed"
}

# Prepare BIND dirs (pastikan grup 'bind' sudah ada setelah install_bind)
prepare_directories(){
  echo -e "${CYAN}Creating zones directory...${NC}"
  mkdir -p "$ZONES_DIR"
  chown root:bind "$ZONES_DIR"
  chmod 755 "$ZONES_DIR"
  echo_status "$ZONES_DIR ready"
}

# Download helper
download_and_perms(){
  local url="$1" dest="$2" owner="$3" perms="$4"
  echo -e "${CYAN}Downloading $url${NC}"
  curl -# -fSL "$url" -o "$dest" || echo_error "Download failed: $url"
  chown "$owner" "$dest" || echo_error "Failed chown on $dest"
  chmod "$perms" "$dest"
  echo_status "$dest ready"
}

# Deploy config files
deploy_configs(){
  echo -e "${CYAN}Deploying BIND configs...${NC}"
  for file in "${!CONFIG_URLS[@]}"; do
    download_and_perms "${CONFIG_URLS[$file]}" "$BIND_DIR/$file" root:bind 644
  done
}

# Restart BIND
restart_bind(){
  echo -e "${CYAN}Checking BIND config...${NC}"
  named-checkconf || echo_error "Invalid BIND config"
  echo -e "${CYAN}Restarting BIND9...${NC}"
  systemctl restart bind9 || echo_error "BIND restart failed"
  echo_status "BIND9 running"
}

# Setup RPZ
setup_rpz(){
  echo -e "${CYAN}Installing RPZ binary...${NC}"
  download_and_perms "$RPZ_URL" "$RPZ_BINARY" root:root 755
  echo -e "${CYAN}Adding cron job...${NC}"
  (crontab -l 2>/dev/null || true; echo "0 */12 * * * $RPZ_BINARY >/dev/null 2>&1") | crontab -
  echo_status "RPZ cron scheduled"
}

# Main
main(){
  ensure_root
  configure_dash
  clear_history
  set_timezone
  fix_hosts
  disable_conflicts
  configure_resolv
  update_system

  # Pastikan BIND terinstal sebelum membuat direktori-zones agar grup 'bind' sudah ada
  install_bind
  prepare_directories

  deploy_configs
  restart_bind
  setup_rpz

  echo -e "${GREEN}=== All tasks completed successfully! ===${NC}"
}

main "$@"
