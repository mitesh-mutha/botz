require 'sinatra'
require 'redis'
#set :environment, :production #For ip:4567 , comment this to get localhost:4567
key="#{Time.now.month}-#{Time.now.year}-#{Time.now.day}"
redis = Redis.new(:host => '127.0.0.1', :port => 6379)
get '/' do
	len = redis.LLEN key
	data = redis.lrange(key,0,len)
	data.reverse.join("<br />")
end