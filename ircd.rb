require'socket'
x=TCPServer.new'0.0.0.0',6667
d={}
loop{Thread.new(x.accept){|c|d[c]=n=nil
c.each_line{|l|if l=~/^N.+ (.*)\r/
m=n
t=$1
next c.puts":s 433 #{n||?*} #{t} :"if d.any?{|(_,y)|y==t}
d[c]=n=t
m||c.puts(":s 001 #{n} :")end
l=~/^PI/&&next
e=d.reject{|(z,_)|z==c&&l=~/^PR/}
e.map{|(z,_)|z.puts":#{m||n}!u@h "+l}
l[0]==?Q&&c.close}}}
