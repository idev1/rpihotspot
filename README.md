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

<strong>--ap-password-encrypt</strong>
<pre>Optional field for installation. If specified, it will encrypt password in hostapd.conf file for security reason.</pre>

<strong>--ap-country-code</strong>
<pre>Optional field for installation: Set Access Point(AP) Country Code. Default value is: IN. 
Make sure that the entered Country Code matches WiFi Country Code if it exists in 
"/etc/wpa_supplicant/wpa_supplicant.conf" file.
Allowed Country codes are: 
AD, AE, AF, AG, AI, AL, AM, AO, AQ, AR, AS, AT, AU, AW, AX, AZ, BA, BB, BD, BE, BF, BG, BH, BI, BJ, BL, BM, BN, BO, BQ,
BR, BS, BT, BV, BW, BY, BZ, CA, CC, CD, CF, CG, CH, CI, CK, CL, CM, CN, CO, CR, CU, CV, CW, CX, CY, CZ, DE, DJ, DK, DM,
DO, DZ, EC, EE, EG, EH, ER, ES, ET, FI, FJ, FK, FM, FO, FR, GA, GB, GD, GE, GF, GG, GH, GI, GL, GM, GN, GP, GQ, GR, GS,
GT, GU, GW, GY, HK, HM, HN, HR, HT, HU, ID, IE, IL, IM, IN, IO, IQ, IR, IS, IT, JE, JM, JO, JP, KE, KG, KH, KI, KM, KN,
KP, KR, KW, KY, KZ, LA, LB, LC, LI, LK, LR, LS, LT, LU, LV, LY, MA, MC, MD, ME, MF, MG, MH, MK, ML, MM, MN, MO, MP, MQ,
MR, MS, MT, MU, MV, MW, MX, MY, MZ, NA, NC, NE, NF, NG, NI, NL, NO, NP, NR, NU, NZ, OM, PA, PE, PF, PG, PH, PK, PL, PM,
PN, PR, PS, PT, PW, PY, QA, RE, RO, RS, RU, RW, SA, SB, SC, SD, SE, SG, SH, SI, SJ, SK, SL, SM, SN, SO, SR, SS, ST, SV,
SX, SY, SZ, TC, TD, TF, TG, TH, TJ, TK, TL, TM, TN, TO, TR, TT, TV, TW, TZ, UA, UG, UM, US, UY, UZ, VA, VC, VE, VG, VI,
VN, VU, WF, WS, YE, YT, ZA, ZM, ZW</pre>

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
<pre><code>sudo ./setup-network.sh --install --ap-ssid="abc-1" --ap-password="password@1" --ap-password-encrypt 
--ap-country-code="IN" --ap-ip-address="192.168.0.1" --wifi-interface="wlan0"</code></pre>

----------------------------------------------------------------------------
Example installation with upgrade: 
----------------------------------------------------------------------------
<pre><code>sudo ./setup-network.sh --install-upgrade --ap-ssid="abc-1" --ap-password="password@1" --ap-password-encrypt 
--ap-country-code="IN" --ap-ip-address="192.168.0.1" --wifi-interface="wlan0"</code></pre>
