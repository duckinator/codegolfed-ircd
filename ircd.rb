require'net/socket'
def s(x,l)x.puts l end
x=Net::Socket::TCP::Server.new('0.0.0.0',6667)
d={}
x.each_request(!!1){|c|
d[c]=n=nil
c.each_line{|l|
m=nil
if l=~/^NICK (.*)\r/
m=n
t=$1
next s(c,":s 433 #{n||'*'} #{t} :") if d.any?{|(_,b)|b==t}
d[c]=n=t
m||s(c,":s 001 #{n} :x")
end
next if !n
next if l=~/^PI/
cx=d.dup
cx=cx.reject{|z|z==c} if l=~/^PR|^NO/
cx.each{|(y,_)|s(y,":#{m||n}!r@h #{l}")}
c.close if l=~/^Q/
}}
loop{sleep 1}
