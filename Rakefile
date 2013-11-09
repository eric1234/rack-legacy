require 'rake/testtask'
require "bundler/setup"
Bundler::GemHelper.install_tasks

Rake::TestTask.new do |t|
  t.name = 'test:unit'
  t.libs << "lib"
  t.test_files = FileList['test/unit/*_test.rb']
end

Rake::TestTask.new do |t|
  t.name = 'test:functional:run'
  t.libs << "lib"
  t.test_files = FileList['test/functional/*_test.rb']
end
task 'test:functional' => ['test:functional:server', 'test:functional:run']

task 'test:functional:server' do
  require 'rubygems'
  require 'httparty'

  puts 'Starting test server...'
  $server = fork {exec 'ruby', '-I', 'lib', 'test/test_server.rb'}
  begin
    HTTParty.get 'http://localhost:4000/ping'
  rescue
    sleep 1
    retry
  end
  puts 'Test server started...'
end

END {
  if $server
    puts 'Shutting down test server...'
    Process.kill 'KILL', $server
  end
}

desc "Run all tests"
task :test => ['test:unit', 'test:functional']

task :default => :test
