require 'rack/legacy/cgi'

module Rack
  module Legacy
    class Php < Cgi

      # Like Rack::Legacy::Cgi.new except allows an additional argument
      # of which executable to use to run the PHP code.
      #
      #  use Rack::Legacy::Php, 'public', 'php5-cgi'
      def initialize(app, public_dir=FileUtils.pwd, php_exe='php-cgi')
        super app, public_dir
        @php_exe = php_exe
      end

      # Adds extension checking in addition to checks in superclass.
      def valid?(path)
        [/php$/, /php?\d$/].any? do |ext|
          ::File.extname(full_path path) =~ ext
        end && super
      end

      # Monkeys with the arguments so that it actually runs PHP's cgi
      # program with the path as an argument to that program.
      def run(env, path)
        env['SCRIPT_FILENAME'] = path
        super env, @php_exe
      end

    end
  end
end