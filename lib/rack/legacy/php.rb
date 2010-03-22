require 'rack/legacy/cgi'

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

      # Adds extension checking in addition to checks in superclass.
      def valid?(path)
        fp = full_path path
        [/php$/, /php?\d$/].any? {|ext| ::File.extname(fp) =~ ext} &&
        fp.start_with?(::File.expand_path @public_dir) && ::File.exist?(fp)
      end

      # Monkeys with the arguments so that it actually runs PHP's cgi
      # program with the path as an argument to that program.
      def run(env, path)
        config = HtAccess.merge_all(path, public_dir)
        config = config.collect {|(key, value)| "#{key}=#{value}"}
        config.collect! {|kv| ['-d', kv]} 

        env['SCRIPT_FILENAME'] = path
        super env, @php_exe, *config.flatten
      end

      class HtAccess

        attr_reader :file

        def initialize(file)
          @file = file
        end

        def to_hash
          ret = {}
          ::File.readlines(@file).each do |line|
            ret[$1] = $2 if line.chomp =~ /^php_\S+ (\S+) (.*)$/
          end
          ret
        end

        def self.find_all(path, root)
          dir = ::File.dirname(path)
          ret = if dir.start_with?(root)
            find_all(dir, root)
          else
            []
          end 
          ret << new("#{dir}/.htaccess") if ::File.exist? "#{dir}/.htaccess"
          ret
        end

        def self.merge_all(path, root)
          find_all(path, root).inject({}) {|ret, hsh| ret.merge hsh}
        end

      end
    end
  end
end