require'socket'
x=TCPServer.new'0.0.0.0',6667
g=Mutex.new
d={}
loop{Thread.new(x.accept){|c|p c;d[c]=n=nil
begin
c.each_line{|l|
puts "#{c.inspect} #{n.inspect}: #{l.inspect}";
g.synchronize{if l=~/^NICK (.*)/
m=n
t=$1.strip
next c.puts":s 433 #{n||?*} #{t} :"if d.any?{|(_,y)|y==t}
d[c]=n=t
m||c.puts(":s 001 #{n} :")end
l=~/^PI/&&next
e=d.reject{|(z,_)|z==c&&l=~/^PR/}
e.map{|(z,_)|z.puts":#{m||n}!u@h "+l}
l[0]==?Q&&c.close}}
rescue => e
$stderr.puts "#{e.class}: #{e.message}"
(d-[c]).map{|(z,_)|z.puts":#{m||n}!u@h QUIT :Server error"}
c.close rescue nil
break
end
}}
