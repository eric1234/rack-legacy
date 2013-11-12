class Rack::Legacy::Index

  # Will rewrite the request if the request is for a directory and
  # one of the index files specified exists.
  def initialize app, public_dir, order=['index.php', 'index.cgi', 'index.html']
    @app = app
    @public_dir = public_dir
    @order = order
  end

  # Check for the dir, files and rewrite if necessary. Note that we
  # don't check to ensure the requested path is in the public directory
  # (i.e. things like ../ will hack outside it). We rely on the
  # middleware actually handling the request to do the necessary
  # security check.
  def call env
    dir = File.join @public_dir, env['PATH_INFO']
    rewrite = env['PATH_INFO']    
    @order.reverse.each do |index|
      full_index = File.join dir, index
      new_path = File.join env['PATH_INFO'], index
      rewrite = new_path if File.exists? full_index
    end if File.directory? dir
    env['PATH_INFO'] = rewrite
    @app.call env
  end

end
