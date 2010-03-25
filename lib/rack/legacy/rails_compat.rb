module Rack
  module Legacy
    module RailsCompat
      def self.included(mod)
        mod.alias_method_chain :file_exist?, :rack_legacy
      end

      def file_exist_with_rack_legacy?(path)
        legacy = ActionController::Dispatcher.middleware.find_all do |handler|
          handler.klass.name =~ /^Rack\:\:Legacy/
        end
        return false if legacy.any? do |handler|
          handler.build(nil).public_dir == @file_server.root &&
          handler.build(nil).valid?(path)
        end
        file_exist_without_rack_legacy? path
      end
    end
    Rails::Rack::Static.send :include, RailsCompat
  end
end if Object.const_defined? :Rails