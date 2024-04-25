#!/bin/bash

# Constants
NESSUS_DOWNLOAD_URL="https://www.tenable.com/downloads/api/v2/pages/nessus/files/Nessus-10.7.2-debian10_amd64.deb"
PLUGIN_DOWNLOAD_URL="https://plugins.nessus.org/v2/nessus.php?f=all-2.0.tar.gz&u=4e2abfd83a40e2012ebf6537ade2f207&p=29a34e24fc12d3f5fdfbb1ae948972c6"

# Functions for common steps
download_and_install_nessus() {
  echo " >> Update system, install utilities..."
  pacman -Syu libxcrypt-compat --noconfirm &>/dev/null
  pacman -S curl dpkg expect --noconfirm &>/dev/null

  echo " o Downloading Nessus..."
  curl -o Nessus-10.7.2-debian10_amd64.deb "$NESSUS_DOWNLOAD_URL" &>/dev/null 
  if [ $? -ne 0 ]; then
    echo " o Nessus download failed. Check your connection and try again."
    exit 1
  fi

  echo " o Installing Nessus..."
  dpkg -i Nessus-10.7.2-debian10_amd64.deb &>/dev/null
  rm Nessus-10.7.2-debian10_amd64.deb &>/dev/null
}

first_time_setup() {
  echo " o Starting Nessus service for initial setup..."
  /bin/systemctl start nessusd.service &>/dev/null 
  sleep 20 # Allow Nessus time to initialize

  echo " o Stopping Nessus service..."
  /bin/systemctl stop nessusd.service &>/dev/null 

  echo " o Configuring Nessus preferences..."
  /opt/nessus/sbin/nessuscli fix --set xmlrpc_listen_port=8834 &>/dev/null
  /opt/nessus/sbin/nessuscli fix --set ui_theme=dark &>/dev/null
  /opt/nessus/sbin/nessuscli fix --set safe_checks=false &>/dev/null
  /opt/nessus/sbin/nessuscli fix --set backend_log_level=performance &>/dev/null
  /opt/nessus/sbin/nessuscli fix --set auto_update=false &>/dev/null
  /opt/nessus/sbin/nessuscli fix --set auto_update_ui=false &>/dev/null
  /opt/nessus/sbin/nessuscli fix --set disable_core_updates=true &>/dev/null
  /opt/nessus/sbin/nessuscli fix --set report_crashes=false &>/dev/null
  /opt/nessus/sbin/nessuscli fix --set send_telemetry=false &>/dev/null

  echo " o Creating admin user (u:admin, p:admin)..."
  /opt/nessus/sbin/nessuscli adduser admin <<EOF
admin
admin
y

y
EOF
}

download_and_update_plugins() {
  echo " o Downloading latest plugins..."
  curl -o all-2.0.tar.gz "$PLUGIN_DOWNLOAD_URL" &>/dev/null
  if [ $? -ne 0 ]; then
    echo " o Plugin download failed. Check your connection and try again."
    exit 1
  fi

  echo " o Updating plugins..."
  /opt/nessus/sbin/nessuscli update all-2.0.tar.gz &>/dev/null
  rm all-2.0.tar.gz
}

configure_plugin_feed() {
  echo " o Fetching latest plugin version number..."
  plugin_version=$(curl -s https://plugins.nessus.org/v2/plugins.php)

  echo " o Building plugin feed configuration..."
  cat > /opt/nessus/var/nessus/plugin_feed_info.inc <<EOF
PLUGIN_SET = "${plugin_version}";
PLUGIN_FEED = "ProfessionalFeed (Direct)";
PLUGIN_FEED_TRANSPORT = "Tenable Network Security Lightning";
EOF

  echo " o Protecting configuration files..."
  chattr +i /opt/nessus/var/nessus/plugin_feed_info.inc &>/dev/null
  chattr +i -R /opt/nessus/lib/nessus/plugins &>/dev/null
}

start_nessus() {
  echo " o Starting Nessus service..."
  /bin/systemctl start nessusd.service &>/dev/null
}

# ******* MAIN SCRIPT *******
while true; do
  echo -e "\n\033[36mChoose the operation you want to perform:\033[39m"
  echo "1. New Install"
  echo "2. Version Update"
  echo "3. Plugin Update Only"
  echo "4. Exit"

  read -p "Enter your choice: " choice
  echo -e "\033[39m" # Reset color
  
  case $choice in 
    # ... (See below for case implementations) 
  esac
done 
