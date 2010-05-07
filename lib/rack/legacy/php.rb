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
        fp.start_with?(::File.expand_path @public_dir) && ::File.file?(fp)
      end

      # Monkeys with the arguments so that it actually runs PHP's cgi
      # program with the path as an argument to that program.
      def run(env, path)
        config = {'cgi.force_redirect' => 0}
        config.merge! HtAccess.merge_all(path, public_dir) if @htaccess_enabled
        config = config.collect {|(key, value)| "#{key}=#{value}"}
        config.collect! {|kv| ['-d', kv]}

        env['SCRIPT_FILENAME'] = path
        super env, @php_exe, *config.flatten
      end

      # For processing .htaccess files to tweak PHP environment.
      # Represents a single .htaccess file that might affect PHP
      class HtAccess

        # The .htaccess file being processed
        attr_reader :file

        # New instance to process the given file for PHP config
        def initialize(file)
          @file = file
        end

        # Returns a hash of the PHP config that needs to be set.
        def to_hash
          ret = {}
          ::File.readlines(@file).each do |line|
            ret[$1] = $2 if line.chomp =~ /^php_\S+ (\S+) (.*)$/
          end
          ret
        end

        # Will return all .htaccess files that affect a given path
        # stopping when it reaches the root directory.
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

        # Finds all .htaccess files that affect the given path stopping
        # at the given root and merge them into one big hash.
        def self.merge_all(path, root)
          find_all(path, root).inject({}) {|ret, hsh| ret.merge hsh}
        end

      end
    end
  end
end