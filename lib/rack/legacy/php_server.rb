# Created by Dawid Dziurdzia
# http://dziurdzia.eu
# github: @nazgu1
# 2013

#Use some code of https://github.com/jaswope/rack-reverse-proxy with LICENCE:
#Copyright (c) 2009 Jon Swope
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'fileutils'
require 'tempfile'
require 'rack/legacy/error_page'
require 'rack/legacy/htaccess'
require 'net/http'

module Rack
  module Legacy
    class PhpServer
      attr_reader :public_dir

      # Like Rack::Legacy::Cgi.new except allows an additional argument
      # of which executable to use to run the PHP server.
      #
      #  use Rack::Legacy::PhpServer, 'public', '/usr/local/bin/php5'
      def initialize(app, public_dir=FileUtils.pwd, php_exe='php', htaccess_enabled=true)
        @app = app
        @public_dir = public_dir
        @php_exe = php_exe
        @htaccess_enabled = htaccess_enabled
        
        error_log = "#{public_dir}/logs/php_error_log.log"
        info_log = "#{public_dir}/logs/php_log.log"
        
        system "#{php_exe} -S localhost:8000 -t #{public_dir} 2> #{error_log} 1> #{info_log} &"
      end
      
      # Middleware, so if it looks like we can run it then do so.
      # Otherwise send it on for someone else to handle.
      def call(env)
        if valid? env['PATH_INFO']
          run env, full_path(env['PATH_INFO'])
        else
          @app.call env
        end
      end

      # Override to check for php extension. Still checks if
      # file is in public path and it is a file like superclass.
      def valid?(path)
        sp = path_parts(full_path path)[0]

        # Must have a php extension or be a directory
        return false unless
          (::File.file?(sp) && sp =~ /\.php$/) ||
          ::File.directory?(sp)

        # Must be in public directory for security
        sp.start_with? ::File.expand_path(@public_dir)
      end

      # Monkeys with the arguments so that it actually runs PHP's cgi
      # program with the path as an argument to that program.
      def run(env, path)
        rackreq = Rack::Request.new(env)
    
        sp = env['PATH_INFO']
        sp += '?' + env['QUERY_STRING'] if
                env.has_key?('QUERY_STRING') && !env['QUERY_STRING'].empty?
        
        url = URI("http://localhost:8000#{sp}")
        
        headers = Rack::Utils::HeaderHash.new
        env.each { |key, value|
          if key =~ /HTTP_(.*)/
            headers[$1] = value
          end
        }
        headers['HOST'] = url.host
        headers['X-Forwarded-Host'] = rackreq.host
        
        session = Net::HTTP.new(url.host, url.port)
        session.verify_mode = OpenSSL::SSL::VERIFY_NONE
        
        session.start { |http|
          m = rackreq.request_method
          case m
          when "GET", "HEAD", "DELETE", "OPTIONS", "TRACE"
            req = Net::HTTP.const_get(m.capitalize).new(url.request_uri, headers)
            
          when "PUT", "POST"
            req = Net::HTTP.const_get(m.capitalize).new(url.request_uri, headers)
        
            if rackreq.body.respond_to?(:read) && rackreq.body.respond_to?(:rewind)
              body = rackreq.body.read
              req.content_length = body.size
              rackreq.body.rewind
            else
              req.content_length = rackreq.body.size
            end
        
            req.content_type = rackreq.content_type unless rackreq.content_type.nil?
            req.body_stream = rackreq.body
          else
            raise "method not supported: #{m}"
          end
        
          body = ''
          res = http.request(req) do |res|
            res.read_body do |segment|
              body << segment
            end
          end
        
          [res.code, response_headers(res), [body]]
        }
      end

    private
      def response_headers http_response
        response_headers = Rack::Utils::HeaderHash.new(http_response.to_hash)
        # handled by Rack
        response_headers.delete('status')
        response_headers.delete('transfer-encoding')
        response_headers
      end
    
      # Returns the path with the public_dir pre-pended and with the
      # paths expanded (so we can check for security issues)
      def full_path(path)
        ::File.expand_path ::File.join(public_dir, path)
      end
  
      def strip_public(path)
        path.sub ::File.expand_path(public_dir), ''
      end
  
      # Given a full path will separate the script part from the
      # path_info part. Returns an array. The first element is the
      # script. The second element is the path info.
      def path_parts(path)
        return [path, nil] unless path =~ /.php/
        script, info = *path.split('.php', 2)
        script += '.php'
        [script, info]
      end
  
      # Given a full path will extract just the info part. So
      #
      #   /index.php/foo/bar
      #
      # will return /foo/bar, but
      #
      #   /index.php
      #
      # will return an empty string.
      def info_path(path)
        path.split('.php', 2)[1].to_s
      end
    end
  end
end
