# typed: true
# frozen_string_literal: true

require "test_helper"

require "tapioca/internal"
require "tapioca/helpers/test/content"
require "tapioca/helpers/test/dsl_compiler"
require_relative "../../lib/tapioca/dsl/compilers/rails_type_id_compiler"

class TestRailsTypeIdCompiler < ActiveSupport::TestCase
  include Tapioca::Helpers::Test::DslCompiler

  setup do
    use_dsl_compiler(Tapioca::Dsl::Compilers::RailsTypeIdCompiler)
  end

  test "gather_constants: empty if no RailsTypeId::Concern" do
    add_ruby_file("test_model.rb", <<~CONTENT)
      class TestModel< ActiveRecord::Base
      end
    CONTENT

    constants = Tapioca::Dsl::Compilers::RailsTypeIdCompiler.gather_constants.map(&:name)
    assert_not_includes(constants, "TestModel")
  end

  test "gather_constants: gathers constants with RailsTypeId::Concern" do
    add_ruby_file("test_model.rb", <<~CONTENT)
      class TestModel< ActiveRecord::Base
        include RailsTypeId::Concern
      end
    CONTENT

    constants = Tapioca::Dsl::Compilers::RailsTypeIdCompiler.gather_constants.map(&:name)
    assert_includes(constants, "TestModel")
  end

  test "decorate: type_id field" do
    add_ruby_file("test_model.rb", <<~CONTENT)
      class TestModel< ActiveRecord::Base
        include RailsTypeId::Concern

        with_type_id_prefix("tm")
      end
    CONTENT

    expected = <<~RBI
      # typed: strong

      class TestModel
        include RailsTypeIdMethods

        module RailsTypeIdMethods
          sig { returns(TypeID) }
          def type_id; end
        end
      end
    RBI

    assert_equal(expected, rbi_for(:TestModel))
  end
end