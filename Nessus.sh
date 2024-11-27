#!/bin/bash

# Ensure the script is run as root
if [[ $(id -u) -ne 0 ]]; then
  echo "Please run as root."
  exit 1
fi

# Display header
clear
cat <<'EOF'
===============================================================
                     Nessus Installer
===============================================================

Current date and time: $(date)

Take a coffee break and relax; I'll handle the setup for you!
===============================================================

     _    ____ _____ ____      _     __  __
    / \  / ___|_   _|  _ \    / \    \ \/ /
   / _ \ \___ \ | | | |_) |  / _ \    \  / 
  / ___ \ ___) || | |  _ <  / ___ \ _ /  \ 
 /_/   \_\____/ |_| |_| \_\/_/   \_(_)_/\_\ 

Developed by: 3tternp  Reference by: PanchingHang
===============================================================
EOF

# Main menu loop
while true; do
  # Display menu options
  echo -e "\033[36mChoose an option:\033[0m"
  echo -e "\033[31m1. New Install\033[0m"
  echo -e "\033[32m2. Version Update\033[0m"
  echo -e "\033[33m3. Plugin Update Only\033[0m"
  echo -e "\033[34m4. Exit\033[0m"
  read -p "Enter your choice: " user_choice

  case "$user_choice" in
    1) # New Install
      echo "Starting new installation..."
      pacman -Syu libxcrypt-compat curl dpkg expect --noconfirm &>/dev/null
      /bin/systemctl stop nessusd.service &>/dev/null

      echo "Downloading Nessus package..."
      curl -s -o Nessus-10.8.3-debian10_amd64.deb 'https://www.tenable.com/downloads/api/v2/pages/nessus/files/Nessus-10.8.3-debian10_amd64.deb'
      if [[ ! -f Nessus-10.8.3-debian10_amd64.deb ]]; then
        echo "Failed to download Nessus package. Exiting."
        exit 1
      fi

      echo "Installing Nessus..."
      dpkg -i Nessus-10.8.3-debian10_amd64.deb &>/dev/null
      rm Nessus-10.8.3-debian10_amd64.deb &>/dev/null

      echo "Starting Nessus for initial setup..."
      /bin/systemctl start nessusd.service &>/dev/null
      sleep 20
      /bin/systemctl stop nessusd.service &>/dev/null

      echo "Configuring Nessus preferences..."
      /opt/nessus/sbin/nessuscli fix --set xmlrpc_listen_port=8834
      /opt/nessus/sbin/nessuscli fix --set ui_theme=dark
      /opt/nessus/sbin/nessuscli fix --set safe_checks=false
      /opt/nessus/sbin/nessuscli fix --set backend_log_level=performance
      /opt/nessus/sbin/nessuscli fix --set auto_update=false
      /opt/nessus/sbin/nessuscli fix --set send_telemetry=false

      echo "Adding Nessus admin user..."
      cat <<'ADMIN_USER' | expect
spawn /opt/nessus/sbin/nessuscli adduser admin
expect "Login password:"
send "admin\r"
expect "Login password (again):"
send "admin\r"
expect "*(can upload plugins, etc.)? (y/n)*"
send "y\r"
expect eof
ADMIN_USER

      echo "Downloading and installing plugins..."
      curl -s -o all-2.0.tar.gz 'https://plugins.nessus.org/v2/nessus.php?f=all-2.0.tar.gz'
      /opt/nessus/sbin/nessuscli update all-2.0.tar.gz &>/dev/null
      rm all-2.0.tar.gz &>/dev/null

      echo "Starting Nessus service..."
      /bin/systemctl start nessusd.service &>/dev/null
      sleep 20

      echo "Nessus installation complete! Access it at: https://localhost:8834/"
      echo "Username: admin | Password: admin"
      ;;
    2) # Version Update
      echo "Stopping Nessus service..."
      /bin/systemctl stop nessusd.service &>/dev/null

      echo "Updating Nessus package..."
      curl -s -o Nessus-10.8.3-debian10_amd64.deb 'https://www.tenable.com/downloads/api/v2/pages/nessus/files/Nessus-10.8.3-debian10_amd64.deb'
      dpkg -i Nessus-10.8.3-debian10_amd64.deb &>/dev/null
      rm Nessus-10.8.3-debian10_amd64.deb &>/dev/null

      echo "Starting Nessus for re-initialization..."
      /bin/systemctl start nessusd.service &>/dev/null
      sleep 20
     echo "Version update complete!"
      ;;
    3) # Plugin Update
      echo "Stopping Nessus service..."
      /bin/systemctl stop nessusd.service &>/dev/null

      echo "Downloading new plugins..."
      curl -s -o all-2.0.tar.gz 'https://plugins.nessus.org/v2/nessus.php?f=all-2.0.tar.gz'
      /opt/nessus/sbin/nessuscli update all-2.0.tar.gz &>/dev/null
      rm all-2.0.tar.gz &>/dev/null

      echo "Starting Nessus service..."
      /bin/systemctl start nessusd.service &>/dev/null
      sleep 20
      echo "Plugins updated successfully!"
      ;;
    4) # Exit
      echo "Exiting script."
      exit 0
      ;;
    *) # Invalid input
      echo -e "\033[31mInvalid selection. Please try again.\033[0m"
      ;;
  esac
done
