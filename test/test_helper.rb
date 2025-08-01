# typed: true
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "with_model"

require "rails_type_id"

require "minitest/autorun"

WithModel.runner = :minitest

module ActiveSupport
  class TestCase < Minitest::Test
    class << self
      def connect_to_database
        # with_model needs to have a database connection active
        ActiveRecord::Base.establish_connection(
          {
            adapter: :sqlite3,
            database: "storage/test.sqlite3"
          }
        )
      end
    end
    TestCase.connect_to_database
  end
end
