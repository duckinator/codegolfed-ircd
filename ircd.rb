require'socket'
def s(x,l)x.puts l end
x=TCPServer.new('0.0.0.0',6667)
d={}
loop{Thread.new(x.accept){|c|d[c]=n=nil
c.each_line{|l|m=nil
if l=~/^N.+ (.*)\r/
m=n
t=$1
next s(c,":s 433 #{n||'*'} #{t} :") if d.any?{|(_,b)|b==t}
d[c]=n=t
m||s(c,":s 001 #{n} :")end
n&&l=~/^PI/&&next
e=d.reject{|(z,_)|z==c&&l=~/^PR|^NO/}
e.each{|(y,_)|s(y,":#{m||n}!r@h #{l}")}
l[0]==?Q&&c.close}}}
