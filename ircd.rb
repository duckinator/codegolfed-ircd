require'net/socket'
def s(x,l)x.puts l end
x=Net::Socket::TCP::Server.new('0.0.0.0',6667)
cs={}
x.each_request(true) {|c|
n=nil
cs[c] = nil
c.each_line{|l|
on=nil
if l=~/^NICK/
on=n
tn=l.split(' ').last
next s(c,":s 433 #{n||'*'} #{tn} :") if cs.any?{|(_,b)|b==tn}
cs[c]=n=tn
s(c,":s 001 #{n} :x") if on.nil?
end
next if n.nil?
next if l=~/PING/
cx=cs.dup
cx=cx.reject{|z|z==c} if l=~/^PRIVMSG|^NOTICE/
cx.each{|(y,_)|s(y,":#{on||n}!r@h #{l}")}
c.close if l=~/^QUIT/
}}
loop{sleep 1}
