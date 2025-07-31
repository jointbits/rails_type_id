# typed: ignore # rubocop:disable Sorbet
# frozen_string_literal: true

require "test_helper"

class TestConcern < ActiveSupport::TestCase
  extend WithModel

  with_model :WithoutPrefix do
    table id: false do |t|
      t.string :id
    end

    model do
      include RailsTypeId::Concern
    end
  end

  with_model :WithPrefix do
    table id: false do |t|
      t.string :id
    end

    model do
      include RailsTypeId::Concern
      with_type_id_prefix("wp")
    end
  end

  def test_requires_prefix
    item_without = WithoutPrefix.create
    refute(item_without.valid?)
    assert_includes(item_without.errors[:type_id_prefix], "type_id_prefix cannot be nil")
    assert_raises(ActiveRecord::RecordInvalid) do
      WithoutPrefix.create!
    end

    item_with = WithPrefix.create
    assert(item_with.valid?)
    assert_empty(item_with.errors)
    item_with = WithPrefix.create!
    type_id = item_with.type_id
    assert_equal(TypeID, type_id.class)
    assert_equal("wp", type_id.prefix)
  end

  def test_validate_type_id_prefix!
    [
      nil,
      "",
      "thisprefixiswaytoolong",
      "this has spaces"
    ].each do |prefix|
      assert_raises(RailsTypeId::Concern::InvalidTypeIdPrefix) do
        RailsTypeId::Concern::Helpers.validate_type_id_prefix!(prefix)
      end
    end
  end
end
