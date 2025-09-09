# rails_type_id

A gem that makes simple to use [TypeID](https://github.com/broothie/typeid-ruby) as the primary key for ActiveRecord models.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add rails_type_id
```

## Usage

### Database requirements

- ActiveRecord models should have an `id` field that is either a string-like type (`TEXT`, `VARCHAR`) .
  See [Migration](#migrating-existing-ids) if you have an existing `id` field.

### Declaring on models
Add `RailsTypeId::Concern` to the model. This model's `id` field should have a string-like database column type.

```ruby
# app/models/my_model.rb
require "rails_type_id"

class MyModel < ActiveRecord::Base
    include RailsTypeId::Concern

    # Prefix should be unique within your project
    with_type_id_prefix("mm")
end
```

### Using the `type_id` field

Model instances will have a `type_id` field of type `TypeID`.

```ruby
my_model = MyModel.create!(..)
my_model.id             #=> "mm_01k1kzwngff50tfvc4e9hsrype"
my_model.type_id        #=> #<TypeID mm_01k1kzwngff50tfvc4e9hsrype>
```

### Testing

`lib/rails_type_id/test_helpers.rb` contains some helper methods for writing wholesome tests.

### Migrating existing IDs

For models with an existing Rails `id` field (usually an auto-incrementing integer), you'll need to
migrate these to either a string-like column type. Below is an example migration for SQLite
using a `text` type for a Users model that has an associated Session.

```ruby
class MigrateUserToUUID < ActiveRecord::Migration[8.0]
    def change
        add_column :users, :uuid, :text, null: true
        add_column :sessions, :user_uuid, :text, null: true

        Users.find_each do |u|
            u.update(uuid: RailsTypeId::Concern::Helpers.generate_type_id("user"))
        end
        Session.find_each do |s|
            s.update(user_uuid: s.user.uuid)
        end
        change_column_null :users, :uuid, false
        change_column_null :sessions, :user_uuid, false

        remove_foreign_key :sessions, :users

        rename_column :users, :id, :integer_id
        rename_column :users, :uuid, :id

        rename_column :sessions, :user_id, :integer_user_id
        rename_column :sessions, :user_uuid, :user_id
        change_column_null :session, :integer_user_id, true

        execute "ALTER TABLE users DROP CONSTRAINT users_pkey;"
        execute "ALTER_TABLE users ADD PRIMARY KEY (id);"

        execute "ALTER TABLE ONLY users ALTER COLUMN integer_id DROP DEFAULT"
        change_column_null :users, :integer_id, true
        execute "DROP SEQUENCE IF EXISTS users_id_seq"

        add_foreign_key :sessions, :users
    end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Release

To cut a new release of this gem to Rubygems:

1. Create a release branch: `release-X.Y.Z`
1. Change the version `X.Y.Z` to match in `lib/rails_type_id/version.rb`.
1. `gh release create vX.Y.Z --target release-X.Y.Z`

