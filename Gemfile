source 'https://rubygems.org'

gem 'rack'
gem 'sinatra'
gem 'json'

group :test do
  gem 'rack-test'
end

group :development do
  gem 'guard-bundler'
  gem 'guard-minitest'
end

group :development, :test do
  gem 'faker'
end

# Mac platform specific development gems
group :development, :darwin do
  gem 'terminal-notifier-guard'
  gem 'rb-fsevent'
end
