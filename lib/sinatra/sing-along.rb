require "thin"
require "sinatra/base"
require "fiber"
require "rack/fiber_pool"
require "json"

module Sinatra
  module SingAlong

    class LocalConnectionStore
      def initialize
        @last_id = 0
      end
      
      def create
        id = next_id
        connections[id] = {
          :id => id,
          :timestamp => Time.new }
      end
      
      def [](id)
        connections[id]
      end
      
      private
      
      def connections
        @connections ||= {}
      end
      
      def next_id
        @last_id += 1
      end
    end
    
    module Helpers
      def broadcast(event, data)
        SingAlong::broadcast event, data
      end
      
      def connection
        @connection
      end
            
      private
      
      def connection=(value)
        @connection = value
      end
      
      def read_message
        request.body.rewind
        return JSON.parse request.body.read
      end
    end
    
    def on(event, &block)
      SingAlong::handlers[event] = block if block_given?
    end

    def self.registered(app)
      app.use Rack::FiberPool
      app.helpers SingAlong::Helpers
      
      app.get "/jquery.sing-along.js" do
        path = File.dirname __FILE__
        file = File.join path, "/sing-along/jquery.sing-along.js"
        send_file file
      end
      
      app.post "/sing-along/xhr/connect" do
        connection = SingAlong::connections.create
        return { :cid => connection[:id] }.to_json
      end
      
      app.post "/sing-along/xhr/poll" do
        message = read_message
        cid, last_message_id = message["cid"], message["last_message_id"] || SingAlong::get_next_message_id
        connection = SingAlong::connections[cid]
        # TODO: what to do when cid is bad?
        return if connection.nil?
        
        messages = SingAlong::get_new_messages last_message_id
        if messages.length == 0
          fiber = Fiber.current
          SingAlong::callbacks << { :timestamp => Time.new, :proc => Proc.new { |messages|
            fiber.resume messages
          }}
          messages = Fiber.yield
        end
        
        return { :messages => messages }.to_json
      end
      
      app.post "/sing-along/xhr/send" do
        message = read_message
        cid, event, data = message["cid"], message["event"].to_sym, message["data"]
        connection = SingAlong::connections[cid]
        handler = SingAlong::handlers[event]
        # TODO: what to do when cid is bad?
        return if connection.nil? || handler.nil?
        
        instance_exec(connection, data) do |c, d|
          connection = c
          d.each do |k,v| 
            params[k.to_sym] = v
          end
        end
        instance_exec(&handler)
        
        return {}.to_json
      end
      
      app.post "/sing-along/xhr/disconnect" do
        message = read_message
        cid = message[:cid]
        return if cid.empty?
        SingAlong::connections.delete cid
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
    
    def self.connections
      @@connections ||= LocalConnectionStore.new
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