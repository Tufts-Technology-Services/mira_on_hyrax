# frozen_string_literal: true
require 'simplecov'

SimpleCov.start 'rails' do
  if ENV['CI']
    require 'simplecov-lcov'

    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = 'coverage/lcov.info'
    end

    formatter SimpleCov::Formatter::LcovFormatter
  end

  add_filter %w[version.rb initializer.rb]
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'database_cleaner'
require 'active_fedora/cleaner'
require 'selenium-webdriver'
require 'webdrivers' unless ENV['IN_DOCKER'].present? || ENV['HUB_URL'].present?

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

FactoryBot.register_strategy(:actor_create, ActorCreate)

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

Capybara::Screenshot.autosave_on_failure = false

if ENV['IN_DOCKER'].present? || ENV['HUB_URL'].present?
  args = %w[disable-gpu no-sandbox whitelisted-ips window-size=1400,1400]
  args.push('headless') if ActiveModel::Type::Boolean.new.cast(ENV['CHROME_HEADLESS_MODE'])

  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    "goog:chromeOptions" => {
      args: args,
      prefs: {
        "download.prompt_for_download" => false,
        "download.default_directory" => "/home/seluser/Downloads"
      }
    }
  )

  Capybara.register_driver :selenium_chrome_headless_sandboxless do |app|
    driver = Capybara::Selenium::Driver.new(app,
                                       browser: :remote,
                                       desired_capabilities: capabilities,
                                       url: ENV['HUB_URL'])

    # Fix for capybara vs remote files. Selenium handles this for us
    driver.browser.file_detector = lambda do |argss|
      str = argss.first.to_s
      str if File.exist?(str)
    end

    driver
  end

  Capybara.server_host = '0.0.0.0'
  Capybara.server_port = 3010

  ip = IPSocket.getaddress(Socket.gethostname)
  Capybara.app_host = "http://#{ip}:#{Capybara.server_port}"
else
  Webdrivers::Chromedriver.required_version = '106.0.5249.21'
  Capybara.register_driver :selenium_chrome_headless_sandboxless do |app|
    browser_options = Selenium::WebDriver::Chrome::Options.new

    browser_options.binary = '/opt/hostedtoolcache/chromium/1036826/x64/chrome'
    browser_options.add_argument('--headless') # old headless mode for Chrome 103
    browser_options.add_argument('--disable-gpu')
    browser_options.add_argument('--no-sandbox')
    browser_options.add_argument('--disable-dev-shm-usage')
    browser_options.add_argument('--remote-debugging-port=9222')
    browser_options.add_argument('--window-size=1920,1080')

    browser_options.add_preference(:download,
      prompt_for_download: false,
      default_directory: DownloadHelpers::PATH.to_s)

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
  end

end

# Uses faster rack_test driver when JavaScript support not needed
Capybara.default_driver = :rack_test # This is a faster driver
Capybara.javascript_driver = :selenium_chrome_headless_sandboxless # This is slower

Capybara.default_max_wait_time = 20

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include FactoryBot::Syntax::Methods
  config.include ApplicationHelper, type: :view
  config.include Warden::Test::Helpers, type: :feature
  config.include OptionalExample

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    Tufts::WorkflowSetup.setup
    Rails.application.load_seed
  end

  config.before do |example|
    # Pass `:clean' to destroy objects in fedora/solr and start from scratch
    ActiveFedora::Cleaner.clean! if example.metadata[:clean]
    if example.metadata[:type] == :feature && Capybara.current_driver != :rack_test
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.start
    end

    Tufts::WorkflowSetup.setup if
      example.metadata[:type] == :feature || example.metadata[:workflow]
  end

  config.before(:suite) do
    ActiveFedora::Cleaner.clean!
  end

  config.after do
    ActiveFedora::Cleaner.clean!
  end

  config.after(:each, type: :feature) do
    Warden.test_reset!
    Capybara.reset_sessions!
    page.driver.reset!
  end

  config.before(:context, batch: true) do
    ActiveJobStatus.store = ActiveSupport::Cache::MemoryStore.new
  end

  config.after(:each, batch: true) do
    ActiveJobStatus.store.clear
  end

  config.after do
    DatabaseCleaner.clean
  end

  ##
  # Use this example group when you want to perform jobs inline during testing.
  #
  # Limit to specific job classes with:
  #
  #   ActiveJob::Base.queue_adapter.filter = [JobClass]
  config.before(perform_enqueued: true) do
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs    = true
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
  end

  config.after(perform_enqueued: true) do
    ActiveJob::Base.queue_adapter.enqueued_jobs  = []
    ActiveJob::Base.queue_adapter.performed_jobs = []

    ActiveJob::Base.queue_adapter.perform_enqueued_jobs    = false
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = false
  end

  Shoulda::Matchers.configure do |shoulda_config|
    shoulda_config.integrate do |with|
      # Choose a test framework:
      with.test_framework :rspec
      with.library :rails
    end
  end
end
