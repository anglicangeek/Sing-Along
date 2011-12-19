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
  
  var cid = null, handlers = [];

	function findHandler(event) {
		for (var n = 0; n < handlers.length; n++) {
			var handler = handlers[n];
      if (handler.event == event)
        return handler
    }
		return null;
	}

	function handleMessage(event, data) {
		var handler = findHandler(event);
		if (handler == null)
			return; // todo: a callback for when a message type isn't handled?
		handler.callback(data);
	}

	function poll(lastMessageId, context) {
		$.ajax({ 
			cache: false,
			type: "POST", 
			url: "sing-along/xhr/poll", 
			dataType: "json", 
			data: JSON.stringify({ 
				cid: cid,
				last_message_id: lastMessageId 
			}), 
			error: function(jqXHR, textStatus, errorThrown) {
			  // todo: track polling errors and slow down the attempts to poll
      }, 
			success: function(data) {
        // todo: reset polling errors
				var messages = data.messages;
				setTimeout(function() { 
					for (var n = 0; n < messages.length; n++) {
						var message = messages[n];
						handleMessage(message.event, message.data)
						lastMessageId = message.id;
					}
				}, 0);
        poll(lastMessageId, data.context);
			}
		});
	}
	
	$.ajax({ 
		cache: false,
		type: "POST", 
		url: "sing-along/xhr/connect", 
		dataType: "json", 
		error: function () {
		  // todo: retry?
		}, 
		success: function (data) {
      cid = data.cid;
			poll(null, null);
		}
	});
      
  $.singAlong = { 

    on: function(event, callback) { 
			var handler = findHandler(event);
			if (handler != null)
				throw "A handler for event " + event + " is already registered.";
		
     	handlers.push({
        event: event,
        callback: callback
      });
    },

    send: function(event, data) {
			$.ajax({ 
				cache: false,
				type: "POST", 
				url: "sing-along/xhr/send", 
				dataType: "json", 
				data: JSON.stringify({ 
					cid: cid,
					event: event,
					data: data 
				}), 
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