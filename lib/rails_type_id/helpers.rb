# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module RailsTypeId
  class InvalidTypeIdPrefix < StandardError; end

  # Helper methods for interacting with type IDs
  class Helpers
    class << self
      extend T::Sig

      sig { params(prefix: String).returns(TypeID) }
      def generate_type_id(prefix)
        TypeID.from_uuid(prefix, SecureRandom.uuid_v7)
      end

      sig { params(prefix: T.nilable(String)).returns(T.nilable(String)) }
      def validate_type_id_prefix(prefix)
        return "type_id_prefix cannot be nil" if prefix.nil?

        return nil if prefix.match(/\A[a-z]{1,10}\z/)

        "type_id_prefix must be lowercase alphabetic (a-z) with length >= 1, <= 10"
      end

      sig { params(prefix: T.nilable(String)).void }
      def validate_type_id_prefix!(prefix)
        result = validate_type_id_prefix(prefix)
        raise InvalidTypeIdPrefix, result if result.present?
      end

      sig { params(type_id: String).returns(T.nilable(ActiveRecord::Base)) }
      def lookup_type_id(type_id)
        klasses = lookup_model(type_id)
        return if klasses.nil?

        klasses.each do |klass|
          result = klass.find_by(id: type_id)
          return result unless result.nil?
        end

        nil
      end

      sig { params(type_id: String).returns(T.nilable(T::Array[T.untyped])) }
      def lookup_model(type_id)
        prefix = TypeID.from_string(type_id).prefix
        return if prefix.nil?

        prefix_map[prefix]
      end

      private

      sig { returns(T::Hash[String, T::Array[T.untyped]]) }
      def prefix_map
        Rails.application.eager_load!
        # This has to be group_by and not index_by because we can have multiple
        # models that use the same prefix (like Settings)
        @prefix_map ||= T.let(
          ActiveRecord::Base.descendants
            .select { |klass| klass.respond_to?(:type_id_prefix) }
            .group_by(&:type_id_prefix),
          T.nilable(T::Hash[String, T::Array[T.untyped]])
        )
      end
    end
  end
end