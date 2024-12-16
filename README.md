# TrustPositif To RPZ Binary
 TrustPositif To RPZ Binary adalah file binary merubah file list domain trustpositif dari kominfo menjadi format dns rpz.
 Hanya digunakan pada dns bind9 pada distro linux debian atau ubuntu, belum dicoba di unbound atau distro linux lainnya.

Debian / Ubuntu 

sudo apt update; sudo apt install bind9 dnsutils
 
sudo wget -c https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/raw/refs/heads/main/rpz -O /usr/local/bin/rpz ; sudo chmod +x /usr/local/bin/rpz

sudo rpz

<img width="736" alt="image" src="https://github.com/user-attachments/assets/43781839-88b9-43a0-ac80-3473a624305a" />



