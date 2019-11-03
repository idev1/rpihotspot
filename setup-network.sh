#! /bin/bash

# Author: Pankaj Shelare
# Email: pankaj.shelare@gmail.com

# This script is created and enhanced using the thoughts of the below given link reference.
# REFERENCE: https://lb.raspberrypi.org/forums/viewtopic.php?t=211542
# Although, the script is created using the thought process of the above link,
# there are many enhancements made to solve BUGS (occurred during evaluation and testing phase) 
# and to promote many advanced features to automate and setup the single WiFi chip of
# Raspberry Pi as an Access Point(AP) and Station(STA) Network both (and hence, supporting
# HOTSPOT feature in Raspberry Pi using the execution of this script).

apIpDefault="10.0.0.1"
apDhcpRangeDefault="10.0.0.50,10.0.0.150,12h"
apSetupIptablesMasqueradeDefault="iptables -t nat -A POSTROUTING -s 10.0.0.0/24 ! -d 10.0.0.0/24 -j MASQUERADE"
apCountryCodeDefault="IN"
apChannelDefault="1"

apIp="$apIpDefault"
apDhcpRange="$apDhcpRangeDefault"
apSetupIptablesMasquerade="$apSetupIptablesMasqueradeDefault"
apCountryCode="$apCountryCodeDefault"
apChannel="$apChannelDefault"
apSsid=""
apPassphrase=""

# REFERENCE: Country codes taken from: https://github.com/recalbox/recalbox-os/wiki/Wifi-country-code-(EN)
countryCodeArray=("AT", "AU", "BE", "BR", "CA", "CH", "CN", "CY", "CZ", "DE", "DK", 
"EE", "ES", "FI", "FR", "GB", "GR", "HK", "HU", "ID", "IE", "IL", "IN", "IS", "IT",  
"JP", "KR", "LT", "LU", "LV", "MY", "NL", "NO", "NZ", "PH", "PL", "PT", "SE", "SG", 
"SI", "SK", "TH", "TW", "US", "ZA")

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
netShutdownFlagFile="$logDir/netShutdownFlag"
shutdownRecoveryFile="$execDir/shutdownRecovery"
rcLocalLogFile="$logDir/rc.local.log"

cleanup=false
install=false
installUpgrade=false
apSsidValid=false
apPassphraseValid=false
apCountryCodeValid=true
apIpAddrValid=true
rebootFlag=true

# Defined common WLAN and AP Interface names here as in the recent and future versions of Debian based OS 
# may change the Networking Interface name.
wlanInterfaceName="wlan0"
apInterfaceName="uap0"

# Set Country Code:
wlanCountryCode="$( cat /etc/wpa_supplicant/wpa_supplicant.conf | grep 'country=' | awk -F '=' '{print $2}' )"
if [[ ! -z "${wlanCountryCode}" && \
    ("${countryCodeArray[@]}" =~ "${wlanCountryCode}") ]]; then
    apCountryCode="$wlanCountryCode"
    apCountryCodeDefault="$wlanCountryCode"
fi

# Read WiFi Station(${wlanInterfaceName}) IP, Mask and Broadcast addresses:
read wlanIpAddr wlanIpMask wlanIpCast <<< $( echo $( ifconfig ${wlanInterfaceName} | grep 'inet ' ) | awk -F " " '{print $2" "$4" "$6}' )

# Set AP Channel:
wlanChannel="$( iwlist ${wlanInterfaceName} channel | grep 'Current Frequency:' | awk -F '(' '{gsub("\)", "", $2); print $2}' | awk -F ' ' '{print $2}' )"
if [ ! -z "${wlanChannel}" ]; then
    apChannel="$wlanChannel"
    apChannelDefault="$wlanChannel"
fi

echo ""
echo "[WLAN]: ${wlanInterfaceName} IP address: $wlanIpAddr"
echo "[WLAN]: ${wlanInterfaceName} IP Mask address: $wlanIpMask"
echo "[WLAN]: ${wlanInterfaceName} IP Broadcast address: $wlanIpCast"
echo "[WLAN]: ${wlanInterfaceName} Country Code: $wlanCountryCode"
echo "[WLAN]: ${wlanInterfaceName} Channel: $wlanChannel"

# REFERENCE: https://www.linuxjournal.com/content/validating-ip-address-bash-script (with my modification to check leading zero's)
validIpAddress() {
    local inIp=$1
    local ip=$inIp
    local status=1
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        
        IFS='.' read -r -a wlanIpMaskArr <<< "$wlanIpMask"
		IFS='.' read -r -a wlanIpAddrArr <<< "$wlanIpAddr"
		
		wlanIpStartWith=""
		wlanIpStartWithCount=0
		
		for i in ${!wlanIpMaskArr[@]}; do
			mskVal=${wlanIpMaskArr[$i]}
			if [ $mskVal == 255 ]; then
				if [ -z "$wlanIpStartWith" ]; then
					wlanIpStartWith="${wlanIpAddrArr[$i]}"
				else
					wlanIpStartWith="$wlanIpStartWith.${wlanIpAddrArr[$i]}"
				fi
				wlanIpStartWithCount=$((wlanIpStartWithCount+1))
			fi
		done
		
		wlanIpStartWith="$wlanIpStartWith."
		
        [[  ( $inIp != $wlanIpAddr && ! $inIp =~ ${wlanIpStartWith}* ) && \
			(( ${#ip[0]} -eq 1 && ${ip[0]} -le 255 ) || ( ${#ip[0]} -gt 1 && ${ip[0]} != 0* && ${ip[0]} -le 255 )) && \
			(( ${#ip[1]} -eq 1 && ${ip[1]} -le 255 ) || ( ${#ip[1]} -gt 1 && ${ip[1]} != 0* && ${ip[1]} -le 255 )) && \
            (( ${#ip[2]} -eq 1 && ${ip[2]} -le 255 ) || ( ${#ip[2]} -gt 1 && ${ip[2]} != 0* && ${ip[2]} -le 255 )) && \
            (( ${#ip[3]} -eq 1 && ${ip[3]} -le 255 ) || ( ${#ip[3]} -gt 1 && ${ip[3]} != 0* && ${ip[3]} -le 255 )) ]]
        
        status=$?
        
    fi
    return $status
}

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
    
    if [[ "$1" == --ap-ssid=* ]]; then
		apSsid="$(echo $1 | awk -F '=' '{print $2}')"
		if [[ "$apSsid" =~ ^[A-Za-z0-9_-]{3,}$ ]]; then
			apSsidValid=true
		fi
    fi
    
    if [[ "$1" == --ap-password=* ]]; then
		apPassphrase="$(echo $1 | awk -F '=' '{print $2}')"
        if [[ "$apPassphrase" =~ ^[A-Za-z0-9@#$%^\&*_+-]{8,}$ ]]; then
			apPassphraseValid=true
        fi
    fi
    
    if [[ "$1" == --ap-country-code=* ]]; then
		apCountryCodeTemp="$(echo $1 | awk -F '=' '{print $2}')"
		if [ ! -z "$apCountryCodeTemp" ]; then
			if [[ "${countryCodeArray[@]}" =~ "${apCountryCodeTemp}" ]]; then
                if [[ ! -z "${wlanCountryCode}" && \
                    (( ! "${countryCodeArray[@]}" =~ "${wlanCountryCode}") || \
                    ( ! "${apCountryCodeTemp}" =~ "${wlanCountryCode}")) ]]; then
                    apCountryCodeValid=false
                else
                    apCountryCodeValid=true
                    apCountryCode="$apCountryCodeTemp"
                fi
			else
				apCountryCodeValid=false
			fi
        fi
    fi
    
    if [[ "$1" == --ap-ip-address=* ]]; then
		apIpAddrTemp="$(echo $1 | awk -F '=' '{print $2}')"
		if [ ! -z "$apIpAddrTemp" ]; then
			if validIpAddress "$apIpAddrTemp"; then
				apIpAddrValid=true
                # Successful validation. Now set apIp, apDhcpRange and apSetupIptablesMasquerade:
				apIp="$apIpAddrTemp"
                IFS='.' read -r -a apIpArr <<< "$apIp"
                apIpFirstThreeDigits="${apIpArr[0]}.${apIpArr[1]}.${apIpArr[2]}"
                apIpLastDigit=${apIpArr[3]}
                div=$((apIpLastDigit/100))
                minCalcDigit=1
                maxCalcDigit=100
                case $div in
                    # Between (0-99)
                    0) minCalcDigit=$((apIpLastDigit+1)); maxCalcDigit=$((minCalcDigit+100)) ;;
                    # Between (100-199)
                    1) minCalcDigit=$((200-apIpLastDigit)); maxCalcDigit=$((minCalcDigit+100)) ;;
                    # Between (200-255)
                    2) minCalcDigit=$((256-apIpLastDigit)); maxCalcDigit=$((minCalcDigit+100)) ;;
                    *) minCalcDigit=1; maxCalcDigit=100 ;;
                        
                esac
                apDhcpRange="${apIpFirstThreeDigits}.${minCalcDigit},${apIpFirstThreeDigits}.${maxCalcDigit},12h"
                apSetupIptablesMasquerade="iptables -t nat -A POSTROUTING -s ${apIpFirstThreeDigits}.0/24 ! -d ${apIpFirstThreeDigits}.0/24 -j MASQUERADE"
			else
				apIpAddrValid=false
			fi
		fi
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
interface ${apInterfaceName}
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
    #iw dev uap0 del
    apDelCmd='iw dev '${apInterfaceName}' del'
    bash -c '$apDelCmd'
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
    
    if [ -f "$rcLocalLogFile" ]; then
        echo "[Remove]: $rcLocalLogFile"
        rm -f $rcLocalLogFile
    fi
    
    if [ -f "$shutdownRecoveryFile" ]; then
        echo "[Remove]: $shutdownRecoveryFile"
        rm -f $shutdownRecoveryFile
    fi
    
    if [ -f "$netShutdownFlagFile" ]; then
        echo "[Remove]: $netShutdownFlagFile"
        rm -f $netShutdownFlagFile
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

#If Internet is available then, install hostapd, dnsmasq, iptables-persistent from internet:
if [ $(curl -Is http://www.google.com 2>/dev/null | head -n 1 | grep -c '200 OK') -gt 0 ]; then
    echo "[Install]: installing: hostapd dnsmasq iptables-persistent from net ..."
    apt update
    if [ "$installUpgrade" = true ]; then
        apt upgrade -y
        apt dist-upgrade -y
    fi
    apt install -y hostapd dnsmasq iptables-persistent
else
    if [ -f $downloadDir/1_libnl-route-3-200.deb -a \
         -f $downloadDir/2_hostapd.deb -a \
         -f $downloadDir/3_libnfnetlink0.deb -a \
         -f $downloadDir/4_dnsmasq-base.deb -a \
         -f $downloadDir/5_dnsmasq.deb -a \
         -f $downloadDir/6_netfilter-persistent.deb -a \
         -f $downloadDir/7_iptables-persistent.deb ]; then
        echo "[Install]: installing: hostapd dnsmasq iptables-persistent from local available dependencies ..."
        dpkg --install $downloadDir/1_libnl-route-3-200.deb
        dpkg --install $downloadDir/2_hostapd.deb 
        dpkg --install $downloadDir/3_libnfnetlink0.deb 
        dpkg --install $downloadDir/4_dnsmasq-base.deb 
        dpkg --install $downloadDir/5_dnsmasq.deb 
        dpkg --install $downloadDir/6_netfilter-persistent.deb 
        dpkg --install $downloadDir/7_iptables-persistent.deb
    fi
fi

systemctl stop hostapd
systemctl stop dnsmasq

doAddDhcpdApSetup

if [ ! -f "/etc/dnsmasq.conf.orig" ]; then
    echo "[Move]: /etc/dnsmasq.conf to /etc/dnsmasq.conf.orig"
    mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
fi

cat > /etc/dnsmasq.conf <<EOF
interface=lo,${apInterfaceName}               #Use interfaces lo and ${apInterfaceName}
no-dhcp-interface=lo,${wlanInterfaceName}
bind-interfaces                 #Bind to the interfaces
server=8.8.8.8                  #Forward DNS requests to Google DNS
#domain-needed                  #Don't forward short names
bogus-priv                      #Never forward addresses in the non-routed address spaces
dhcp-range=$apDhcpRange
EOF

cat > /etc/hostapd/hostapd.conf <<EOF
channel=$apChannel
ssid=$apSsid
wpa_passphrase=$apPassphrase
interface=${apInterfaceName}
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
country_code=$apCountryCode
# I commented out the lines below in my implementation, but I kept them here for reference.
# Enable WMM
#wmm_enabled=1
# Enable 40MHz channels with 20ns guard interval
#ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
EOF

sed -i 's/^#DAEMON_CONF=.*$/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd

cat > $netStationConfigFile <<EOF 
allow-hotplug ${wlanInterfaceName}
EOF

# Create shutdown recovery script when last time shutdown did not go well.
cat > $shutdownRecoveryFile <<EOF
# ----------------------------------------------------------------------------------------------
# IMPORTANT: 
# ----------------------------------------------------------------------------------------------
# Improper shutdown/reboot by directly switching of the device or taking off the power plug
# may result in malfuctioning of Access Point (AP) Network setup or may harm other
# functionalies of the application. Hence, below script will ensure improper shutdown recovery.
# You can disable this feature by setting: 'rebootFlag=false' or 'rebootFlag=n' in this script
# or in main script: 'setup-network.sh'.
# ----------------------------------------------------------------------------------------------

if [ ! -f "$netShutdownFlagFile" ]; then
    #sudo bash -c 'echo "\$(date +"%Y-%m-%d %T") - [WARNING]: Last time shutdown did not happen properly!" >> $netLogFile'
    echo "[WARNING]: Last shutdown errors may affect Access Point(AP) Network to become non-functional!"
    echo "[SOLUTION]: Reboot system to solve the shutdown errors."
    #read -n 1 -p "Reboot System [y/n]: " "rebootFlag"
    if [ "$rebootFlag" = "y" -o "$rebootFlag" = true ]; then
        sudo $netStopFile
        echo "Rebooting in 5 seconds ..."
        sleep 5
        sudo reboot
    fi
elif [ -f "$netShutdownFlagFile" ]; then
    sudo rm -f $netShutdownFlagFile
fi

EOF

chmod ug+x $shutdownRecoveryFile

# Create startup script
cat > $netStartFile <<EOF

# Check shutdown flag file exists for proper last time shutdown 
# and if last time shutdown did not happen properly then reboot to make sure that, 
# netStop.service properly do the necessary things before shutdown:

# Output the standard errors and messages of rc.local executions to rc.local.log file.
exec 2> $rcLocalLogFile
exec 1>&2

# Attach script for improper shutdown recovery:
source $shutdownRecoveryFile


#Make sure no ${apInterfaceName} interface exists (this generates an error; we could probably use an if statement to check if it exists first)
echo "Removing ${apInterfaceName} interface..."
iw dev ${apInterfaceName} del

#Add ${apInterfaceName} interface (this is dependent on the wireless interface being called ${wlanInterfaceName}, which it may not be in Stretch)
echo "Adding ${apInterfaceName} interface..."
iw dev ${wlanInterfaceName} interface add ${apInterfaceName} type __ap

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
$apSetupIptablesMasquerade
iptables -t nat -A POSTROUTING -o ${wlanInterfaceName} -j MASQUERADE
iptables -A FORWARD -i ${wlanInterfaceName} -o ${apInterfaceName} -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i ${apInterfaceName} -o ${wlanInterfaceName} -j ACCEPT
#iptables-save > /etc/iptables/rules.v4
iptables-save > /etc/iptables.ipv4.nat
#iptables-restore < /etc/iptables.ipv4.nat

# Bring up ${apInterfaceName} interface. Commented out line may be a possible alternative to using dhcpcd.conf to set up the IP address.
#ifconfig ${apInterfaceName} 10.0.0.1 netmask 255.255.255.0 broadcast 10.0.0.255
ifconfig ${apInterfaceName} up

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

# Handle proper shutdown by touching a empty shutdown flag file:
sudo touch $netShutdownFlagFile

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
    if [ "$apSsidValid" = false -o "$apPassphraseValid" = false \
        -o "$apCountryCodeValid" = false -o "$apIpAddrValid" = false ]; then
        
errMsg='
\n
Invalid Access Point(AP) setup options are specified for installation.\n
Please provide the below [OPTION] for installation:\n
============================================================================\n
\n
'
        
        if [ "$apSsidValid" = false ]; then
errMsg=''$errMsg'

--ap-ssid\t\t\tMandatory field for installation: Set Access Point(AP) SSID. Atleast 3 chars long.\n
\t\t\t\tAllowed special chars are: _ -\n
\n'
        fi
        
        if [ "$apPassphraseValid" = false ]; then
errMsg=''$errMsg'

--ap-password\t\t\tMandatory field for installation: Set Access Point(AP) Password. Atleast 8 chars long.\n
\t\t\t\tAllowed special chars are: @ # $ %% ^ & * _ + -
'
        fi
        
        if [ "$apCountryCodeValid" = false ]; then
errMsg=''$errMsg'

 --ap-country-code\t\tOptional field for installation: Set Access Point(AP) Country Code. Default value is: '$apCountryCodeDefault'. 
\t\t\t\tMake sure that  the entered Country Code matches WiFi Country Code if it exists in /etc/wpa_supplicant/wpa_supplicant.conf
\t\t\t\tAllowed Country codes are: 
\t\t\t\t'${countryCodeArray[@]:0:20}'
\t\t\t\t'${countryCodeArray[@]:20:20}'
\t\t\t\t'${countryCodeArray[@]:40:5}'
'
        fi
        
        if [ "$apIpAddrValid" = false ]; then
errMsg=''$errMsg'
 --ap-ip-address\t\tOptional field for installation: Set Access Point(AP) IP Address. Default value is: '$apIpDefault'.
\t\t\t\tAccess Point(AP) IP address must not be equal to WiFi Station('${wlanInterfaceName}') IP address: '${wlanIpAddr}'
\t\t\t\twith its submask: '${wlanIpMask}' and broadcast: '${wlanIpCast}'

'
        fi
        
errMsg=''$errMsg'
 ----------------------------------------------------------------------------
 Example installation without upgrade:
 ----------------------------------------------------------------------------
 sudo ./setup-network.sh --install --ap-ssid="abc-1" --ap-password="password@1" --ap-country-code="IN" --ap-ip-address="192.168.0.1"
\n
 ----------------------------------------------------------------------------
 Example installation with upgrade: 
 ----------------------------------------------------------------------------
 sudo ./setup-network.sh --install-upgrade --ap-ssid="abc-1" --ap-password="password@1" --ap-country-code="IN" --ap-ip-address="192.168.0.1"
\n
'
        
        printf "${errMsg}\n"
        
        exit 0
    fi
    
    doInstall
    # Sleep for 10s before restarting:
    echo "[Reboot]: In 10 seconds ..."
    sleep 10
    reboot
fi

if [ "$cleanup" = false -a "$install" = false -a "$installUpgrade" = false ]; then
    echo '
    No Options specified for script execution.
    Usage command is sudo setup-network.sh [OPTION].
    See [OPTION] below:
    ============================================================================
    --clean             Cleans/undo all the previously made network configuration/setup.
    
    --install           Install network configuration/setup required for to make '${wlanInterfaceName}' as Access Point (AP) and Station (STA).
    
    --install-upgrade   Install & Upgrade network configuration/setup required for to make '${wlanInterfaceName}' as Access Point (AP) and Station (STA).
    
    --ap-ssid           Mandatory field for installation: Set Access Point(AP) SSID. Atleast 3 chars long. 
                        Allowed special chars are: _ -
                        
    --ap-password       Mandatory field for installation: Set Access Point(AP) Password. Atleast 8 chars long. 
                        Allowed special chars are: @ # $ % ^ & * _ + -
                        
    --ap-country-code	Optional field for installation: Set Access Point(AP) Country Code. Default value is: '$apCountryCodeDefault'. 
                        Make sure that  the entered Country Code matches WiFi Country Code if it exists in /etc/wpa_supplicant/wpa_supplicant.conf
                        Allowed Country codes are: 
                        '${countryCodeArray[@]:0:20}'
                        '${countryCodeArray[@]:20:20}'
                        '${countryCodeArray[@]:40:5}'
                        
    --ap-ip-address     Optional field for installation: Set Access Point(AP) IP Address. Default value is: '$apIpDefault'. 
                        Access Point(AP) IP address must not be equal to WiFi Station('${wlanInterfaceName}') IP address: '${wlanIpAddr}' 
                        with its submask: '${wlanIpMask}' and broadcast: '${wlanIpCast}'
        
    
    ----------------------------------------------------------------------------
    Example cleanup:
    ----------------------------------------------------------------------------
    sudo ./setup-network.sh --clean
    
    
    ----------------------------------------------------------------------------
    Example installation without upgrade: 
    ----------------------------------------------------------------------------
    sudo ./setup-network.sh --install --ap-ssid="abc-1" --ap-password="password@1" --ap-country-code="IN" --ap-ip-address="192.168.0.1"
    
    
    ----------------------------------------------------------------------------
    Example installation with upgrade: 
    ----------------------------------------------------------------------------
    sudo ./setup-network.sh --install-upgrade --ap-ssid="abc-1" --ap-password="password@1" --ap-country-code="IN" --ap-ip-address="192.168.0.1"
    
    '
    exit 0
fi
