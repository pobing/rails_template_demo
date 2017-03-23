## Gem part

remove_file 'Gemfile'
run 'touch Gemfile'
add_source 'https://gems.ruby-china.org'

gem 'rails', '~> 5.0.0', '>= 5.0.0.1'
gem 'puma', '~> 3.0'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'turbolinks', '~> 5'

gem 'pg', '~> 0.18'
gem 'redis-namespace'
gem 'redis'
gem 'axlsx_rails'
gem 'paranoia', '~> 2.2'
gem 'config'
gem 'will_paginate', '~> 3.1.0'
gem 'will_paginate-bootstrap', '~> 1.0.1'
gem 'newrelic_rpm', '~> 3.0'
gem 'rqrcode', '~> 0.10.1'
gem 'rqrcode_png', '~> 0.1.5'

gem_group :development, :test do
  gem 'byebug', platform: :mri
  gem 'fakeredis'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'scss_lint', require: false
  gem 'awesome_print'
end

gem_group :development do
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem_group :test do
  gem 'json_spec'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'factory_girl'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

remove_file ".gitignore"

file '.gitignore', <<-CODE
# Ignore bundler config.
.DS_Store
/.bundle

# Ignore all logfiles and tempfiles.
/log/*
!/log/.keep
/tmp
.idea
/test
config/settings.local.yml
config/settings/*.local.yml
config/environments/*.local.yml
public/assets/
.byebug_history
CODE

## Config part

inside 'config' do
  remove_file 'database.yml'
  create_file 'database.yml' do <<-EOF
  default: &default
    adapter: postgresql
    encoding: unicode
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

  development:
    <<: *default
    database: #{app_name}_development

  test:
    <<: *default
    database: #{app_name}_test

  production:
    <<: *default
    database: <%= ENV['RDS_DB_NAME'] %>
    username: <%= ENV['RDS_USERNAME'] %>
    password: <%= ENV['RDS_PASSWORD'] %>
    host: <%= ENV['RDS_HOSTNAME'] %>
    port: <%= ENV['RDS_PORT'] %>
  EOF
  end
end

## Initializer
initializer 'redis.rb', <<-CODE
require 'redis-namespace'

class GDRedis
  class << self
    def instance
      new_instance :gd_app
    end

    def perform_with_ttl(key, ttl = 300)
      yield key
      instance.expire key, ttl unless ttl.nil?
    end

    def perform_with_expireat(key, expireat)
      yield key
      instance.expireat key, expireat
    end

    private

    def new_instance(name_space)
      # instance_name = "@"+name_space+"_redis"
      return instance_variable_get(instance_name) if instance_variable_defined?(instance_name)

      require 'fakeredis' if Rails.env.test?
      redis_connection = Redis.new url: Settings.redis.url
      instance_variable_set instance_name, Redis::Namespace.new(name_space.to_s, redis: redis_connection)
    end
  end
end

class AutoExpireGDRedis
  def initialize(store, ttl = 24 * 3600)
    @store = store
    @ttl = ttl
  end

  def [](url)
    @store.[](url)
  end

  def []=(url, value)
    @store.[]=(url, value)
    @store.expire(url, @ttl)
  end

  def keys
    @store.keys
  end

  def del(url)
    @store.del(url)
  end
end
CODE

rakefile("rspec.rake") do
  <<-TASK
    if Rails.env.development? || Rails.env.test?
      require 'rspec/core/rake_task'
      RSpec::Core::RakeTask.new(:spec)
    end
  TASK
end

generate(:model, 'users',
  'nick_name:string',
  'email:string',
  'avatar:string',
  'custom_domain:string',
  'access_token:string',
  'refresh_token:string',
  'expires_at:datetime'
)

rails_command "db:setup"

# generate(:controller, "health_check index")
file 'app/controllers/health_check_controller.rb', <<-CODE
class HealthCheckController < ActionController::Base
  def index
    render plain: 'Hey buddy! We are good.', status: 200
  end
end
CODE

route "root to: 'apps#index'"
# health Check route
route "get 'health-check', to: 'health_check#index'"

after_bundle do
  remove_dir "app/mailers"
  remove_dir "test"
  remove_file "app/views/layouts/application.html.erb"
  remove_file "app/views/layouts/mailer.html.erb"
  remove_file "app/views/layouts/mailer.text.erb"

  run "spring stop"
  generate "config:install"
  generate "rspec:install"
  generate 'newrelic install --license_key="f3daa6976efc50a1b45ea8077219cbe7307d82f4" "#{app_name}"'

  # Todo:

  # git :init
  # git add: '.'
  # git commit: "-a -m 'Initial commit'"
end
