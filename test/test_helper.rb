# typed: true
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "with_model"

require "rails_type_id"

require "minitest/autorun"

# Set up sqlite3 database for tests
ActiveRecord::Base.establish_connection(
  {
    adapter: :sqlite3,
    database: "storage/test.sqlite3"
  }
)

WithModel.runner = :minitest

module ActiveSupport
  class TestCase < Minitest::Test
  end
end
