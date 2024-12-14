# TrustPositif To RPZ Binary
 TrustPositif To RPZ Binary adalah file binary merubah file list domain trustpositif dari kominfo menjadi format dns rpz.
 hanya digunakan pada dns bind9 pada distro linux debian atau ubuntu, belum dicoba di unbound atau distro linux lainnya.


 
wget -c  https://github.com/alsyundawy/TrustPositif-To-RPZ-Binary/raw/refs/heads/main/rpz -O /usr/local/bin/rpz
chmod +X /usr/local/bin/rpz
