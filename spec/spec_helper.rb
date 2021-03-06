# -*- encoding : utf-8 -*-

require 'database_cleaner'
require 'factory_girl'
require 'capybara/rspec'

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.include Devise::TestHelpers, :type => :controller

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.mock_with :rspec
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true

  # Needed for Spork
  ActiveSupport::Dependencies.clear

  # Factory girl
  config.include FactoryGirl::Syntax::Methods

  # Clear search index for each test
  config.before(:each) do
    refresh_relics_index
  end

  config.include Devise::TestHelpers, :type => :controller
  config.extend ControllerMacros, :type => :controller
  config.include RequestHelpers, :type => :request


  config.before(:each) do
    refresh_relics_index
  end
end

DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean
FactoryGirl.reload
I18n.backend.reload!
Otwartezabytki::Application.reload_routes!

# http://railsgotchas.wordpress.com/2012/01/31/activeadmin-spork-and-the-infamous-undefined-local-variable-or-method-view_factory/
ActionView::Template.register_template_handler :arb, lambda { |template|
  "self.class.send :include, Arbre::Builder; @_helpers = self; self.extend ActiveAdmin::ViewHelpers; @__current_dom_element__ = Arbre::Context.new(assigns, self); begin; #{template.source}; end; current_dom_context"
}

def sample_path(file)
  file_path = "#{Rails.root}/spec/samples/#{file}"
  raise Exception.new("File not found: #{file_path}") unless File.exists?(file_path)
  file_path
end
