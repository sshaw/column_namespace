# Column Namespace

[![Build Status](https://travis-ci.org/sshaw/column_namespace.svg?branch=master)](https://travis-ci.org/sshaw/column_namespace)

Group columns on your Active Record model under a "namespace method".

## Usage

Given the following database table (note the columns beginning with `"external_"`):
```sql
create table products (
  id int unsigned,
  name varchar(255),
  external_product_id bigint unsigned,
  external_variant_id bigint unsigned,
  external_metafield_id bigint unsigned
)
```

Add the following to its model:
```ruby
class Product < ApplicationRecord
  extend ColumnNamespace
  column_namespace "external_"
end
```

Now you can do:
```ruby
product = Product.new(:external => { :product_id => 123, :variant_id => 999 })

p product.external.product_id  # 123
p product.external.variant_id  # 999

product.save!

p product[:external_variant_id]  # 999

product.external.variant_id = 21341510
product.save!

product[:external_variant_id]  # 21341510

product = Product.last
p product.external.to_h  # { :product_id => 1, :metafield_id => nil, ... }
```

Alternatively you can specify the namespace method and its columns:
```ruby
class Product < ApplicationRecord
  extend ColumnNamespace
  column_namespace :some_method => %w[name external_product_id]
end
```

This gives you:
```ruby
product = Product.new(:some_method => { :name => "sshaw", :external_product_id => 99 })
product.some_method.name = nil
product.some_method.external_product_id = 1_000_00

# etc... same stuff as before
```


### But Isn't This What `composed_of` Does‽

Yes, but, no!

`composed_of` forces you to create and explicitly use a "value object". In some cases (like in the above examples)
this class is artificial. It doesn't exist in your domain –nor should it!

Using the above examples with `composed_of` do not work. Instead of:
```ruby
product = Product.last
product.external.product_id = 510
product.save!  # does not save 510
```

You'd have to write:
```ruby
product = Product.last
product.external = External.new(:product_id => 510)
product.save!
```

The same applies for validation:
```ruby
# In Product:
# validates :external_product_id, :numericality => { :greater_than => -1 }
product = Product.last
product.external.product_id = -1
product.valid?  # true
```

You'd have to assign an instance of `External` to `product.external` for this to work.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "column_namespace"
```

Or:

```
gem install column_namespace
```

## Author

Skye Shaw [skye.shaw AT gmail.com]

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
