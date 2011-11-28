/*
 * jquery.sing-along - A jQuery plugin for for quickly creating real-time web apps along with Ruby and Sinatra, with minimal effort.
 * 
 * http://github.com/anglicangeek/sing-along
 *
 * Copyright (c) 2011 Andrew Miller <ego@anglicangeek.com>
 * Licensed under the MIT license (see LICENSE.txt).
 */

// todo: add onError for handling errors for a given message type?
 
(function($) {
  
  var connectionContext = null, handlers = [];

	function findHandler(messageType) {
		for (var n = 0; n < handlers.length; n++) {
			var handler = handlers[n];
      if (handler.messageType == messageType)
        return handler
			return null;
    }
	}

	function handleMessage(messageType, data) {
		var handler = findHandler(messageType);
		if (handler == null)
			return; // todo: a callback for when a message type isn't handled?
		handler.callback(data);
	}

	function poll(lastTimestamp, context) {
	  $.ajax({ 
			cache: false,
			type: "POST", 
			url: "sing-along/xhr/poll", 
			dataType: "json", 
			data: JSON.stringify({ context: context }), 
			error: function(jqXHR, textStatus, errorThrown) {
			  // todo: track polling errors and slow down the attempts to poll
      }, 
			success: function(data) {
        // todo: reset polling errors
				connectionContext = data.context;
				var messages = data.messages;
				setTimeout(function() { 
					for (var n = 0; n < messages.length; n++) {
						var message = messages[n];
						handleMessage(message.message_type, message.message_data)
					}
				}, 0);
        poll(data.context);
			}
		});
	}
	
	poll(null, null);
      
  $.singAlong = { 

    on: function(messageType, callback) { 
			var handler = findHandler(messageType);
			if (handler != null)
				throw "A handler for message type " + messageType + " is already registered.";
		
     	handlers.push({
        messageType: messageType,
        callback: callback
      });
    },

    send: function(messageType, data) {
			$.ajax({ 
				cache: false,
				type: "POST", 
				url: "sing-along/xhr/send", 
				dataType: "json", 
				data: JSON.stringify({ 
					message_type: messageType,
					message_data: data,
					connection_context: connectionContext }), 
				error: function () {
				  // todo: call an errback?
	      }, 
				success: function (data) {
	        // todo: call a callback?
				}
			});
    }

  };
  

})(jQuery);