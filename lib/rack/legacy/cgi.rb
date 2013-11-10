require 'shellwords'

class Rack::Legacy::Cgi

  # Will setup a new instance of the CGI middleware executing
  # programs located in the given `public_dir`
  def initialize app, public_dir=Dir.getwd
    @app = app
    @public_dir = public_dir
  end

  # Middleware, so if it looks like we can run it then do so.
  # Otherwise send it on for someone else to handle.
  def call env
    path = env['PATH_INFO']
    path = path[1..-1] if path =~ /\//
    path = ::File.expand_path path, @public_dir
    if valid? path
      run env, path
    else
      @app.call env
    end
  end

  # Check to ensure the path exists and it is a child of the
  # public directory.
  def valid?(path)
    path.start_with?(::File.expand_path @public_dir) &&
    ::File.file?(path) && ::File.executable?(path)
  end

  private

  # Will run the given path with the given environment
  def run env, path
    env['DOCUMENT_ROOT'] = @public_dir
    env['SERVER_SOFTWARE'] = 'Rack Legacy'
    status = 200
    headers = {}
    body = ''

    IO.popen('-', 'r+') do |io|
      if io.nil?  # Child
        # Pass on all uppercase environment variables. Only uppercase
        # since Rack uses lower case ones internally.
        env.each do |key, value|
          ENV[key] = value if
            value.respond_to?(:to_str) && key =~ /^[A-Z_]+$/
        end
        exec path
      else        # Parent
        # Send request to CGI sub-process
        io.write(env['rack.input'].read) if env['rack.input']
        io.close_write

        # Parse headers coming back from sub-process
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

        # Get response and wait for process to complete.
        body = io.read
        Process.wait

        # If there was an error throw it up the execution stack so
        # someone can rescue to provide info to the right person.
        unless $?.exitstatus == 0
          # Build full command for easier debugging. Output to
          # stderr to prevent user from getting too much information.
          cmd = env.inject([path]) do |assignments, (key, value)|
            assignments.unshift "#{key}=#{value.to_s.shellescape}" if
              value.respond_to?(:to_str) && key =~ /^[A-Z_]+$/
            assignments
          end * ' '
          $stderr.puts <<ERROR
CGI exited with status #{$?.exitstatus}. The full command run was:

#{cmd}

ERROR
          raise Rack::Legacy::ExecutionError
        end

      end
    end

    # Extract status from sub-process if it is doing something other
    # than a 200 response.
    status = headers.delete('Status').to_i if headers.has_key? 'Status'

    # Send it all back to rack
    [status, headers, [body]]
  end
end
