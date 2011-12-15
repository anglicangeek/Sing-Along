require "thin"
require "sinatra/base"
require "fiber"
require "rack/fiber_pool"
require "json"

module Sinatra
  module SingAlong
    
    module Helpers
      def broadcast(event, data)
        SingAlong::broadcast(event, data)
      end
    end
    
    def on(event, &block)
      SingAlong::handlers[event] = block if block_given?
    end

    def self.registered(app)
      app.use Rack::FiberPool
      app.helpers SingAlong::Helpers
      
      app.post "/sing-along/xhr/poll" do
        request.body.rewind
        data = JSON.parse(request.body.read)
        last_message_id = data["last_message_id"] || SingAlong::get_next_message_id()
        messages = SingAlong::get_new_messages(last_message_id)
        
        if messages.length == 0
          fiber = Fiber.current
          SingAlong::callbacks << { :timestamp => Time.new, :proc => Proc.new { |messages|
            fiber.resume(messages)
          }}
          messages = Fiber.yield
        end
        
        return { :messages => messages }.to_json
      end
      
      app.post "/sing-along/xhr/send" do
        request.body.rewind
        message = JSON.parse(request.body.read)
        event, data = message["event"].to_sym, message["data"]
        handler = SingAlong::handlers[event]
        return if handler.nil?
        
        instance_exec do
          data.each do |k,v| 
            params[k.to_sym] = v
          end
        end
        instance_exec(&handler)
        
        return {}.to_json
      end
      
      app.get "/jquery.sing-along.js" do
        path = File.dirname(__FILE__)
        file = File.join(path, "/sing-along/jquery.sing-along.js")
        send_file(file)
      end
      
      EventMachine::next_tick do
        EventMachine::add_periodic_timer(1) do
          callbacks, now = SingAlong::callbacks, Time.new
          while !callbacks.empty? && now - callbacks[0][:timestamp] > 20
            callbacks.shift[:proc].call([])
          end 
        end
      end
      
      # TODO: clean up messages
    end
    
    private
    
    def self.broadcast(event, data)
      message = {
        :id => get_next_message_id(),
        :event => event,
        :data => data,
        :timestamp => Time.new }
      messages << message
      callbacks.shift[:proc].call([message]) while callbacks.length > 0
    end
    
    def self.callbacks
      @@callbacks ||= []
    end
    
    def self.handlers
      @@handlers ||= {}
    end
    
    def self.get_new_messages(last_message_id)
      new_messages = []
      return nil if messages.nil?
      messages.each { |message| new_messages << message if message[:id] > last_message_id }
      return new_messages
    end
    
    def self.get_next_message_id
      if messages.empty?
        return 1
      else
        return messages.last[:id]
      end
    end
    
    def self.messages
      @@messages ||= []
    end    
  end
  
  register SingAlong
end