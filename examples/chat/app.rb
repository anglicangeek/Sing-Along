require "sinatra"
require File.join(File.expand_path(File.dirname(__FILE__)), "../../lib/sinatra/sing-along")

$nicks = []

NickRequiredError = "You must first set a nickname with `/nick <nickname>`."

get '/' do
  haml :index
end

on :nick do
  nick = data[:nick]
  broadcast :error, { :text => "The nickname '#{nick}' is already being used." } and return if $nicks.include?(nick)
  connection[:nick] = nick
  broadcast :joined, { :nick => nick }
end

on :say do
  nick, text = connection[:nick], data[:text]
  broadcast :error, { :text => NickRequiredError } and return if nick.nil?
  broadcast :said, { :nick => nick, :text => text }
end

on :msg do
  from, to, text = connection[:nick], data[:nick], data[:text]
  broadcast :error, { :text => NickRequiredError } and return if nick.nil?
  broadcast_if :whispered, { :from => from, :text => text } do |c|
    c[:nick] == to
  end
end

on :quit do
  nick = connection[:nick]
  broadcast :error, { :text => NickRequiredError } and return if nick.nil?
  $nicks.delete nick
  broadcast :left, { :nick => nick }
end