source 'https://rubygems.org'

if ENV['PHOTOCOPIER_PATH']
  gem 'photocopier', path: ENV.fetch('PHOTOCOPIER_PATH')
else
  gem 'photocopier', git: 'https://github.com/annrie/photocopier.git', tag: 'v1.5.0.pre.1'
end

gemspec
