# Define namespace
module Rack
  module Legacy

    # Thrown when Rack-Legacy encounters some sort of problem delegating
    # the request to the legacy environment.
    class ExecutionError < StandardError
    end

  end
end

require 'rack/legacy/index'
require 'rack/legacy/cgi'
require 'rack/legacy/php'
