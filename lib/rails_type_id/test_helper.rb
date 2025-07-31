# typed: ignore # rubocop:disable Sorbet

module RailsTypeId
  module TestHelper
    def models_missing_type_id_prefix(base_class:, ignore_classes: [])
      Rails.application.eager_load!
      base_class.descendants.select do |klass|
        next if ignore_classes.include?(klass)
        !klass.respond_to?(:type_id_prefix)
      end
    end
  end
end