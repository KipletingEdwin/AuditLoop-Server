
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/factory"
require_relative "support/fake_anthropic_client"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    include Factory
  end
end