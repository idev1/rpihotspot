#! /bin/bash

# REFERENCE: https://lb.raspberrypi.org/forums/viewtopic.php?t=211542#p1355569

apIp="10.0.0.1"
apDhcpRange="10.0.0.50,10.0.0.150,12h"
apSsid="<YOUR_AP_SSID>"
apPassphrase="<YOUR_AP_SSID_PASSPHRASE>"
setupIptablesMasquerade="iptables -t nat -A POSTROUTING -s 10.0.0.0/24 ! -d 10.0.0.0/24 -j MASQUERADE"

workDir="/home/pi"
installDir="$workDir/network-setup"
logDir="$installDir/log"
execDir="$installDir/bin"
downloadDir="$installDir/downloads"
netStartFile="$execDir/netStart"
netStopFile="$execDir/netStop.sh"
netLogFile="$logDir/network.log"
netStopServiceFile="/etc/systemd/system/netStop.service"
netStationConfigFile="/etc/network/interfaces.d/station"

cleanup=false
install=false
installUpgrade=false

while [ "$1" != "" ]; do
    
    if [ "$1" = "--clean" ]; then
        cleanup=true
    fi
    
    if [ "$1" = "--install" ]; then
        install=true
    fi
	
    if [ "$1" = "--install-upgrade" ]; then
        installUpgrade=true
    fi
	
    shift

done

# Create initial directories:
mkdir -p $installDir
mkdir -p $logDir
mkdir -p $execDir
mkdir -p $downloadDir

doRemoveDhcpdApSetup() {
    # May work with this pattern also: /^#__AP_SETUP_START__/,/^#__AP_SETUP_END__/p;/^#__AP_SETUP_END__/q
    result=$(sed -n '/^#__AP_SETUP_START__/,/^#__AP_SETUP_END__/p' /etc/dhcpcd.conf)
    if [ ! -z "$result" ]; then
        echo "[Remove]: AP config from /etc/dhcpcd.conf"
        sed '/^#__AP_SETUP_START__/,/^#__AP_SETUP_END__/d' /etc/dhcpcd.conf > ./tmp.conf
        rm -f /etc/dhcpcd.conf
        mv ./tmp.conf /etc/dhcpcd.conf
        rm -f ./tmp.conf
    fi
}

doAddDhcpdApSetup() {
    doRemoveDhcpdApSetup
    cat >> /etc/dhcpcd.conf <<EOF

#__AP_SETUP_START__
interface uap0
    static ip_address=$apIp
    nohook wpa_supplicant
#__AP_SETUP_END__
EOF

}

doRemoveRcLocalNetStartSetup() {
    if [ $(cat /etc/rc.local 2>/dev/null | grep -c "$netStartFile") -gt 0 ]; then
        echo "[Remove]: entry -> '$netStartFile' from /etc/rc.local"
        sed '/netStart/d' /etc/rc.local > ./tmp.conf
        rm -f /etc/rc.local
        mv ./tmp.conf /etc/rc.local
        rm -f ./tmp.conf
    fi
}

doAddRcLocalNetStartSetup() {
    doRemoveRcLocalNetStartSetup
    sed '/exit 0/d' /etc/rc.local > ./tmp.conf
    echo "/bin/bash $netStartFile
exit 0" >> ./tmp.conf
    rm -f /etc/rc.local
    mv ./tmp.conf /etc/rc.local
    rm -f ./tmp.conf
}

doRemoveIpTableNatEntries() {
    # Clean other network entries:
    iw dev uap0 del
    iptables -F
    iptables -t nat -F
    bash -c 'cat /dev/null > /etc/iptables.ipv4.nat'
    bash -c 'cat /dev/null > /proc/sys/net/ipv4/ip_forward'
    sed -i 's/^net.ipv4.ip_forward=.*$/#net.ipv4.ip_forward=1/' /etc/sysctl.conf
    echo "[Cleanup]: Cleaned all NAT IP Table entries."
}

doCleanup() {
    echo "[Cleanup]: cleaning ..."

    # Cleanup: /etc/dhcpcd.conf
    doRemoveDhcpdApSetup

    # Cleanup: /etc/rc.local
    doRemoveRcLocalNetStartSetup

    if [ $(dpkg-query -W -f='${Status}' hostapd 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "[Remove]: hostapd"
        apt purge -y hostapd
    fi

    if [ $(dpkg-query -W -f='${Status}' dnsmasq 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "[Remove]: dnsmasq"
        apt purge -y dnsmasq
    fi

    if [ $(dpkg-query -W -f='${Status}' iptables-persistent 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "[Remove]: iptables-persistent"
        apt purge -y iptables-persistent
    fi

    if [ -f "$netStationConfigFile" ]; then
        echo "[Remove]: $netStationConfigFile"
        rm -f $netStationConfigFile
    fi

    if [ -f "/etc/dnsmasq.conf" ]; then
        echo "[Remove]: /etc/dnsmasq.conf"
        rm -f /etc/dnsmasq.conf
    fi
    
    if [ -f "/etc/dnsmasq.conf.orig" ]; then
        echo "[Remove]: /etc/dnsmasq.conf.orig"
        rm -f /etc/dnsmasq.conf
    fi

    if [ -f "/etc/hostapd/hostapd.conf" ]; then
        echo "[Remove]: /etc/hostapd/hostapd.conf"
        rm -f /etc/hostapd/hostapd.conf
    fi

    if [ -f "/etc/default/hostapd" ]; then
        echo "[Remove]: /etc/default/hostapd"
        rm -f /etc/default/hostapd
    fi

    if [ $(systemctl list-unit-files --type=service 2>/dev/null | grep -c 'netStop.service') -gt 0 ]; then
        systemctl stop netStop.service
        systemctl disable netStop.service
        echo "[Remove]: stop/disable service -> netStop"
    fi
    
    if [ -f "$netStopServiceFile" ]; then
        echo "[Remove]: $netStopServiceFile"
        rm -f $netStopServiceFile
    fi
    
    if [ -f "$netStartFile" ]; then
        echo "[Remove]: $netStartFile"
        rm -f $netStartFile
    fi
    
    if [ -f "$netStopFile" ]; then
        echo "[Remove]: $netStopFile"
        rm -f $netStopFile
    fi
    
    if [ -f "$netLogFile" ]; then
        echo "[Remove]: $netLogFile"
        rm -f $netLogFile
    fi
    
    doRemoveIpTableNatEntries
    
    # Clean and auto remove the previously install dependant component if they exists by improper purging.
    apt clean
    apt autoremove -y

    #Restart DHCPCD service:
    systemctl restart dhcpcd
    #systemctl daemon-reload
    sleep 5
    
    echo "[Cleanup]: DONE"
}

doInstall() {

doCleanup

touch $netLogFile
chmod ug+w $netLogFile

#Silent install iptables:
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

echo "[Install]: installing: hostapd dnsmasq iptables-persistent ..."
apt update
if [ "$installUpgrade" = true ]; then
    apt upgrade -y
    apt dist-upgrade -y
fi
apt install -y hostapd dnsmasq iptables-persistent

systemctl stop hostapd
systemctl stop dnsmasq

doAddDhcpdApSetup

if [ ! -f "/etc/dnsmasq.conf.orig" ]; then
    echo "[Move]: /etc/dnsmasq.conf to /etc/dnsmasq.conf.orig"
    mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
fi

cat > /etc/dnsmasq.conf <<EOF
interface=lo,uap0               #Use interfaces lo and uap0
no-dhcp-interface=lo,wlan0
bind-interfaces                 #Bind to the interfaces
server=8.8.8.8                  #Forward DNS requests to Google DNS
#domain-needed                  #Don't forward short names
bogus-priv                      #Never forward addresses in the non-routed address spaces
dhcp-range=$apDhcpRange
EOF

cat > /etc/hostapd/hostapd.conf <<EOF
channel=1
ssid=$apSsid
wpa_passphrase=$apPassphrase
interface=uap0
# Use the 2.4GHz band (I think you can use in ag mode to get the 5GHz band as well, but I have not tested this yet)
hw_mode=g
# Accept all MAC addresses
macaddr_acl=0
# Use WPA authentication
auth_algs=1
# Require clients to know the network name
ignore_broadcast_ssid=0
# Use WPA2
wpa=2
# Use a pre-shared key
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
#driver=nl80211
country_code=IN
# I commented out the lines below in my implementation, but I kept them here for reference.
# Enable WMM
#wmm_enabled=1
# Enable 40MHz channels with 20ns guard interval
#ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
EOF

sed -i 's/^#DAEMON_CONF=.*$/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd

cat > $netStationConfigFile <<EOF 
allow-hotplug wlan0
EOF

# Create startup script
cat > $netStartFile <<EOF
#Make sure no uap0 interface exists (this generates an error; we could probably use an if statement to check if it exists first)
echo "Removing uap0 interface..."
iw dev uap0 del

#Add uap0 interface (this is dependent on the wireless interface being called wlan0, which it may not be in Stretch)
echo "Adding uap0 interface..."
iw dev wlan0 interface add uap0 type __ap

#Modify iptables (these can probably be saved using iptables-persistent if desired)
echo "IPV4 forwarding: setting..."
#sysctl net.ipv4.ip_forward=1
#echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sed -i 's/^#net.ipv4.ip_forward=.*$/net.ipv4.ip_forward=1/' /etc/sysctl.conf
echo "Editing IP tables..."
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -F
iptables -t nat -F
sleep 2
$setupIptablesMasquerade
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o uap0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i uap0 -o wlan0 -j ACCEPT
#iptables-save > /etc/iptables/rules.v4
iptables-save > /etc/iptables.ipv4.nat
#iptables-restore < /etc/iptables.ipv4.nat

# Bring up uap0 interface. Commented out line may be a possible alternative to using dhcpcd.conf to set up the IP address.
#ifconfig uap0 10.0.0.1 netmask 255.255.255.0 broadcast 10.0.0.255
ifconfig uap0 up

# Start hostapd. 10-second sleep avoids some race condition, apparently. It may not need to be that long. (?) 
echo "Starting hostapd service..."
systemctl start hostapd.service
sleep 10

#Start dhcpcd. Again, a 5-second sleep
echo "Starting dhcpcd service..."
systemctl start dhcpcd.service
sleep 20

echo "Starting dnsmasq service..."
systemctl restart dnsmasq.service
#systemctl start dnsmasq.service

echo "Enabling netStop service..."
systemctl enable netStop.service
systemctl start netStop.service

echo "netStart DONE"
bash -c 'echo "\$(date +"%Y-%m-%d %T") - Started: hostapd, dnsmasq, dhcpcd" >> $netLogFile'
EOF

chmod ug+x $netStartFile

doAddRcLocalNetStartSetup

cat > /etc/hosts <<EOF 
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.1.1       raspberrypi
$apIp    raspberrypi
EOF

# Disable regular network services:
# The netStart script handles starting up network services in a certain order and time frame. Disabling them here makes sure things are not run at system startup.
systemctl unmask hostapd

cat > $netStopFile <<EOF
#! /bin/bash

sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sudo systemctl stop dhcpcd
sudo systemctl disable hostapd
sudo systemctl disable dnsmasq
sudo systemctl disable dhcpcd

sudo bash -c 'echo "\$(date +"%Y-%m-%d %T") - Stopped: hostapd, dnsmasq, dhcpcd" >> $netLogFile'

EOF

chmod ug+x $netStopFile

# REFERENCE: https://raspberrypi.stackexchange.com/questions/89732/run-a-script-at-shutdown-on-raspbian
cat > $netStopServiceFile <<EOF
[Unit]
Description=Stops all the WiFi dependencies: hostapd, dnsmasq and dhcpcd.

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/bin/true
ExecStop=$netStopFile

[Install]
WantedBy=multi-user.target
EOF

echo "[Install]: enabling netStop.service ..."

systemctl systemctl enable netStop.service
systemctl systemctl start netStop.service

chmod ug+x /etc/rc.local

echo "[Install]: DONE"

}

if [ "$cleanup" = true ]; then
    doCleanup
    reboot
fi

if [ "$install" = true -o "$installUpgrade" = true ]; then
    doInstall
    # Sleep for 10s before restarting:
    echo "[Reboot]: In 10 seconds ..."
    sleep 10
    reboot
fi

if [ "$cleanup" = false -a "$install" = false -a "$installUpgrade" = false ]; then
    echo '
    No Options specified for script execution.
    Usage command is sudo ./setup-network.sh [OPTION].
    See [OPTION] below:
    ===========================================
    --clean             Cleans/undo all the previously made network configuration/setup.
    --install           Install without System Upgrade, network configuration/setup 
                        required to make single WiFi chip as Access Point (AP) and Station (STA).
    --install-upgrade   Install with System Upgrade, network configuration/setup 
                        required to make single WiFi chip as Access Point (AP) and Station (STA).
    '
    exit 0
fi
