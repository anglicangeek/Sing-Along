require "sinatra"
require "sinatra/sing-along"

NickRequiredError = "You must first join the chat with /join <nick>."

$nicks = []

on :join do |client, data|
  nick = data[:nick]
  throw "The nickname '#{nick}' is already being used." if $nicks.include? nick
  client[:nick] = nick
  broadcast :joined, { :nick => nick }
end

on :say do |client, data|
  nick, text = client[:nick], data[:text]
  throw NickRequiredError } if nick.nil? 
  broadcast :said, { :nick => nick, :text => text }
end

on :whisper do |client, data|
  from, to, text = client[:nick], data[:nick], data[:text]
  throw NickRequiredError } if from.nil?
  broadcast_if :whispered, { :from => from, :text => text } do |c|
    c[:nick] == to
  end
end

on :leave do |client, data|
  nick = client[:nick]
  throw NickRequiredError } if nick.nil?
  $nicks.delete nick
  broadcast :left, { :nick => nick }
end

get '/' do
  haml :home
end

__END__

@@ home
%div.title Hello world!!!!!