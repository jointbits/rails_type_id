# typed: true
# frozen_string_literal: true

module RailsTypeId
  # MigrationHelper makes migrating a Rails model to type IDs a bit easier.
  module MigrationHelper
    extend T::Sig

    # Sets up the type ID columns for `id` and dependent models
    sig do
      params(
        model_klass: T.untyped,
        dependent_models: T::Hash[T.untyped, T.nilable(String)]
      ).void
    end
    def setup_type_id(model_klass, dependent_models)
      T.bind(self, T.untyped)
      table_name = model_klass.table_name

      add_column table_name, :type_id, :text, null: true
      dependent_models.each do |dm, fk_name|
        fk_id =
          if fk_name
            "#{fk_name}_type_id"
          else
            "#{table_name.singularlize}_type_id"
          end
        add_column dm.table_name, fk_id, :text, null: true
      end
    end

    # Once data is backfilled, `migrate_to_type_id` takes care of swapping the columns
    sig do
      params(
        model_klass: T.untyped,
        dependent_models: T::Hash[T.untyped, T.nilable(String)]
      ).void
    end
    def migrate_to_type_id(model_klass, dependent_models)
      T.bind(self, T.untyped)
      table_name = model_klass.table_name

      change_column_null table_name, :type_id, false

      dependent_models.each_key do |dm|
        remove_foreign_key dm.table_name, table_name
      end

      rename_column table_name, :id, :old_id
      rename_column table_name, :type_id, :id

      dependent_models.each do |dm, fk_name|
        if fk_name
          fk_id = "#{fk_name}_id"
          fk_type_id = "#{fk_name}_type_id"
        else
          fk_id = "#{table_name.singularize}_id"
          fk_type_id = "#{table_name.singularize}_type_id"
        end
        rename_column dm.table_name, fk_id, "old_#{fk_id}"
        rename_column dm.table_name, fk_type_id, fk_id
        change_column_null dm.table_name, "old_#{fk_id}", true
      end

      execute "ALTER TABLE #{table_name} DROP CONSTRAINT #{table_name}_pkey;"
      execute "ALTER TABLE #{table_name} ADD PRIMARY KEY (id);"

      execute "ALTER TABLE ONLY #{table_name} ALTER COLUMN old_id DROP DEFAULT"
      change_column_null table_name, :old_id, true

      dependent_models.each do |dm, fk_name|
        if fk_name
          add_foreign_key dm.table_name, table_name, column: "#{fk_name}_id"
        else
          add_foreign_key dm.table_name, table_name
        end
      end
    end
  end
end
