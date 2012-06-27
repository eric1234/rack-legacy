Gem::Specification.new do |s|
  s.name = 'rack-legacy'
  s.version = '0.3.2'
  s.homepage = 'http://wiki.github.com/eric1234/rack-legacy/'
  s.author = 'Eric Anderson'
  s.email = 'eric@pixelwareinc.com'
  s.executables << 'rack_legacy'
  s.add_dependency 'rack'
  s.add_development_dependency 'flexmock'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'mechanize', '>= 2.0'
  s.files = Dir['lib/**/*.rb'] + Dir['bin/*'] + Dir['share/*']
  s.has_rdoc = true
  s.extra_rdoc_files << 'README' << 'WISHLIST'
  s.rdoc_options << '--main' << 'README'
  s.summary = 'Rack-based handler for legacy CGI and PHP'
  s.description = <<-DESCRIPTION
    Rack legacy is a rack handler to help your run legacy code
    side-by-side on your rack server. Currently CGI and PHP is supported.

    Although this can be done with an Apache setup this is overkill for
    development environments.

    PHP support is enabled by running through the php-cgi executable.
  DESCRIPTION
end
