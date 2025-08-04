# typed: false # rubocop:disable Sorbet/HasSigil
# frozen_string_literal: true

require "active_model"
require "active_support"
require "sorbet-runtime"
require "typeid"

module RailsTypeId
  # RailsTypeId::Concern is a Rails ActiveSupport::Concern that uses a Stripe-style "type ID"
  # for its ID field.
  module Concern
    extend ::ActiveSupport::Concern
    include ::ActiveModel::Validations::Callbacks

    # Checks validity of the ActiveRecord model instances
    class Validator < ActiveModel::Validator
      def validate(record)
        result = Helpers.validate_type_id_prefix(record.class.type_id_prefix)
        record.errors.add(:type_id_prefix, result) if result
      end
    end

    class_methods do
      def with_type_id_prefix(prefix)
        Helpers.validate_type_id_prefix!(prefix)

        @_type_id_prefix = prefix
      end

      def type_id_prefix
        @_type_id_prefix
      end

      def from_controller_id_param(type_id_str)
        find(TypeID.from_string(type_id_str).uuid.to_s)
      end
    end

    included do
      attribute :id # Postgres UUID field

      before_create :generate_type_id
      validates_with Validator

      # Returns the TypeID for the model
      # @return [TypeID]
      define_method :type_id do
        Helpers.validate_type_id_prefix!(self.class.type_id_prefix)
        TypeID.from_string(id)
      end

      # If `id` is unset, generates a new UUID v7 TypeID and sets the `id` field
      # @return [void]
      define_method :generate_type_id do
        Helpers.validate_type_id_prefix!(self.class.type_id_prefix)
        self.id ||= Helpers.generate_type_id(self.class.type_id_prefix).to_s
      end
    end
  end
end
