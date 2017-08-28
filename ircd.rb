# Not really golfing any more; just trying to make a proper IRCd.

# TODO:
#
# 1. Make PMs work right.
#   a. user->user PMs only go to that user,
#   b. user->channel PMs only go to that channel.
#      * This requires tracking channels. Kind of. Maybe?
# 2. Server <-> server communication, because why the fuck not.

require'socket'

class Ircd
  def parse(line)
    line = line.strip

    # type = PRIVMSG, NOTICE, JOIN, PART, NICK, USER, etc
    parts = line.split(' ')
    index = parts.index { |part| part[0] == ':' }

    type, *params = line.split(' ', index - 2)
    params[-1] = params.last[1..-1] if params.last.start_with?(':')

    [type, params]
  end

  def send_to(client, recipient, message)

  end

  def handle(clients, client, line)
    type, params = parse(line)

    case type
    when PRIVMSG
      send_to(client, *params)
    end
  end

  def blargh
    x = TCPServer.new('0.0.0.0', 6667)

    last_uid = 0
    users = {}
    connections = []

    loop {
      Thread.new(x.accept) { |c|
        last_uid += 1
        id = last_uid
        users[id]=nil
        connections << c
        nickname = nil
        c.each_line { |line|
          handle(connections, c, line)
          if l=~/^N.+ (.*)/
            m=n
            t=$1.strip
            next c.puts":s 433 #{n||?*} #{t} :"if u.any?{|(_,y)|y==t}
            u[id]=n=t
            m||c.puts(":s 001 #{n} :")
          end
          l=~/^PI/&&next
          cx=cs.reject{|d|d==Thread.current&&l=~/^PR/}
          cx.map{|d|d.puts":#{m||n}!u@h "+l}
          p u
          p cs
          l[0]==?Q&&c.close
        }
      }
    }
  end
end
