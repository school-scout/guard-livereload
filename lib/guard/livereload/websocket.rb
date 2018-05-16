require 'eventmachine'
require 'em-websocket'
require "http/parser"
require 'uri'

module Guard
  class LiveReload
    class WebSocket < EventMachine::WebSocket::Connection
      def dispatch data
        parser = Http::Parser.new
        parser << data
        if parser.http_method != 'GET' || parser.upgrade?
          super #pass the request to websocket
        elsif URI.parse(parser.request_url).path == '/livereload.js'
          serve_file File.expand_path("../../../../js/livereload.js", __FILE__)
        else
          send_data "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nContent-Length: 13\r\n\r\n404 Not Found"
          close_connection_after_writing
        end
      end

      def serve_file path
        UI.debug "Serving file #{path}"
        content_type = case File.extname(path)
        when '.css' then 'text/css'
        when '.js' then 'application/ecmascript'
        when '.gif' then 'image/gif'
        when '.jpeg', '.jpg' then 'image/jpeg'
        when '.png' then 'image/png'
        else; 'text/plain'
        end
        send_data "HTTP/1.1 200 OK\r\nContent-Type: #{content_type}\r\nContent-Length: #{File.size path}\r\n\r\n"
        stream_file_data(path).callback { close_connection_after_writing }
      end

    end
  end
end
