require 'rack/legacy/cgi'
require 'rack/legacy/htaccess'

module Rack
  module Legacy
    class Php < Cgi

      # Like Rack::Legacy::Cgi.new except allows an additional argument
      # of which executable to use to run the PHP code.
      #
      #  use Rack::Legacy::Php, 'public', 'php5-cgi'
      def initialize(app, public_dir=FileUtils.pwd, php_exe='php-cgi', htaccess_enabled=true)
        super app, public_dir
        @php_exe = php_exe
        @htaccess_enabled = htaccess_enabled
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
        config = {'cgi.force_redirect' => 0}
        config.merge! HtAccess.merge_all(path, public_dir) if @htaccess_enabled
        config = config.collect {|(key, value)| "#{key}=#{value}"}
        config.collect! {|kv| ['-d', kv]}

        script, info = *path_parts(path)
        if ::File.directory? script
          # If directory then assume index.php
          script = ::File.join script, 'index.php';
          # Ensure it ends in / which some PHP scripts depend on
          path = "#{path}/" unless path =~ /\/$/
        end
        env['SCRIPT_FILENAME'] = script
        env['SCRIPT_NAME'] = strip_public script
        env['PATH_INFO'] = info
        env['REQUEST_URI'] = strip_public path
        env['REQUEST_URI'] += '?' + env['QUERY_STRING'] if
          env.has_key?('QUERY_STRING') && !env['QUERY_STRING'].empty?
        super env, @php_exe, *config.flatten
      end

      private

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
