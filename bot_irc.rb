require 'cinch'
require 'redis'

class Botcommand
  def initialize(command_name, regexpression, log = true)
    @command = command_name
    @regexpression = regexpression
    @log = log
  end

  def log?()
    @log
  end

  def TOGGLE_LOG()
    @log = !(@log)
  end

  def get_command_name()
    @command_name
  end

  def set_command_name(command_name)
    @command_name = command_name
  end

  def get_regexp()
    puts @regexpression
    @regexpression
  end

  def set_regexp(regexpression)
    @regexpression = regexpression
  end
end

# Key variable
  #type = 3
  #key="#{Time.now.month}-#{Time.now.year}-#{Time.now.day}-#{type}"
key = ARGV[0]

# Name of the bot
bot_name = "BOT_MTSH"

#Server and channel details
SERVER_ADDRESS = "irc.freenode.org"
CHANNELS = ["#nitk-droid","#nitk-autobotz"]

# Location of log and logging variable should be initially false
logging = {}
CHANNELS.each do |chan|
  logging[chan] = false
end
LOG_LOCATION = "http://localhost:4567"

# Following are the command objects
TOGGLE_LOG = Botcommand.new("ToggleLog", /\A[!][sS]\z/ ,true)
HELLO_USER = Botcommand.new("HelloUser", /\A[!][Hh][eE][lL][lL][oO]\z/,true)
LOCATE_LOG = Botcommand.new("LocateLog", /\A[!][Ll][Oo][Gg]\z/ ,false)
ENABLE_LOG = Botcommand.new("LogStatus", /\A[!][Ll][Oo][Gg][_][Ss][Tt][Aa][Tt]\z/ ,false)
LOL = Botcommand.new("L.O.L", /\A[!][Ll][Oo][Ll]\z/ ,false)
ASK_TIME = Botcommand.new("Time", /\A[!][tT][iI][mM][eE]\z/ ,false)
USERS_LIST = Botcommand.new("UsersList",/\A[!][uU][sS][eE][rR][sS]\z/, false)
USERS_COUNT = Botcommand.new("UsersList",/\A[!][uU][sS][eE][rR][_][cC][oO][Uu][nN][tT]\z/, false)
COMMAND_LIST = Botcommand.new("CommandList(Help)",/(\A[!][cC][oO][mM][mM][sS]\z|\A[!][hH][eE][lL][pP]\z)/, false)

old_user_count = 0
new_user_count = 0

bot = Cinch::Bot.new do
  redis = Redis.new(:host => '127.0.0.1', :port => 6379)
  configure do |c|
    c.server = SERVER_ADDRESS
    c.channels = CHANNELS
    c.nick = bot_name  
  end
  
# The following code is the handler for the command to toggle log 
on :message,TOGGLE_LOG.get_regexp do |m|
  logging[m.channel.to_s] = !logging[m.channel.to_s]
  if( logging[m.channel.to_s] ) then 
    reply_string = "=========================Logging for #{m.channel} started at #{Time.now.asctime}========================================="
    m.reply(reply_string)
    if ( TOGGLE_LOG.log? ) then
      redis.LPUSH key , reply_string
      reply_string = m.channel.to_s+" - Users: "
      m.channel.users.each do |f|
        reply_string += f[0].to_s+" "
      end
      redis.LPUSH key , "#{reply_string}"  
      reply_string = m.channel.to_s+" - Number of users"
      redis.LPUSH key , "#{reply_string} is #{m.channel.users.length}"

    end
  elsif ( !logging[m.channel.to_s] ) then
    reply_string = "=========================Logging for #{m.channel} stopped at #{Time.now.asctime}========================================="
    m.reply(reply_string)
    if ( TOGGLE_LOG.log? ) then
      redis.LPUSH key , reply_string
      reply_string = m.channel.to_s+" - Users: "
      m.channel.users.each do |f|
        reply_string += f[0].to_s+" "
      end
      redis.LPUSH key , "#{reply_string}"  
      reply_string = m.channel.to_s+" - Number of users"
      redis.LPUSH key , "#{reply_string} is #{m.channel.users.length}"
    end
      text = redis.get(key)
      redis.save
  end
end


# The following code is the handler for the command to say hello
on :message, HELLO_USER.get_regexp do |m|
  reply_string = "Hello #{m.user.nick}. How are you ?! Never mind, already too bored"
  m.reply(reply_string)
  if( logging[m.channel.to_s] && HELLO_USER.log? ) then
    redis.LPUSH key , bot_name+": "+reply_string
  end
end


# The following code is the handler for the command to get location of logs
on :message,LOCATE_LOG.get_regexp do |m|
  reply_string = "#{m.user.nick}: The log can be found here - "+LOG_LOCATION
  m.reply(reply_string)
  if( logging[m.channel.to_s] && LOCATE_LOG.log? ) then
    redis.LPUSH key , bot_name+": "+reply_string
  end
end

# The following code is the handler for the command to find whether logging is enabled
on :message,ENABLE_LOG.get_regexp do |m|
  if ( logging[m.channel.to_s] ) then
    reply_string = "#{m.user.nick}: The conversation is being logged"
  else
    reply_string = "#{m.user.nick}: The conversation is not being logged"
  end
  m.reply(reply_string)
  if( logging[m.channel.to_s] && ENABLE_LOG.log? ) then
    redis.LPUSH key , bot_name+": "+reply_string
  end
end


# The following code is the handler for the command for nothing..... just a random command
on :message,LOL.get_regexp do |m|
  reply_string = "#{m.user.nick}: Is it so funny ?! I don't think so.... :| "
  m.reply(reply_string)
  #puts m.channel
  #puts "--------------------"
  if( logging[m.channel.to_s] && LOL.log? ) then
    redis.LPUSH key , bot_name+": "+reply_string
  end
end


# The following code is the handler for the command for current time
on :message,ASK_TIME.get_regexp do |m|
  reply_string = "#{m.user.nick}: The Time is #{Time.now.asctime}"
  m.reply(reply_string)
  if(logging[m.channel.to_s] && ASK_TIME.log? ) then
    redis.LPUSH key , bot_name+": "+reply_string
  end
end

# The following is for prefixing the log statements with time and log if a user leaves or is added
on :message do |m|
  new_user_count = m.channel.users.length

  if ( old_user_count != new_user_count ) then
    reply_string = m.channel.to_s+" - Users: "
    m.channel.users.each do |f|
      reply_string += f[0].to_s+" "
    end
    if ( logging[m.channel.to_s] ) then
      redis.LPUSH key , "#{reply_string}"
    end
    reply_string = m.channel.to_s+" - Number of users"
    if ( logging[m.channel.to_s] ) then
      redis.LPUSH key , "#{reply_string} is #{m.channel.users.length}"
    end
    old_user_count = new_user_count
  end

  if(logging[m.channel.to_s]) then
  logPrefixString = "%s - <%02d:%02d> " % [m.channel,Time.now.hour, Time.now.min]
  #redis.LPUSH key , "<#{Time.now.hour}:#{Time.now.min}> "+m.user.nick+": "+(m.params[1]).to_s
  redis.LPUSH key , logPrefixString+m.user.nick+" : "+(m.params[1]).to_s
  end

end

# The following is for a list of users
on :message,USERS_LIST.get_regexp do |m|
  reply_string = "Users: "
  m.channel.users.each do |f|
    reply_string += f[0].to_s+" "
  end
  m.reply("#{reply_string}")
  if(logging && USERS_LIST.log? ) then
   #redis.LPUSH key , "<#{Time.now.hour}:#{Time.now.min}> "+m.user.nick+": "+(m.params[1]).to_s
    redis.LPUSH key , "#{reply_string}"
  end
end

# The following is for a count of the number of users
on :message,USERS_COUNT.get_regexp do |m|
  reply_string = "Number of users"
  m.reply("#{reply_string} is #{m.channel.users.length}")
  if(logging[m.channel.to_s] && USERS_COUNT.log? ) then
    #redis.LPUSH key , "<#{Time.now.hour}:#{Time.now.min}> "+m.user.nick+": "+(m.params[1]).to_s
    redis.LPUSH key , "#{reply_string} is #{m.channel.users.length}"
  end
end

# The following is for listing the commands
on :message,COMMAND_LIST.get_regexp do |m|
  reply_string = '!log_stat, !s, !log, !time, !lol, !hello, !users, !user_count, !comms( or !help)  Note : They are not case sensitive'
  m.reply("#{reply_string}")
  if(logging[m.channel.to_s] && COMMAND_LIST.log? ) then
    #redis.LPUSH key , "<#{Time.now.hour}:#{Time.now.min}> "+m.user.nick+": "+(m.params[1]).to_s
    redis.LPUSH key , "#{reply_string}"
  end
end

end

bot.start