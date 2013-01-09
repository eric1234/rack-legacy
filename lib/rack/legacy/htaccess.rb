# For processing .htaccess files to tweak PHP environment.
# Represents a single .htaccess file that might affect PHP
module Rack
	module Legacy
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