# MT-TOR
Tor Proxy for Mikrotik RouterOS (arm / arm64)

Please also see the official Mikrotik guide on youtube: **[Mikrotik Setup / Configuration](https://www.youtube.com/watch?v=ECRjxpb5IgE)**

![Tor Container Screenshot](https://github.com/matthiaskonrath/mt-tor/blob/main/Screenshot%202025-12-14%20at%2013.57.52.png)
![Tor Connection](https://github.com/matthiaskonrath/mt-tor/blob/main/Screenshot%202025-12-14%20at%2013.59.08.png)

### Build and export the package (arm / arm64) by chaning the settings in `build.sh` and running it
```
nano build.sh
./build.sh
```

## This config is intended for direct us in a clean default setup
### Setup the network
```
/interface/veth/add name=veth1 address=172.17.0.2/24 gateway=172.17.0.1
/interface/bridge/add name=tor_bridge
/ip/address/add address=172.17.0.1/24 interface=tor_bridge
/interface/bridge/port add bridge=tor_bridge interface=veth1
```

### Add interfaces to the tor bridge (these will only have access to the internet via tor)
```
/interface/bridge/port add bridge=tor_bridge interface=TODO
```

### Add the tor bridge to the LAN interface list
```
/interface/list/member/add comment=defconf interface=tor_bridge list=LAN
```

### Allow only the tor proxy internet access
(`place-before` looks like it is in the wrong order, but it works)
```
/ip/firewall/filter/add src-address=172.17.0.2 dst-address=0.0.0.0/0 chain=forward action=accept out-interface-list=WAN place-before=0
/ip/firewall/filter/add src-address=172.17.0.0/24 chain=forward action=drop out-interface-list=WAN place-before=0
```

### Setup the tor proxy and add firewall rules to allow only tor traffic
```
/ip/socksify/add name=tor socks5-port=9050 socks5-server=172.17.0.2 disabled=no
/ip/firewall/nat/add chain=dstnat action=accept protocol=tcp src-address=172.17.0.2 place-before=0
/ip/firewall/nat/add chain=dstnat action=socksify protocol=tcp socksify-service=tor src-address=172.17.0.0/24 place-before=0
```

### Set the DNS server of the default network to cloudflare (is prevents delays and disruptions)
```
/ip/dhcp-server/network/set dns-server=1.1.1.1 numbers=0
```

### Create a DHCP pool and service for the tor traffic
```
/ip/pool/add name=tor_pool ranges=172.17.0.10-172.17.0.254
/ip/dhcp-server/add address-pool=tor_pool interface=tor_bridge name=tor_dhcp
/ip dhcp-server/network/add address=172.17.0.0/24 dns-server=172.17.0.1 gateway=172.17.0.1
```

### Download certificates for DoH
```
/tool fetch url=https://curl.se/ca/cacert.pem
```

### Import Certificats for DoH
```
/certificate import file-name=cacert.pem
```

### Setup the DoH service
```
/ip dns set servers=1.1.1.1
/ip dns set use-doh-server=https://1.1.1.1/dns-query verify-doh-cert=yes
```

### Send DoH only over tor
```
/ip/firewall/nat/add chain=output action=socksify socksify-service=tor protocol=tcp dst-address=1.1.1.1
```

### Import the container
```
/container/add file=mt-tor-arm64.tar interface=veth1 logging=yes
```

### Configure and start the tor container
(the DNS setting is important, otherwise it can't establish a connection with the tor servers)
```
/container/set mt-tor-arm64 start-on-boot=yes auto-restart-interval=300 dns=1.1.1.1
/container/start mt-tor-arm64
```

### Clear all estblished connections (or reboot)
```
/ip/firewall/connection/remove [f]
```


Relevant links:
- https://help.mikrotik.com/docs/display/ROS/Container
- https://docs.docker.com/build/building/multi-platform/
- https://help.mikrotik.com/docs/spaces/ROS/pages/343244851/Socksify

Check your IP / Tor status:
- https://check.torproject.org/?lang=en_US
- https://www.whatismyip.com
