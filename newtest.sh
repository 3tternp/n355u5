#!/bin/bash

# Check if the script is run as root
if [[ $(id -u) -ne 0 ]]; then
    echo "Please run this script as root."
    exit 1
fi

echo "=============================================================="
echo "            Nessus Management Script"
echo "=============================================================="
echo "Current date and time: $(date)"
echo "=============================================================="

# Function to print the menu
print_menu() {
    echo -e "\033[36m"
    echo "Choose the operation you want to perform:"
    echo -e "\033[31m1. New Install"
    echo -e "\033[32m2. Version Update"
    echo -e "\033[33m3. Plugin Update Only"
    echo -e "\033[32m4. Exit"
    echo -e "\033[36m"
}

# Function to install Nessus
install_nessus() {
    echo "Updating system and installing necessary utilities..."
    apt-get update -y
    apt-get install curl dpkg expect -y

    echo "Stopping Nessus service..."
    systemctl stop nessusd.service

    echo "Downloading Nessus..."
    curl -L -o Nessus.deb 'https://www.tenable.com/downloads/api/v2/pages/nessus/files/Nessus-10.8.2-debian10_amd64.deb'
    if [[ ! -f Nessus.deb ]]; then
        echo "Nessus download failed. Exiting."
        exit 1
    fi

    echo "Installing Nessus..."
    dpkg -i Nessus.deb
    rm -f Nessus.deb

    echo "Starting Nessus service for initialization..."
    systemctl start nessusd.service
    sleep 20
    systemctl stop nessusd.service

    configure_nessus
}

# Function to configure Nessus after installation
configure_nessus() {
    echo "Configuring Nessus settings..."
    /opt/nessus/sbin/nessuscli fix --set xmlrpc_listen_port=8834
    /opt/nessus/sbin/nessuscli fix --set ui_theme=dark
    /opt/nessus/sbin/nessuscli fix --set safe_checks=false
    /opt/nessus/sbin/nessuscli fix --set backend_log_level=performance
    /opt/nessus/sbin/nessuscli fix --set auto_update=false
    /opt/nessus/sbin/nessuscli fix --set auto_update_ui=false
    /opt/nessus/sbin/nessuscli fix --set disable_core_updates=true
    /opt/nessus/sbin/nessuscli fix --set report_crashes=false
    /opt/nessus/sbin/nessuscli fix --set send_telemetry=false

    add_nessus_user
}

# Function to add a default user
add_nessus_user() {
    echo "Adding default user (username: admin, password: admin)..."
    expect -c '
    spawn /opt/nessus/sbin/nessuscli adduser admin
    expect "Login password:"
    send "admin\r"
    expect "Login password (again):"
    send "admin\r"
    expect "*(can upload plugins, etc.)? (y/n)*"
    send "y\r"
    expect "*(the user can have an empty rules set)"
    send "\r"
    expect "Is that ok*"
    send "y\r"
    expect eof
    '
}

# Function to update Nessus
perform_version_update() {
    echo "Updating Nessus..."
    systemctl stop nessusd.service
    install_nessus
}

# Function to update plugins
perform_plugin_update() {
    echo "Updating plugins..."
    systemctl stop nessusd.service

    echo "Downloading new plugins..."
    curl -A Mozilla -o all-2.0.tar.gz 'https://plugins.nessus.org/v2/nessus.php?f=all-2.0.tar.gz'
    if [[ ! -f all-2.0.tar.gz ]]; then
        echo "Plugin download failed. Exiting."
        exit 1
    fi

    echo "Installing plugins..."
    /opt/nessus/sbin/nessuscli update all-2.0.tar.gz
    rm -f all-2.0.tar.gz
    echo "Plugins updated successfully."
}

# Main loop
while true; do
    print_menu
    read -p "Select an option: " choice
    case $choice in
        1) install_nessus ;;
        2) perform_version_update ;;
        3) perform_plugin_update ;;
        4) exit 0 ;;
        *) echo -e "\033[31mInvalid selection. Please try again.\033[36m" ;;
    esac
done
