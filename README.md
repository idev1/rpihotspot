# Hotspot on single WiFi chip of Raspberry Pi - ZeroW / 3B / 3B+ / 4B

Script to  automate and setup Access Point and WiFi Client/Station network on the single WiFi chip of Raspberry Pi - ZeroW / 3B / 3B+ / 4B.

Credited following [REFERENCE]: https://lb.raspberrypi.org/forums/viewtopic.php?t=211542.

Although, the script is created using the thought process of the above reference link but, there are many enhancements made to solve BUGS (occurred during evaluation and testing phase) and to promote many advanced features to automate and setup the single WiFi chip of Raspberry Pi as an Access Point(AP) and Station(STA) Network both (and hence, supporting HOTSPOT feature in Raspberry Pi using the execution of this script).

<pre>
<strong>
Usage command is: "sudo ./setup-network.sh [OPTION]". See [OPTION] below:
</strong>
</pre>
________________________________________________________________________________

<strong>--clean</strong>
<pre>Cleans/undo all the previously made network configuration/setup.</pre>

<strong>--install</strong>
<pre>Install network configuration/setup required to make WiFi chip as 
Access Point(AP) and Station(STA) both.</pre>

<strong>--install-upgrade</strong>
<pre>Install & Upgrade network configuration/setup required to make WiFi chip as 
Access Point(AP) and Station(STA) both.</pre>

<strong>--ap-ssid</strong>
<pre>Mandatory field for installation: Set Access Point(AP) SSID. Atleast 3 chars long. 
Allowed special chars are: _ - </pre>

<strong>--ap-password</strong>
<pre>Mandatory field for installation: Set Access Point(AP) Password. Atleast 8 chars long. 
Allowed special chars are: @ # $ % ^ & * _ + -</pre>

<strong>--ap-country-code</strong>
<pre>Optional field for installation: Set Access Point(AP) Country Code. Default value is: IN. 
Make sure that the entered Country Code matches WiFi Country Code if it exists in 
"/etc/wpa_supplicant/wpa_supplicant.conf" file.
Allowed Country codes are: AT, AU, BE, BR, CA, CH, CN, CY, CZ, DE, DK, EE, ES, FI, FR, 
GB, GR, HK, HU, ID, IE, IL, IN, IS, IT, JP, KR, LT, LU, LV, MY, NL, NO, NZ, PH, PL, PT, 
SE, SG, SI, SK, TH, TW, US, ZA</pre>

<strong>--ap-ip-address</strong>
<pre>Optional field for installation: Set Access Point(AP) IP Address. 
Default AP IP Address value is: 10.0.0.1. 
LAN/WLAN reserved private Access Point(AP) IP address must in the below range:
[10.0.0.0 – 10.255.255.255] or [172.16.0.0 – 172.31.255.255] or [192.168.0.0 – 192.168.255.255]
(Refer site: https://en.wikipedia.org/wiki/Private_network#Private_IPv4_addresses to know more 
about above IP address range).
Access Point(AP) IP address must not be equal to WiFi Station(wlan0) IP address: xxx.xxx.xxx.xxx 
with its submask: xxx.xxx.xxx.xxx and broadcast: xxx.xxx.xxx.xxx (where, the suffix xxx in the
WiFi Station IP's will be replaced by the actual WiFi Station IP's of the device once the script
is executed).
</pre>

<strong>--wifi-interface</strong>
<pre>Optional field for installation: Set hardware specific in-built WiFi interface name to be used. 
Default value is: 'wlan0'.
If an invalid WiFi interface name is provided then the installation will disregard this 
WiFi interface name and will not throw any error but, the installation will proceed with 
default in-built WiFi interface name as: 'wlan0'.
</pre>
	
----------------------------------------------------------------------------
Example cleanup:
----------------------------------------------------------------------------
<pre><code>sudo ./setup-network.sh --clean</code></pre>

----------------------------------------------------------------------------
Example installation without upgrade: 
----------------------------------------------------------------------------
<pre><code>sudo ./setup-network.sh --install --ap-ssid="abc-1" --ap-password="password@1" 
--ap-country-code="IN" --ap-ip-address="192.168.0.1" --wifi-interface="wlan0"</code></pre>

----------------------------------------------------------------------------
Example installation with upgrade: 
----------------------------------------------------------------------------
<pre><code>sudo ./setup-network.sh --install-upgrade --ap-ssid="abc-1" --ap-password="password@1" 
--ap-country-code="IN" --ap-ip-address="192.168.0.1" --wifi-interface="wlan0"</code></pre>
