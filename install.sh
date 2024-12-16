#!/bin/bash

readonly scriptPwd="/tmp/"
cp ./Linux/Brother_printer_AutoInstaller "$scriptPwd"

readonly astralinux="astra"
readonly redos="redos"

readonly weasis_download_link_astra="https://github.com/nroduit/Weasis/releases/download/v4.0.3/weasis_4.0.3-1_amd64.deb"
readonly weasis_download_link_redos="https://github.com/nroduit/Weasis/releases/download/v4.5.1/weasis-4.5.1-1.x86_64.rpm"

readonly ruDesktop_download_link_astra="https://rudesktop.ru/download/rudesktop-astra-amd64.deb"
readonly ruDesktop_download_link_redos="https://rudesktop.ru/download/rudesktop-amd64.rpm"

restart_anydesk() {
  systemctl stop anydesk
  rm -fv /etc/anydesk/s*
  systemctl restart anydesk
}

enable_auto_unblock_service_for_secretnet() {
  cp ./Linux/snunblock.service /etc/systemd/system
  systemctl enable snunblock
  systemctl start snunblock
}

check_linux_version() {
  if [ "$(grep -c redos /etc/os-release)" -gt 0 ]; then
    echo "$redos"
  elif [ "$(grep -c astra /etc/os-release)" -gt 0 ]; then
    echo "$astralinux"
  fi
}

linux_version=$(check_linux_version)

download_ruDesktop() {
  case $linux_version in
  "$astralinux")
    wget -O "$scriptPwd"rudesktop-astra-amd64.deb "$ruDesktop_download_link_astra"
    ;;
  "$redos")
    wget -O "$scriptPwd"rudesktop-amd64.rpm "$ruDesktop_download_link_redos"
    ;;
  esac
}

install_ruDesktop() {
  case $linux_version in
  "$astralinux")
    apt install "$scriptPwd"rudesktop-astra-amd64.deb -y
    ;;
  "$redos")
    dnf install "$scriptPwd"rudesktop-amd64.rpm -y
    ;;
  esac
}

download_weasis_dicom_viewer() {
  case $linux_version in
  "$astralinux")
    wget -O "$scriptPwd"weasis.deb "$weasis_download_link_astra"
    ;;
  "$redos")
    wget -O "$scriptPwd"weasis.rpm "$weasis_download_link_redos"
    ;;
  esac
}

install_weasis_dicom_viewer() {
  case $linux_version in
  "$astralinux")
    dpkg -i "$scriptPwd"weasis.deb
    ;;
  "$redos")
    rpm -i "$scriptPwd"weasis.rpm
    ;;
  esac
}

set_cryptopro_license() {
  sudo /opt/cprocsp/sbin/amd64/cpconfig -license -set 4040U-D0000-01E43-EQZNN-5HL77
}

install_cryptopro_sertificates() {
  /opt/cprocsp/bin/amd64/certmgr -inst -store mroot -file "Kornevoy-sertifikat-GUTS-2022.CER" &&
    /opt/cprocsp/bin/amd64/certmgr -inst -store mroot -file "Kaznacheystvo-Rossii.CER" &&
    /opt/cprocsp/bin/amd64/certmgr -inst -store mroot -file "guts_2012.cer"
}

cryptopro_absorb_certificates() {
  local user
  user=$(grep -ie ^user /etc/passwd | cut -f1 -d':')
  sudo -u "$user" /opt/cprocsp/bin/amd64/csptestf -absorb -certs
}

secretnet_unlock_station() {
  /opt/secretnet/bin/snaidectl -i &&
    /opt/secretnet/sbin/snunblock &&
    /opt/secretnet/bin/sndevctl -c &&
    /opt/secretnet/sbin/snfc -i
}

secretnet_set_policy_not_to_block_station() {
  /opt/secretnet/bin/snpolctl -p devices -c devices_control,state,0
}

restart_anydesk
enable_auto_unblock_service_for_secretnet
download_ruDesktop
install_ruDesktop
download_weasis_dicom_viewer
install_weasis_dicom_viewer

if [ "$(lsusb | grep -ci brother)" -ne 0 ]; then
  echo "starting auto installer for brother printers"
  cd $scriptPwd
  bash "$scriptPwd"Brother_printer_AutoInstaller
fi

chown root:root /var/opt/cprocsp/tmp/.registry_lock
set_cryptopro_license
install_cryptopro_sertificates
cryptopro_absorb_certificates
secretnet_set_policy_not_to_block_station
secretnet_unlock_station
