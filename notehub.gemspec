# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','notehub','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'notehub'
  s.version = Notehub::VERSION
  s.author = 'Your Name Here'
  s.email = 'your@email.address.com'
  s.homepage = 'http://your.website.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A description of your project'
# Add your other files here if you make them
  s.files = %w(
bin/notehub
lib/notehub/version.rb
lib/notehub/notehub.rb
lib/notehub.rb
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','notehub.rdoc']
  s.rdoc_options << '--title' << 'notehub' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'notehub'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_runtime_dependency('gli','2.7.0')
  s.add_runtime_dependency('json','1.8.1')
  s.add_runtime_dependency('highline','1.6.21')
end
