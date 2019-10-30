# Hotspot on Single WiFi chip of Raspberry Pi - ZeroW / 3B / 3B+

Script to automate and setup Access Point and WiFi Client/Station network on the single WiFi chip of Raspberry Pi - ZeroW / 3B / 3B+.

[REFERENCE](https://lb.raspberrypi.org/forums/viewtopic.php?t=211542#p1355569)

Remember to configure the Access Point SSID and Password for your own use by changing the lines below in script:

```
apSsid="<YOUR_AP_SSID>"
apPassphrase="<YOUR_AP_SSID_PASSPHRASE>"
```
Also, ensure your access point config file meets your requirements. 
Find section that builds hostapd.conf in the script and modify:
###### /etc/hostapd/hostapd.conf

Particularly pay attention to country code and channel settings. Some user's report best result matching AP channel to WiFi Station channel.

To find your current wifi channel use:
```
iwlist channel
```
