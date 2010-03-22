require 'fileutils'
require 'tempfile'
require 'rack/legacy/error_page'

module Rack
  module Legacy
    class Cgi
      attr_reader :public_dir

      # Will setup a new instance of the Cgi middleware executing
      # programs located in the given public_dir
      #
      #   use Rack::Legacy::Cgi, 'cgi-bin'
      def initialize(app, public_dir=FileUtils.pwd)
        @app = app
        @public_dir = public_dir
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
  
      # Check to ensure the path exists and it is a child of the
      # public directory.
      def valid?(path)
        fp = full_path path
        fp.start_with?(::File.expand_path public_dir) &&
        ::File.exist?(fp) && ::File.executable?(fp)
      end
  
      protected

      # Returns the path with the public_dir pre-pended and with the
      # paths expanded (so we can check for security issues)
      def full_path(path)
        ::File.expand_path ::File.join(public_dir, path)
      end

      # Will run the given path with the given environment
      def run(env, *path)
        status = 200
        headers = {}
        body = ''

        stderr = Tempfile.new 'legacy-rack-stderr'
        IO.popen('-', 'r+') do |io|
          if io.nil?  # Child
            $stderr.reopen stderr.path
            ENV['DOCUMENT_ROOT'] = public_dir
            env.each {|k, v| ENV[k] = v if v.respond_to? :to_str}
            exec *path
          else        # Parent
            io.write(env['rack.input'].read) if env['rack.input']
            io.close_write
            Process.wait
            stderr.rewind
            stderr = stderr.read
            if $?.exitstatus == 0
              until io.eof? || (line = io.readline.chomp) == ''
                if line =~ /\s*\:\s*/
                  key, value = line.split(/\s*\:\s*/)
                  headers[key] = value
                end
              end
              body = io.read
            else
              status = 500
              body = io.read
              body = ErrorPage.new(env, headers, body, stderr).to_s
              headers['Content-Type'] = 'text/html'
            end
          end
        end
  
        [status, headers, body]
      end
    end


  end
end