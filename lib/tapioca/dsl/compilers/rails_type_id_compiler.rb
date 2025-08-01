# typed: strict
# frozen_string_literal: true

require "tapioca"

require_relative "../../../rails_type_id/concern"

module Tapioca
  module Dsl
    module Compilers
      # This Tapioca compiler generates RBI for Rails models that include RailsTypeId::Concern.
      class RailsTypeIdCompiler < Tapioca::Dsl::Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(RailsTypeId::Concern) } }

        RBI_MODULE_NAME = "RailsTypeIdMethods"

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes
              .select { |c| c < RailsTypeId::Concern }
          end
        end

        sig { override.void }
        def decorate
          root.create_path(constant) do |klass|
            klass.create_module(RBI_MODULE_NAME) do |methods_mod|
              methods_mod.create_method(
                "type_id",
                return_type: "TypeID",
              )
            end
            klass.create_include(RBI_MODULE_NAME)
          end
        end
      end
    end
  end
end