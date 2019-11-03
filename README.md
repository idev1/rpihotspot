# Hotspot on Single WiFi chip of Raspberry Pi - ZeroW / 3B / 3B+ / 4B

Script to  automate and setup Access Point and WiFi Client/Station network on the single WiFi chip of Raspberry Pi - ZeroW / 3B / 3B+ / 4B.

Credited following [REFERENCE]: https://lb.raspberrypi.org/forums/viewtopic.php?t=211542
Although, the script is created using the thought process of the above reference link but, there are many enhancements made to solve BUGS (occurred during evaluation and testing phase) and to promote many advanced features to automate and setup the single WiFi chip of Raspberry Pi as an Access Point(AP) and Station(STA) Network both (and hence, supporting HOTSPOT feature in Raspberry Pi using the execution of this script).

# Usage command is "sudo ./setup-network.sh" [OPTION].
See [OPTION] below:
============================================================================
--clean             Cleans/undo all the previously made network configuration/setup.

--install           Install network configuration/setup required for to make wlan0 as Access Point (AP) and Station (STA).

--install-upgrade   Install & Upgrade network configuration/setup required for to make wlan0 as Access Point (AP) and Station 
                    (STA).

--ap-ssid           Mandatory field for installation: Set Access Point(AP) SSID. Atleast 3 chars long. 
					          Allowed special chars are: _ -
					
--ap-password       Mandatory field for installation: Set Access Point(AP) Password. Atleast 8 chars long. 
					          Allowed special chars are: @ # $ % ^ & * _ + -
					
--ap-country-code   Optional field for installation: Set Access Point(AP) Country Code. Default value is: IN. 
					          Make sure that  the entered Country Code matches WiFi Country Code if it exists in 
                    /etc/wpa_supplicant/wpa_supplicant.conf
					          Allowed Country codes are: 
					          AT, AU, BE, BR, CA, CH, CN, CY, CZ, DE, DK, EE, ES, FI, FR, GB, GR, HK, HU, ID,
					          IE, IL, IN, IS, IT, JP, KR, LT, LU, LV, MY, NL, NO, NZ, PH, PL, PT, SE, SG, SI,
					          SK, TH, TW, US, ZA
					
--ap-ip-address     Optional field for installation: Set Access Point(AP) IP Address. Default value is: 10.0.0.1. 
					          Access Point(AP) IP address must not be equal to WiFi Station(wlan0) IP address: 192.168.43.233 
					          with its submask: 255.255.255.0 and broadcast: 192.168.43.255
	

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
