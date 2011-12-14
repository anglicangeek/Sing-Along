require "sinatra"
require File.join(File.expand_path(File.dirname(__FILE__)), "../../lib/sinatra/sing-along")

on :echo do
  broadcast :echo, { :text => params[:text] } 
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
      
      $(document).ready(function() {
        $('#echo').submit(function() {
          $send("echo", { text: $('#text').val() });
          $('#text').val('');
          return false;
        });
      });
      
      $on('echo', function(data) {
        $('#echoes').append('<li>' + data.text + '</li>');
      });
  %body
    %form#echo{ :name=>'echo', :action=>'#' }
      %input#text{ :name=>'text', :type=>'text'}
      %input{ :type=>'submit', :value=>'Echo'}
    %label{ :for=>'echoes' }
      Echoes:
    %ul#echoes