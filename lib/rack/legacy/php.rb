require 'rack/legacy'
require 'rack/request'
require 'rack/reverse_proxy'
require 'childprocess'

class Rack::Legacy::Php

  # Proxies off requests to PHP files to the built-in PHP webserver.
  #
  # public_dir::
  #    Location of PHP files. Default to current working directory.
  # php_exe::
  #    Location of `php` exec. Will process through shell so is
  #    generally not needed since it is in the path.
  # quiet::
  #    By default the PHP server inherits the parent process IO. Set
  #    this to true to hide the PHP server output
  #
  def initialize app, public_dir=Dir.getwd, php_exe='php', quiet=false
    @app = app; @public_dir = public_dir
    server = TCPServer.new('127.0.0.1', 0)
    port = server.addr[1]
    server.close()
    @proxy = Rack::ReverseProxy.new do
      reverse_proxy_options preserve_host: false
      reverse_proxy /^.*$/, "http://localhost:#{port}"
    end
    @php = ChildProcess.build php_exe,
      '-S', "localhost:#{port}", '-t', public_dir
    @php.io.inherit! unless quiet
    @php.start
    at_exit {@php.stop if @php.alive?}
  end

  # If it looks like it is one of ours proxy off to PHP server.
  # Otherwise send down the stack.
  def call env
    if valid? env['PATH_INFO']
      @php.start unless @php.alive?
      ip = Rack::Request.new(env).ip
      env['HTTP_X_FORWARDED_FOR'] = ip if ip
      env['PATH_INFO'].gsub! /\/index.php$/, '/'
      @proxy.call env
    else
      @app.call env
    end
  end

  # Make sure it points to a valid PHP file. No need to ensure it
  # is in the public directory since PHP will do that for us.
  def valid? path
    return false unless path =~ /\.php/

    path = path[1..-1] if path =~ /^\//
    path = path.split('.php', 2)[0] + '.php'
    path = ::File.expand_path path, @public_dir
    ::File.file? path
  end
end
