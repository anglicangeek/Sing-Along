_**NOTICE! This repo is very, very outdates and no longer maintained.**_

# Sing-Along

Sing-Along is a [Sinatra](http://sinatrarb.com) extension for quickly creating real-time web apps in Ruby with minimal effort.

_**This is an early draft of Sing-Along's Readme, written [before](http://tom.preston-werner.com/2010/08/23/readme-driven-development.html) the start of development. It's likely some details will change as Sing-Along is crafted.**_ 

## Getting Started

Start by installing the Sing-Along gem: 
    
    gem install sing-along
    
_**Note that the gem isn't available yet.**_

### Sinatra-Side

For classic-style Sinatra apps, just add a `require` call after your :

    require "sinatra"
    require "sinatra/sing-along"
    
    on :sing do |client, data|
      broadcast :song, { :lyrics => "I did it my way." }
    end
    
    # etc.
    
For modular-style Sinatra apps, you must add a `require` call and use `register`:

    require "sinatra"
    require "sinatra/sing-along"
    
    class SongBook < Sinatra::Base
      register Sinatra::SingAlong
      
      on :sing do |client, data|
        broadcast :song, { :lyrics => "I did it my way." }
      end

      # etc.
    end

### Browser-Side

In the browser, Sing-Along depends on jQuery (1.4.2 or later). You'll need to include to both jQuery and Sing-Along's script:

    <script src="/jquery-1.4.2.js"></script>
    <script src="/jquery.sing-along.js"></script>
    <script>
      var $on = $.singAlong.on;
      var $send = $.singAlong.send;
      
      $on("song", function(server, data) {
        // stuff
      });
      
      $send("sing");
      
      // etc.
    </script>

## How to Use Sing-Along

Sing-Along makes it easy to send and receive real-time messages between your Sinatra app and the web browser. Sing-Along handles things like EventMachine, fibers, connections, heartbeats, message routing, and data serialization so you can focus on the messages your real-time app needs. 

The next several sections explain how to handle and send messages both from Sinatra and the browser.

### Handling Messages In Your Sinatra App

Sing-Along extends Sinatra's DSL with `on`, which you'll use to handle messages sent to your app from the browser. `on` takes a message type (a symbol) and the block that handles that type of message. The block's arguments are the client connection and the data included in the message.

    on :say do |client, data|
      nick, text = client[:nick], data[:text]
      broadcast :said, { :from => nick, :text => text }
    end

### Sending Messages From Your Sinatra App

Sing-Along adds two helper methods to your Sinatra app: `broadcast` and `broadcast_if`. Both are used to send a message to the listening clients; `broadcast` will send the message to all clients, while `broadcast_if` will yield to the block for each client, only sending the message when the block returns true.

    # send a message to all listening clients
    get "/join" do
      nick = params[:nick]
      broadcast :joined, { :nick => nick }
    end

    # send a message to just one client
    get "/whisper" do
      to, text = params[:to], params[:text]
      broadcast_if :whispered, { :from => , :text => text } do |c|
        c[:nick] == to
      end 
    end
    
### Handling Messages In the Browser

The Sing-Along jQuery plug-in has an `on` method you will use to register message handlers in JavaScipt. The `on` method expects a message type (a string) and handler function. The handler function's arguments will be the connection to the server, as well as the data included in the message.

    <script src="/jquery.sing-along.js"></script>
    <script>
      var $on = $.singAlong.on;
      
      $on("said", function(server, data) {
        $("#chatLog").append(data.text);
      });
    </script>

### Sending Messages From the Browser

The Sing-Along jQuery plug-in also has a `send` method you will use to send messages to your Sinatra app. You must always provide a message type, and you may optionally provide message data.

    <script src="/jquery.sing-along.js"></script>
    <script>
      var $send = $.singAlong.send;
    
      $("#theForm").submit(new function() {
        $send("say", { text: $("message").value });
        $("message").value = "";
      })
    </script>

### Handling Sinatra-Side Errors

In addition to `on`, Sing-Along adds `on_error` to Sinatra's DSL; as you'd expect, it's used to handle errors. If you pass a message type to `on_error`, only errors for that message type will be handled; otherwise, all errors without an explicit error handler will be passed to the `on_error` handler without any message type specified.

    # an error handler for a specific message type:
    on_error :said do |client, error|
      puts "error for :said: #{error}"
    end
    
    # an error handler for all message types that don't have a specific error handler:
    on_error do |client, message_type, error|
      puts "#{message_type} error: #{error}"
    end

The error object passed to the handler's block will either be a string or a hash, depending on how the error was thrown . If the error was sent with just an error message (e.g., `throw "anErrorMessage"` in JavaScript), the hash will 

### Handling Browser-Side Errors

Sing-Along has a JavaScript equivalent of `on_error`, the `onError` method. As with it's server-side counterpart, you may optionally choose to handle errors for a specific error, or all errors that don't have an explicit error handler.

    <script src="/jquery.sing-along.js"></script>
    <script>
      var $onError = $.singAlong.onError;
  
      // an error handler for a specific message type
      $onError("say", function(server, error) {
        alert(error);
      });
      
      // an error handler for a specific message type
      $onError(function(server, messageType, error) {
        alert("Error for " + messageType + ": " + error);
      });
    </script>

### Configuring Transporters

Sing-Along will use WebSockets (`:websockets`) to transport messages when it's available, and XHR long-polling (`:xhr_long_polling`) otherwise.

If needed, you can configure the available transporters (for instance, when deploying to Heroku's Cedar stack, you'll want to exclude WebSockets, since they don't work there):

    set :transporters, [ :xhr_long_polling ]
