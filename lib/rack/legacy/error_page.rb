require 'erb'
require 'cgi'

module Rack
  module Legacy
    class ErrorPage
    
      # Given the environment, stdout and stderr from a programs execution
      # will generate a error page to assist in debugging
      def initialize(env, headers, stdout, stderr)
        @env = env
        @headers = headers
        @stdout = stdout
        @stderr = stderr
      end
    
      # Generate the page
      def to_s
        ERB.new(template).result binding
      end
    
      private
    
      def template
        <<TEMPLATE
<html>
<style type="text/css">
  body {background-color: #CECECE; color: black}
  #page {
    width: 60em;
    margin: 1em auto;
    padding: 2em;
    background-color: white;
    border: medium solid #848484;
    border-radius: 0.5em;
  }

  pre {width: 100%; overflow: auto}
  table {border-collapse: collapse}
  table th, table td {padding: 0.25em 0.5em}
  table th {text-align: left; background-color: #EAEAEA; font-weight: normal}
</style>
<body>
  <div id="page">
    <h1>Internal Server Error</h1>
  
    <p>An error was encountered while executing
    <%=h @env['PATH_INFO'].to_s %> under the rack-legacy middleware.</p>
  
    <% unless @stdout == '' %>
      <h2>Standard Out</h2>
      <pre><code><%=h @stdout %></code></pre>
    <% end %>
  
    <% unless @stderr == '' %>
      <h2>Standard Error</h2>
      <pre><code><%=h @stderr %></code></pre>
    <% end %>
  
    <% unless @headers.empty? %>
      <h2>Output Headers</h2>
      <table>
        <% @headers.each do |key, value| %>
          <tr>
            <th><%=h key %></th>
            <td><%=h value %></td>
          </tr>
        <% end %> 
      </table>
    <% end %>
  
    <% unless @env.empty? %>
      <h2>Environment</h2>
      <table>
        <% @env.keys.sort.each do |key|
          value = @env[key]
          next unless value.respond_to? :to_str %>
          <tr>
            <th><%=h key %></th>
            <td><%=h value %></td>
          </tr>
        <% end %>
      </table>
    <% end %>
  </div>
</body>
</html>
TEMPLATE
      end
    
      private
    
      def h(s)
        s.to_s.
          # Encode unsafe HTML characters
          gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;").
          # Use HTML entities for non-ASCII characters
          unpack("U*").collect { |s| s > 127 ? "&##{s};" : s.chr }.join("")
      rescue ArgumentError => e
        case e.message
          when "invalid byte sequence in US-ASCII" then
            # Assume UTF-8 string
            s.force_encoding('UTF-8') and retry
        end
        raise e
      end
    
    end
  end
end
