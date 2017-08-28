require 'socket'
server = TCPServer.new'0.0.0.0',6667
mutex = Mutex.new
clients = {}

def send(clients, c, text)
  p clients
  puts "#{c} [SEND] #{text}"
  c.puts text
rescue IOError, Errno::EPIPE => e
  warn "ERROR: #{c} send(): #{e.class}: #{e.message}"
  cmd_quit(clients, c, clients[c], e.message)
end

def send_all(clients, c, handle, message, send_back=false)
  text = ":#{handle}!u@h #{message}"
  puts "#{c} [SEND] #{text}"

  recipients = clients.keys

  unless send_back
    recipients -= [c]
  end

  recipients.each do |(r_client, r_handle)|
    send(clients, r_client, text)
  end
end

def cmd_quit(clients, c, handle, text)
  send_all(clients, c, handle, "QUIT :#{text}")
  clients.delete(c)
end

# TODO: Track per-channel.
def cmd_names(clients, c, handle, channel)
  send(clients, c, ":s 353 #{handle} @ #{channel} :#{clients.values.reject(&:nil?).join(' ')}")
  send(clients, c, ":s 366 #{handle} #{channel} :End of /NAMES list.")
end

def cmd_join(clients, c, handle, channel)
  send_all(clients, c, handle, "JOIN #{channel}", true)
  cmd_names(clients, c, handle, channel)
end

loop {
  Thread.new(server.accept) { |c|
    clients[c] = nil
    handle = nil
    quitting = false
    c.each_line { |l|
      mutex.synchronize {
        old_handle = nil

        next if l.strip.empty?

        puts "#{c.inspect} [RECV] #{handle.inspect}: #{l.inspect}"
begin
        case l
        when /^DIE/
          send_all(clients, c, "s", "NOTICE * :Shutting down.", true)
          exit
        when /^NICK (.*)/
          old_handle = handle
          temporary_handle = $1.strip
          if clients.values.include?(temporary_handle)
            send(clients, c, ":s 433 #{handle||?*} #{temporary_handle} :")
            next
          end
          clients[c] = handle = temporary_handle

          send_all(clients, c, (old_handle || handle), "NICK #{handle}", true)

          cmd_join(clients, c, handle, "#lobby") if old_handle.nil?
        when /^PING (.*)/
          send(clients, c, "PONG #{$1}")
        when /^(USER|WHO|CAP|PASS) /
          next
        when /^NAMES ([^\s]*)/
          cmd_names(clients, c, handle, $1)
        when /^JOIN ([^\s]*)/
          cmd_join(clients, c, handle, $1)
        when /^QUIT/
          quitting = true
          quit_msg = l.split(' ').last
          quit_msg = quit_msg[1..-1] if quit_msg[0] == ':'
        else
          send_all(clients, c, handle, l, l !~ /^PRIVMSG /)
        end
rescue => e
  puts "each_line: #{e.class}: #{e.message}"
  quitting = true
  quit_msg ||= e.message
end
      }

      break if quitting
    }

    cmd_quit(clients, c, clients[c], quit_msg)
    c.close rescue nil
  } # Thread.new {}
} # loop {}
