require "spec_helper"
require "active_record"

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database  => ":memory:"
)

ActiveRecord::Base.connection.create_table(:products, :force => true) do |t|
  t.integer :external_product_id
  t.integer :external_variant_id
  t.integer :external_metafield_id
  t.string :a
  t.string :b
end

class Product < ActiveRecord::Base
  extend ColumnNamespace

  column_namespace "external_"
  column_namespace :foo => %w[a b]
end

RSpec.describe ColumnNamespace do
  ACCESSORS = %w[product_id variant_id metafield_id].flat_map { |name| [name, "#{name}="] }

  context "given a column prefix string" do
    it "creates a nested class with the unprefixed column names as attributes" do
      expect(Product.const_defined?("External", false)).to be true

      product = Product.new
      expect(product).to respond_to(:external)
      expect(product.external).to respond_to(*ACCESSORS)
    end

    it "assigns the prefix class' attributes to the prefixed columns" do
      product = Product.create!(:external_product_id => 3, :external_variant_id => 2, :external_metafield_id => 1)

      product.external.product_id = 111
      product.external.variant_id = 222
      product.external.metafield_id = 333

      # Not overridden yet
      expect(product.external_product_id).to eq 3
      expect(product.external_variant_id).to eq 2
      expect(product.external_metafield_id).to eq 1

      # We assign before validation
      product.valid?

      expect(product.external.product_id).to eq 111
      expect(product.external.variant_id).to eq 222
      expect(product.external.metafield_id).to eq 333

      product.save!
      product.reload

      expect(product.external.product_id).to eq 111
      expect(product.external.variant_id).to eq 222
      expect(product.external.metafield_id).to eq 333
    end

    context ".new" do
      it "accepts a prefix Hash" do
        attributes = { :product_id => 1, :variant_id => 2, :metafield_id => 3 }
        product = Product.new(:external => attributes)

        expect(product.external.product_id).to eq 1
        expect(product.external.variant_id).to eq 2
        expect(product.external.metafield_id).to eq 3
      end
    end

    context "when the prefix does not include trailing non-word characters" do
      it "does not include trailing characters in prefix in the attributes" do
        instance = Class.new(ActiveRecord::Base) do
          self.table_name = "products"

          extend ColumnNamespace
          # Should be same as if "external_" was given
          column_namespace "external"
        end.new

        expect(instance).to respond_to(:external)
        expect(instance.external).to respond_to(*ACCESSORS)
      end
    end
  end

  context "given a namespace to column mapping" do
    it "creates a nested class with the given column names as attributes" do
      expect(Product.const_defined?("Foo", false)).to be true

      product = Product.new
      expect(product).to respond_to(:foo)
      expect(product.foo).to respond_to(:a, :a=, :b, :b=)
    end

    it "assigns the attributes to the prefixed columns" do
      product = Product.create!(:a => "1", :b => "2")

      product.foo.a = "11"
      product.foo.b = "22"

      # Not overridden yet
      expect(product.a).to eq "1"
      expect(product.b).to eq "2"

      # We assign before validation
      product.valid?

      expect(product.foo.a).to eq "11"
      expect(product.foo.b).to eq "22"

      product.save!
      product.reload

      expect(product.foo.a).to eq "11"
      expect(product.foo.b).to eq "22"
    end
  end
end
