require 'fileutils'
require 'tempfile'
require 'shellwords'
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
        ::File.file?(fp) && ::File.executable?(fp)
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
            ENV['SERVER_SOFTWARE'] = 'Rack Legacy'
            env.each {|k, v| ENV[k] = v if v.respond_to? :to_str}
            exec *path
          else        # Parent
            io.write(env['rack.input'].read) if env['rack.input']
            io.close_write
            until io.eof? || (line = io.readline.chomp) == ''
              if line =~ /\s*\:\s*/
                key, value = line.split(/\s*\:\s*/, 2)
                if headers.has_key? key
                  headers[key] += "\n" + value
                else
                  headers[key] = value
                end
              end
            end
            body = io.read
            stderr.rewind
            stderr = stderr.read
            Process.wait
            unless $?.exitstatus == 0
              status = 500
              cmd = env.inject(path) do |assignments, (key, value)|
                assignments.unshift "#{key}=#{value.to_s.shellescape}" if
                  value.respond_to?(:to_str) && key =~ /^[A-Z_]+$/
                assignments
              end * ' '
              body = ErrorPage.new(env, headers, body, stderr, cmd).to_s
              headers = {'Content-Type' => 'text/html'}
            end
          end
        end

        status = headers.delete('Status').to_i if headers.has_key? 'Status'
        [status, headers, [body]]
      end
    end


  end
end
