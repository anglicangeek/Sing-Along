require "sinatra"
require "sinatra/sing-along"

NickRequiredError = "You must first join the chat with /join <nick>."

$nicks = []

on :join do
  nick = params[:nick]
  throw "The nickname '#{nick}' is already being used." if $nicks.include? nick
  connection[:nick] = nick
  broadcast :joined, { :nick => nick }
end

on :say do
  nick, text = connection[:nick], params[:text]
  throw NickRequiredError if nick.nil? 
  broadcast :said, { :nick => nick, :text => text }
end

on :whisper do |client, data|
  from, to, text = connection[:nick], params[:nick], params[:text]
  throw NickRequiredError } if from.nil?
  broadcast_if :whispered, { :from => from, :text => text } do |conn|
    conn[:nick] == to
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