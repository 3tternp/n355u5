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
 echo $(date '+%Y-%m-%d %H:%M:%S')
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
    echo " >> Update system, install utilities..."
pacman -Syu libxcrypt-compat --noconfirm &>/dev/null
pacman -S curl dpkg expect --noconfirm &>/dev/null
/bin/systemctl stop nessusd.service &>/dev/null
echo " o downloading Nessus.."
curl --request GET \
  --url 'https://www.tenable.com/downloads/api/v2/pages/nessus/files/Nessus-10.8.4-debian10_amd64.deb' \
  --output 'Nessus-10.8.4-debian10_amd64.deb'&>/dev/null
{ if [ ! -f Nessus-10.8.4-debian10_amd64.deb ]; then
  echo " o nessus download failed :/ exiting. where are you man ?? Are you living in stoneage ??"
  exit 0
fi }
echo " o installing Nessus.."
dpkg -i Nessus-10.8.4-debian10_amd64.deb &>/dev/null
rm -r Nessus-10.8.4-debian10_amd64.deb  &>/dev/null
# look I tried to just make changes and run but it doesnt work. if you can optimize
# what im doing here, let me know.  but this was it for me, it had to be run once :/
echo " o starting service once FIRST TIME INITIALIZATION (we have to do this)"
/bin/systemctl start nessusd.service &>/dev/null
echo " o let's allow Nessus time to initalize - we'll give it like 20 seconds..."
sleep 20
echo " o stopping the nessus service.."
/bin/systemctl stop nessusd.service &>/dev/null
echo " o changing nessus settings to Zen preferences (freedom fighter mode)"
echo "   listen port: 8834"
/opt/nessus/sbin/nessuscli fix --set xmlrpc_listen_port=8834 &>/dev/null
echo "   theme:       dark"
/opt/nessus/sbin/nessuscli fix --set ui_theme=dark &>/dev/null
echo "   safe checks: off"
/opt/nessus/sbin/nessuscli fix --set safe_checks=false &>/dev/null
echo "   logs:        performance"
/opt/nessus/sbin/nessuscli fix --set backend_log_level=performance &>/dev/null
echo "   updates:     off"
/opt/nessus/sbin/nessuscli fix --set auto_update=false &>/dev/null
/opt/nessus/sbin/nessuscli fix --set auto_update_ui=false &>/dev/null
/opt/nessus/sbin/nessuscli fix --set disable_core_updates=true &>/dev/null
echo "   telemetry:   off"
/opt/nessus/sbin/nessuscli fix --set report_crashes=false &>/dev/null
/opt/nessus/sbin/nessuscli fix --set send_telemetry=false &>/dev/null
echo " o adding a user you can change this later (u:admin,p:admin)"
cat > expect.tmp<<'EOF'
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
EOF
expect -f expect.tmp &>/dev/null
rm -rf expect.tmp &>/dev/null
echo " o downloading new plugins.."
curl -A Mozilla -o all-2.0.tar.gz \
  --url 'https://plugins.nessus.org/v2/nessus.php?f=all-2.0.tar.gz&u=56b33ade57c60a01058b1506999a2431&p=1ee9c89d5379a119a56498f2d5dff674' &>/dev/null
{ if [ ! -f all-2.0.tar.gz ]; then
  echo " o plugins all-2.0.tar.gz download failed :/ exiting. where r you man ?? get the h3ll out of here to internet zone"
  exit 0
fi }
echo " o installing plugins.."
/opt/nessus/sbin/nessuscli update all-2.0.tar.gz &>/dev/null
echo " o fetching version number.."
# i have seen this not be correct for the download.  hrm. but, it works for me.
vernum=$(curl https://plugins.nessus.org/v2/plugins.php 2> /dev/null)
echo " o building plugin feed..."
cat > /opt/nessus/var/nessus/plugin_feed_info.inc <<EOF
PLUGIN_SET = "${vernum}";
PLUGIN_FEED = "ProfessionalFeed (Direct)";
PLUGIN_FEED_TRANSPORT = "Tenable Network Security Lightning";
EOF
echo " o protecting files.."
chattr -i /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc &>/dev/null
cp /opt/nessus/var/nessus/plugin_feed_info.inc /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc &>/dev/null
echo " o let's set everything immutable..."
chattr +i /opt/nessus/var/nessus/plugin_feed_info.inc &>/dev/null
chattr +i -R /opt/nessus/lib/nessus/plugins &>/dev/null
echo " o but unsetting key files.."
chattr -i /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc &>/dev/null
chattr -i /opt/nessus/lib/nessus/plugins  &>/dev/null
echo " o starting service.."
rm -r all-2.0.tar.gz &>/dev/null
/bin/systemctl start nessusd.service &>/dev/null
echo " o Let's sleep for another 20 seconds to let the server have time to start!"
sleep 20
echo " o Monitoring Nessus progress. Following line updates every 10 seconds until 100%"
zen=0
while [ $zen -ne 100 ]
do
 statline=`curl -sL -k https://localhost:8834/server/status|awk -F"," -v k="engine_status" '{ gsub(/{|}/,""); for(i=1;i<=NF;i++) { if ( $i ~ k ){printf $i} } }'`
 if [[ $statline != *"engine_status"* ]]; then echo -ne "\n Problem: Nessus server unreachable? Trying again..\n"; fi
 echo -ne "\r $statline"
 if [[ $statline == *"100"* ]]; then zen=100; else sleep 10; fi
done
echo -ne '\n  o Done!\n'
echo
echo "        Access your Nessus:  https://localhost:8834/ (or your VPS IP)"
echo "                             username: admin"
# echo "                             password: admin"
echo "                             you can change this any time"
echo
read -p "Press enter to continue"
echo
     echo "Installation complete!"
      ;;
      
    2) # Version Update
      echo "Stopping Nessus service..."
      /bin/systemctl stop nessusd.service &>/dev/null
chattr -i /opt/nessus/var/nessus/plugin_feed_info.inc
chattr -i -R /opt/nessus/lib/nessus/plugins
/bin/systemctl stop nessusd.service &>/dev/null
echo " o downloading Nessus.."
curl --request GET \
  --url 'https://www.tenable.com/downloads/api/v2/pages/nessus/files/Nessus-10.8.4-debian10_amd64.deb' \
  --output 'Nessus-10.8.4-debian10_amd64.deb'&>/dev/null
{ if [ ! -f Nessus-10.8.4-debian10_amd64.deb ]; then
  echo " o nessus download failed :/ exiting. where are you man ?? Are you living in stoneage ??"
  exit 0
fi }
echo " o installing Nessus.."
dpkg -i Nessus-10.8.4-debian10_amd64.deb  &>/dev/null
rm -r Nessus-10.8.4-debian10_amd64.deb  &>/dev/null
# look I tried to just make changes and run but it doesnt work. if you can optimize
# what im doing here, let me know.  but this was it for me, it had to be run once :/
echo " o starting service once FIRST TIME INITIALIZATION (we have to do this)"
/bin/systemctl start nessusd.service &>/dev/null
echo " o let's allow Nessus time to initalize - we'll give it like 20 seconds..."
sleep 20
echo " o stopping the nessus service.."
/bin/systemctl stop nessusd.service &>/dev/null
echo " o changing nessus settings to Zen preferences (freedom fighter mode)"
echo "   listen port: 8834"
/opt/nessus/sbin/nessuscli fix --set xmlrpc_listen_port=8834 &>/dev/null
echo "   theme:       dark"
/opt/nessus/sbin/nessuscli fix --set ui_theme=dark &>/dev/null
echo "   safe checks: off"
/opt/nessus/sbin/nessuscli fix --set safe_checks=false &>/dev/null
echo "   logs:        performance"
/opt/nessus/sbin/nessuscli fix --set backend_log_level=performance &>/dev/null
echo "   updates:     off"
/opt/nessus/sbin/nessuscli fix --set auto_update=false &>/dev/null
/opt/nessus/sbin/nessuscli fix --set auto_update_ui=false &>/dev/null
/opt/nessus/sbin/nessuscli fix --set disable_core_updates=true &>/dev/null
echo "   telemetry:   off"
/opt/nessus/sbin/nessuscli fix --set report_crashes=false &>/dev/null
/opt/nessus/sbin/nessuscli fix --set send_telemetry=false &>/dev/null
echo " o adding a user you can change this later (u:admin,p:admin)"
cat > expect.tmp<<'EOF'
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
EOF
expect -f expect.tmp &>/dev/null
rm -rf expect.tmp &>/dev/null
echo " o downloading new plugins.."
curl -A Mozilla -o all-2.0.tar.gz \
  --url 'https://plugins.nessus.org/v2/nessus.php?f=all-2.0.tar.gz&u=56b33ade57c60a01058b1506999a2431&p=1ee9c89d5379a119a56498f2d5dff674' &>/dev/null
{ if [ ! -f all-2.0.tar.gz ]; then
  echo " o plugins all-2.0.tar.gz download failed :/ exiting. where r you man ?? get the h3ll out of here to internet zone"
  exit 0
fi }
echo " o installing plugins.."
/opt/nessus/sbin/nessuscli update all-2.0.tar.gz &>/dev/null
echo " o fetching version number.."
# i have seen this not be correct for the download.  hrm. but, it works for me.
vernum=$(curl https://plugins.nessus.org/v2/plugins.php 2> /dev/null)
echo " o building plugin feed..."
cat > /opt/nessus/var/nessus/plugin_feed_info.inc <<EOF
PLUGIN_SET = "${vernum}";
PLUGIN_FEED = "ProfessionalFeed (Direct)";
PLUGIN_FEED_TRANSPORT = "Tenable Network Security Lightning";
EOF
echo " o protecting files.."
chattr -i /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc &>/dev/null
cp /opt/nessus/var/nessus/plugin_feed_info.inc /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc &>/dev/null
echo " o let's set everything immutable..."
chattr +i /opt/nessus/var/nessus/plugin_feed_info.inc &>/dev/null
chattr +i -R /opt/nessus/lib/nessus/plugins &>/dev/null
echo " o but unsetting key files.."
chattr -i /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc &>/dev/null
chattr -i /opt/nessus/lib/nessus/plugins  &>/dev/null
echo " o starting service.."
rm -r all-2.0.tar.gz &>/dev/null
/bin/systemctl start nessusd.service &>/dev/null
echo " o Let's sleep for another 20 seconds to let the server have time to start!"
sleep 20
echo " o Monitoring Nessus progress. Following line updates every 10 seconds until 100%"
zen=0
while [ $zen -ne 100 ]
do
 statline=`curl -sL -k https://localhost:8834/server/status|awk -F"," -v k="engine_status" '{ gsub(/{|}/,""); for(i=1;i<=NF;i++) { if ( $i ~ k ){printf $i} } }'`
 if [[ $statline != *"engine_status"* ]]; then echo -ne "\n Problem: Nessus server unreachable? Trying again..\n"; fi
 echo -ne "\r $statline"
 if [[ $statline == *"100"* ]]; then zen=100; else sleep 10; fi
done
echo -ne '\n  o Done!\n'
echo
echo "        Access your Nessus:  https://localhost:8834/ (or your VPS IP)"
echo "                             username: admin"
# echo "                             password: admin"
echo "                             you can change this any time"
echo
     echo "Version update complete!"
      ;;
      
    3) # Plugin Update
chattr -i /opt/nessus/var/nessus/plugin_feed_info.inc
chattr -i -R /opt/nessus/lib/nessus/plugins
/bin/systemctl stop nessusd.service &>/dev/null

echo " o downloading new plugins.."
curl -A Mozilla -o all-2.0.tar.gz \
  --url 'https://plugins.nessus.org/v2/nessus.php?f=all-2.0.tar.gz&u=56b33ade57c60a01058b1506999a2431&p=1ee9c89d5379a119a56498f2d5dff674' &>/dev/null
{ if [ ! -f all-2.0.tar.gz ]; then
  echo " o plugins all-2.0.tar.gz download failed :/ exiting. where r you man ?? get the h3ll out of here to internet zone"
  exit 0
fi }
echo " o installing plugins.."
/opt/nessus/sbin/nessuscli update all-2.0.tar.gz &>/dev/null
echo " o fetching version number.."
# i have seen this not be correct for the download.  hrm. but, it works for me.
vernum=$(curl https://plugins.nessus.org/v2/plugins.php 2> /dev/null)
echo " o building plugin feed..."
cat > /opt/nessus/var/nessus/plugin_feed_info.inc <<EOF
PLUGIN_SET = "${vernum}";
PLUGIN_FEED = "ProfessionalFeed (Direct)";
PLUGIN_FEED_TRANSPORT = "Tenable Network Security Lightning";
EOF
echo " o protecting files.."
chattr -i /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc &>/dev/null
cp /opt/nessus/var/nessus/plugin_feed_info.inc /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc &>/dev/null
echo " o let's set everything immutable..."
chattr +i /opt/nessus/var/nessus/plugin_feed_info.inc &>/dev/null
chattr +i -R /opt/nessus/lib/nessus/plugins &>/dev/null
echo " o but unsetting key files.."
chattr -i /opt/nessus/lib/nessus/plugins/plugin_feed_info.inc &>/dev/null
chattr -i /opt/nessus/lib/nessus/plugins  &>/dev/null
echo " o starting service.."
rm -r all-2.0.tar.gz &>/dev/null
/bin/systemctl start nessusd.service &>/dev/null
echo " o Let's sleep for another 20 seconds to let the server have time to start!"
sleep 20
echo " o Monitoring Nessus progress. Following line updates every 10 seconds until 100%"
zen=0
while [ $zen -ne 100 ]
do
 statline=`curl -sL -k https://localhost:8834/server/status|awk -F"," -v k="engine_status" '{ gsub(/{|}/,""); for(i=1;i<=NF;i++) { if ( $i ~ k ){printf $i} } }'`
 if [[ $statline != *"engine_status"* ]]; then echo -ne "\n Problem: Nessus server unreachable? Trying again..\n"; fi
 echo -ne "\r $statline"
 if [[ $statline == *"100"* ]]; then zen=100; else sleep 10; fi
done
echo -ne '\n  o Done!\n'
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

