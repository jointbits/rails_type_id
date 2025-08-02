# rails_type_id

A gem that makes simple to use [TypeID](https://github.com/broothie/typeid-ruby) as the primary key for ActiveRecord models.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add rails_type_id
```

## Usage

### Declaring on models
Add `RailsTypeId::Concern` to the model. This model's `id` field should have either a String or UUID database column type.

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
my_model.id             #=> "019867fe-560f-7941-a7ed-8472639c7ace"
my_model.type_id        #=> #<TypeID mm_01k1kzwngff50tfvc4e9hsrype>
my_model.type_id.to_s   #=> mm_01k1kzwngff50tfvc4e9hsrype
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

