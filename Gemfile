# frozen_string_literal: true
source 'https://rubygems.org'

ruby '2.7.7'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end
gem 'active-fedora'
gem 'activejob-uniqueness', '0.2.0', require: 'active_job/uniqueness/sidekiq_patch'
gem 'chunky_png'
gem 'dotenv-rails'
gem 'exiftool_vendored'
# gem 'fedora-migrate', path: '../fedora-migrate'
gem 'fastimage'
gem 'hydra-role-management'
gem 'hyrax', '~> 2.9'
gem 'mimemagic', '0.3.10'
gem 'nokogiri', '>=1.8.2' # 1.8.2 fixes security issue https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-15412
gem 'okcomputer'
gem 'pdf-reader'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2'
gem 'rmagick', '4.2.6'

# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use Puma as the app server
gem "puma", ">= 4.3.9"
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

gem 'blacklight', '6.24.0'
gem 'blacklight_advanced_search'
gem 'omniauth', '1.9.1'
gem 'omniauth-shibboleth'
gem 'whenever', require: false

gem 'tufts-curation', git: 'https://github.com/TuftsUniversity/tufts-curation', tag: 'v1.3.7'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger  console
  gem 'byebug', platform: :mri
  gem 'launchy'
  gem 'pry'
  gem 'term-ansicolor'
end

group :development do
  gem 'listen', '~> 3.0.5'
end

gem 'active_job_status', '~> 1.2.1'
gem 'devise-guests', '~> 0.6'
gem 'devise_ldap_authenticatable'
gem 'handle-system', git: 'https://github.com/TuftsUniversity/handle.git'
gem 'ladle'
gem 'mysql2'
gem 'react-rails'
gem 'rsolr', '>= 1.0'
gem 'sanitize', '6.0.1' # Upgrade further
gem 'sidekiq'
gem 'sidekiq-failures'
gem 'sidekiq-limit_fetch'

group :production do
  gem 'passenger'
  gem 'therubyracer'
end

group :development, :test do
  gem 'bixby'
  gem 'capybara'
  gem 'capybara-maleficent', require: false
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'fcrepo_wrapper'
  gem 'ffaker'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 4.5.1'
  gem 'simplecov'
  gem 'simplecov-lcov', '~> 0.8.0'
  gem 'solr_wrapper', '>= 0.3'
  gem 'webdrivers', '~> 4.0', require: false
end

# github security updates list
gem "devise", ">= 4.6.0"
gem "rubyzip", ">= 1.2.2"
