require 'socket'

class Ircd
  # Ping timeouts.
  TIMEOUT = 69
  TIMEOUT_CHECK_INTERVAL = TIMEOUT * 4


  def initialize
    @server = TCPServer.new('0.0.0.0', 6667)
    @mutex = Mutex.new

    @last_sent_times = {}
    @last_received_times = {}

    @clients = {}
  end

  def send(c, text)
    @last_sent_times[c] = Time.now.to_i
    puts "#{c} [SEND] #{text}"
    c.puts text
  rescue IOError, Errno::EPIPE => e
    warn "ERROR: #{c} send(): #{e.class}: #{e.message}"
    cmd_quit(c, @clients[c], e.message)
  end

  def send_all(c, handle, message, send_back=false)
    text = ":#{handle}!u@h #{message}"
    puts "#{c} [SEND] #{text}"

    recipients = @clients.keys

    unless send_back
      recipients -= [c]
    end

    recipients.each do |(r_client, r_handle)|
      send(r_client, text)
    end
  end

  def cmd_quit(c, handle, text)
    send_all(c, handle, "QUIT :#{text}")
    @clients.delete(c)
  end

  # HACK: This returns every user on the server.
  # TODO: Track per-channel.
  def cmd_names(c, handle, channel)
    send(c, ":s 353 #{handle} @ #{channel} :#{@clients.values.reject(&:nil?).join(' ')}")
    send(c, ":s 366 #{handle} #{channel} :End of /NAMES list.")
  end

  def cmd_join(c, handle, channel)
    send_all(c, handle, "JOIN #{channel}", true)
    cmd_names(c, handle, channel)
  end

  def spawn_ping_timeout_loop
    Thread.new {
      loop {
        sleep TIMEOUT_CHECK_INTERVAL

        @clients.each do |c, handle|
          mutex.synchronize {
            if (@last_received_times[c] - @last_sent_times[c]) > TIMEOUT
              cmd_quit(c, handle, "Ping timeout: #{TIMEOUT} seconds")
              sent.delete(c)
              received.delete(c)
              next
            end

            pings_sent[c] = Time.now.to_i
            c.send("PING :#{Time.to_s}")
          }
        end
      }
    }
  end

  def despair
    spawn_ping_timeout_loop

    loop {
      Thread.new(@server.accept) { |c|
        @clients[c] = nil
        handle = nil
        quitting = false
        quit_msg = nil

        c.each_line { |l|
          @last_received_times[c] = Time.now.to_i

          @mutex.synchronize {
            still_connecting = true
            old_handle = nil

            next if l.strip.empty?

            puts "#{c.inspect} [RECV] #{handle.inspect}: #{l.inspect}"
            begin
              case l
              when /^DIE/
                send_all(c, "s", "NOTICE * :Shutting down.", true)
                exit
              when /^NICK (.*)/
                old_handle = handle
                temporary_handle = $1.strip

                if @clients.values.include?(temporary_handle)
                  failed_handle = temporary_handle
                  send(c, ":s 433 #{handle||?*} #{temporary_handle} :Nickname is already in use.")
                  next
                end

                @clients[c] = handle = temporary_handle

                if old_handle
                  send_all(c, old_handle, "NICK #{handle}", true)
                end

                if still_connecting
                  still_connecting = false
                  send(c, ":s 001 #{handle} :Welcome!")
                end

                cmd_join(c, handle, "#lobby") if old_handle.nil?
              when /^PONG (.*)/
              when /^PING (.*)/
                send(c, "PONG #{$1}")
              when /^(USER|WHO|CAP|PASS) /
                next
              when /^NAMES ([^\s]*)/
                cmd_names(c, handle, $1)
              when /^JOIN ([^\s]*)/
                cmd_join(c, handle, $1)
              when /^QUIT/
                quitting = true
                quit_msg = l.split(':', 2).last
                quit_msg = quit_msg[1..-1] if quit_msg[0] == ':'
              else
                send_all(c, handle, l, l !~ /^PRIVMSG /)
              end
            rescue => e
              puts "each_line: #{e.class}: #{e.message}"
              quitting = true
              quit_msg ||= e.message
            end
          }

          break if quitting
        }

        cmd_quit(c, @clients[c], quit_msg)
        c.close rescue nil
      } # Thread.new {}
    } # loop {}
  end
end

ircd = Ircd.new
ircd.despair
