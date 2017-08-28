require'net/socket'
def s(x,l)x.puts l end
x=Net::Socket::TCP::Server.new('0.0.0.0',6667)
d={}
x.each_request(!!1) {|c|
n=nil
d[c] = nil
c.each_line{|l|
m=nil
if l=~/^NI/
m=n
tn=l.split(' ').last
next s(c,":s 433 #{n||'*'} #{tn} :") if d.any?{|(_,b)|b==tn}
d[c]=n=tn
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
