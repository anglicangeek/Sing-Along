require "sinatra"
require File.join File.expand_path(File.dirname(__FILE__)), "../../lib/sinatra/sing-along"

on :echo do |data, context|
  puts data["text"]
  broadcast :echo, { :text => 'Hello from the server.' } 
end

get "/" do
  haml :index
end

__END__

@@ index
!!!
%html
  %head
    %script{ :src => 'http://code.jquery.com/jquery-1.7.js' }
    %script{ :src => '/jquery.sing-along.js' }
    :javascript
      var $on = $.singAlong.on;
      var $send = $.singAlong.send;
      
      $on("echo", function(data) {
        document.write(data.text);
      });
      
      $send("echo", { text: "Hello from the client." });
  %body
    Hello