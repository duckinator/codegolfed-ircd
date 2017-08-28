require'net/socket'
def s(x,l)x.puts l end
x=Net::Socket::TCP::Server.new('0.0.0.0',6667)
d={}
x.each_request(!!1) {|c|
n=nil
d[c] = nil
c.each_line{|l|
on=nil
if l=~/^NICK/
on=n
tn=l.split(' ').last
next s(c,":s 433 #{n||'*'} #{tn} :") if d.any?{|(_,b)|b==tn}
d[c]=n=tn
s(c,":s 001 #{n} :x") if on.nil?
end
next if n.nil?
next if l=~/PING/
cx=d.dup
cx=cx.reject{|z|z==c} if l=~/^PRIVMSG|^NOTICE/
cx.each{|(y,_)|s(y,":#{on||n}!r@h #{l}")}
c.close if l=~/^QUIT/
}}
loop{sleep 1}
