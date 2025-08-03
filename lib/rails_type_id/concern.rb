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

    class InvalidTypeIdPrefix < StandardError; end

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

      before_create :generate_uuid_v7
      validates_with Validator

      # Returns the TypeID for the model
      # @return [TypeID]
      define_method :type_id do
        Helpers.validate_type_id_prefix!(self.class.type_id_prefix)
        TypeID.from_uuid(self.class.type_id_prefix, id)
      end

      # If `id` is unset, generates a new UUID v7 and sets it
      # @return [void]
      define_method :generate_uuid_v7 do
        case self.class.attribute_types["id"].type
        when :uuid, :string
          self.id ||= SecureRandom.uuid_v7
        end
      end

      define_method :to_param do
        type_id.to_s
      end
    end

    # Internal helper methods
    class Helpers
      extend T::Sig

      class << self
        def validate_type_id_prefix(prefix)
          return "type_id_prefix cannot be nil" if prefix.nil?

          return nil if prefix.match(/\A[a-z]{1,10}\z/)

          "type_id_prefix must be lowercase alphabetic (a-z) with length >= 1, <= 10"
        end

        def validate_type_id_prefix!(prefix)
          result = validate_type_id_prefix(prefix)
          raise InvalidTypeIdPrefix, result if result.present?
        end

        def lookup_type_id(type_id)
          klasses = lookup_model(type_id)
          return if klasses.nil?

          id = type_id # TODO: parse out the uuid part
          klasses.each do |klass|
            result = klass.find_by(id: id)
            return result unless result.nil?
          end

          nil
        end

        def lookup_model(type_id)
          prefix = get_prefix(type_id)
          return if prefix.nil?

          prefix_map[prefix]
        end

        def get_prefix(id)
          prefix, = parse_id(id)
          prefix
        end

        private

        def parse_id(id)
          id.split("_")
        end

        def prefix_map
          Rails.application.eager_load!
          # This has to be group_by and not index_by because we can have multiple
          # models that use the same prefix (like Settings)
          @prefix_map ||= ActiveRecord::Base.descendants
                                            .select { |klass| klass.respond_to?(:type_id_prefix) }
                                            .group_by(&:type_id_prefix)
        end
      end
    end
  end
end
