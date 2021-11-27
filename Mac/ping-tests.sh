#!/bin/bash

### Test ping to local router
router_ip=$(netstat -rn |grep default | awk {'print $2'} | head -1) 
echo "Router IP: " $router_ip
echo "Average ping to router: "$(ping -c 5 $router_ip | tail -1| awk '{print $4}' | cut -d '/' -f 2)

### Test ping to local public IP address (tests connection from router to ISP modem)
isp_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
echo "ISP IP: " $isp_ip
echo "Average ping to ISP IP: "$(ping -c 5 $isp_ip | tail -1| awk '{print $4}' | cut -d '/' -f 2)

### Test ping to Google public DNS server
echo "Average ping to 8.8.8.8: " $(ping -c 5 8.8.8.8 | tail -1| awk '{print $4}' | cut -d '/' -f 2)

### Dumps ifconfig
echo "Network Interface Configuration"
echo $(ifconfig)