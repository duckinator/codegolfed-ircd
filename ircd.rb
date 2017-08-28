require'net/socket' # is this cheating? do I care?

# send
def s(x,l)
  puts "[SEND #{x}] #{l}"
  x.puts l
end

x=Net::Socket::TCP::Server.new('0.0.0.0',6667)
# Hash[connection => handle]
cs={}

x.each_request(true) {|c|
n=nil
cs[c] = nil

c.each_line{|l|
  puts "[RECV #{c}] #{l}"
  on=nil
  if l=~/^NICK/
    on=n
    tn=l.split(' ').last
    next s(c,":s 433 #{n||'*'} #{tn} :Nickname in use") if cs.values.include?(tn)
    cs[c]=n=tn
    s(c,":s 001 #{n} :x") if on.nil?
  end
  next if n.nil?
  next if l=~/PING/

  puts "??? #{n.inspect}"
  puts "?? cs: #{cs.inspect}"
  cx=cs.dup
  #cx-=c if l=~/PRIVMSG|NOTICE/
  cx=cx.reject{|z|z==c} if l=~/^PRIVMSG|^NOTICE/
  puts "cs: #{cs.inspect}"
  puts "cx: #{cx.inspect}"
  cx.each{|(y,_)|s(y,":#{on||n}!r@h #{l}")}
  c.close if l=~/^QUIT/
}
}

sleep 1 while true #yolo
