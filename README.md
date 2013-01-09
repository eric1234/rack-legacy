Rack Legacy tries to provide interaction with legacy environments like
PHP and CGI while still getting the Rack portability so you don't need
a full Apache stack.

This software is currently ALPHA quality. Use at your own risk.

The PRIMARY use case for this software is for development of an
application where Ruby is being used but there are also some legacy
PHP or CGI that is running along-side the Ruby application. This
middleware allows you to do that development without the full Apache
stack. When you take the application to a production environment you
can either leave this middleware in or use a full Apache stack to get
added performance and security.

Released under the MIT License:
<http://www.opensource.org/licenses/mit-license.php>

### Usage

1. Add `config.rb` to your application root directory
2. Insert configuration:
2.1. PHP-CGI

		require 'rack'
		require 'rack-legacy'
		require 'rack-rewrite'

		INDEXES = ['index.html','index.php', 'index.cgi']

		use Rack::Rewrite do
		  rewrite %r{(.*/$)}, lambda {|match, rack_env|
			INDEXES.each do |index|
			  if File.exists?(File.join(Dir.getwd, rack_env['PATH_INFO'], index))
				return rack_env['PATH_INFO'] + index
			  end
			end
			rack_env['PATH_INFO']
		  }
		end

		use Rack::Legacy::Cgi, Dir.getwd
		run Rack::File.new Dir.getwd

	2.2. PHP 5.4 Server

		require 'rack'
		require 'rack-legacy'
		require 'rack-rewrite'

		INDEXES = ['index.html','index.php', 'index.cgi']

		use Rack::Rewrite do
		  rewrite %r{(.*/$)}, lambda {|match, rack_env|
			INDEXES.each do |index|
			  if File.exists?(File.join(Dir.getwd, rack_env['PATH_INFO'], index))
				return rack_env['PATH_INFO'] + index
			  end
			end
			rack_env['PATH_INFO']
		  }
		end

		use Rack::Legacy::PhpServer, Dir.getwd #, '/usr/local/Cellar/php54/5.4.10/bin/php'
		run Rack::File.new Dir.getwd

3. Start your rack server.

### CREDIT

This gem was developed by [Eric Anderson](http://pixelwareinc.com) via
work done under [Red Tusk Studios](http://redtusk.com).
