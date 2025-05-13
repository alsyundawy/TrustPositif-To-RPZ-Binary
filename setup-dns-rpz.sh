#!/usr/bin/env bash
#
# Optimized Installer & Configurator for BIND9 with RPZ (Response Policy Zone)
# Author       : HARRY DERTIN SUTISNA ALSYUNDAWY
# Date         : Jakarta, 25 Maret 2025
# Description  : Automatic setup of BIND9 DNS server with RPZ binary, plus system hardening and locale settings.

set -euo pipefail
IFS=$'\n\t'

# Color definitions
readonly CYAN="\033[1;36m"
readonly YELLOW="\033[1;33m"
readonly GREEN="\033[1;32m"
readonly MAGENTA="\033[1;35m"
readonly NC="\033[0m"  # No Color

# Configuration variables
readonly BIND_DIR="/etc/bind"
readonly ZONES_DIR="${BIND_DIR}/zones"
readonly RPZ_BINARY="/usr/local/bin/rpz"
readonly RPZ_URL="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/rpz"
declare -A CONFIG_URLS=(
  ["named.conf.local"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/named.conf.local"
  ["named.conf.options"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/named.conf.options"
  ["safesearch.zones"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/zones/safesearch.zones"
  ["whitelist.zones"]="https://raw.githubusercontent.com/alsyundawy/TrustPositif-To-RPZ-Binary/main/bind/zones/whitelist.zones"
)

# Error and status helpers
echo_error(){ echo -e "${MAGENTA}[ERROR] $*${NC}" >&2; exit 1; }
echo_status(){ echo -e "${GREEN}[OK] $*${NC}"; }

# Ensure running as root
enforce_root(){ [[ $EUID -ne 0 ]] && { echo -e "${YELLOW}Elevating to root...${NC}"; exec sudo bash "$0" "$@"; }; }

# Disable dash as /bin/sh for reliability
configure_dash(){
  echo -e "${CYAN}Disabling dash as /bin/sh...${NC}"
  echo "dash dash/sh boolean false" | debconf-set-selections
  dpkg-reconfigure -f noninteractive dash || echo_error "Failed to reconfigure dash"
  echo_status "dash unlinked from /bin/sh"
}

# Clear bash history securely
clear_history(){
  echo -e "${CYAN}Clearing bash history...${NC}"
  history -c && history -w
  echo_status "Bash history cleared"
}

# Set timezone to Asia/Jakarta
set_timezone(){
  echo -e "${CYAN}Setting timezone to Asia/Jakarta...${NC}"
  timedatectl set-timezone Asia/Jakarta || echo_error "Failed to set timezone"
  echo_status "Timezone set"
}

# Fix /etc/hosts
fix_hosts(){
  hn="$(hostname)"
  grep -qF "$hn" /etc/hosts || { echo "127.0.0.1 $hn" >> /etc/hosts || echo_error "Failed updating /etc/hosts"; }
  echo_status "/etc/hosts ok"
}

# Disable conflicting services
disable_conflicts(){ for svc in systemd-resolved systemd-networkd-wait-online; do systemctl disable --now "$svc" 2>/dev/null || :; done; echo_status "Conflicting services disabled"; }

# Configure DNS resolver
configure_resolv(){
  echo -e "${CYAN}Configuring /etc/resolv.conf...${NC}"
  unlink /etc/resolv.conf 2>/dev/null || :
  cat <<EOF > /etc/resolv.conf
search google.com
nameserver 127.0.0.1
nameserver 43.247.23.161
nameserver 43.247.23.188
nameserver 1.1.1.2
EOF
  echo_status "resolv.conf written"
}

# System update & cleanup
update_system(){
  echo -e "${CYAN}Updating system...${NC}"
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
  DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -qq
  apt-get autoremove -y -qq
  apt-get clean -qq
  echo_status "System up-to-date"
}

# Prepare BIND directories
prepare_directories(){ mkdir -p "$ZONES_DIR"; chown root:bind "$ZONES_DIR"; chmod 755 "$ZONES_DIR"; echo_status "Zones directory ready"; }

# Install BIND9 & dnsutils
install_bind(){ echo -e "${CYAN}Installing BIND9 & dnsutils...${NC}"; DEBIAN_FRONTEND=noninteractive apt-get install -y -qq bind9 dnsutils || echo_error "BIND9 install failed"; echo_status "BIND9 installed"; }

# Download and set permissions for file
download_and_perms(){ local url="$1" dest="$2" owner="$3" perms="$4"; echo -e "${CYAN}Downloading $url...${NC}"; curl -fsSL "$url" -o "$dest" || echo_error "Download failed: $url"; chown "$owner" "$dest"; chmod "$perms" "$dest"; echo_status "$dest ready"; }

# Deploy BIND config files
deploy_configs(){ for file in "${!CONFIG_URLS[@]}"; do download_and_perms "${CONFIG_URLS[$file]}" "${BIND_DIR}/$file" root:bind 644; done; }

# Verify and restart BIND
restart_bind(){ named-checkconf || echo_error "Invalid BIND config"; systemctl restart bind9 || echo_error "Failed restart BIND9"; echo_status "BIND9 running"; }

# Setup RPZ binary & cron job
setup_rpz(){ download_and_perms "$RPZ_URL" "$RPZ_BINARY" root:root 755; (crontab -l 2>/dev/null || true; echo "0 */12 * * * $RPZ_BINARY >/dev/null 2>&1") | crontab -; echo_status "RPZ cron ready"; }

# Main execution
main(){
  enforce_root "$@"
  configure_dash
  clear_history
  set_timezone
  fix_hosts
  disable_conflicts
  configure_resolv
  update_system
  prepare_directories
  install_bind
  deploy_configs
  restart_bind
  setup_rpz
  echo -e "${GREEN}All done successfully!${NC}"
}

main "$@"
