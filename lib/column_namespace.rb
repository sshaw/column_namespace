# frozen_string_literal: true

require "column_namespace/version"
require "class2"

module ColumnNamespace
  def column_namespace(options)
    if options.is_a?(Hash)
      namespace_via_list(options)
      return
    end

    Array.wrap(options).each { |prefix| namespace_via_prefix(prefix) }
  end

  private

  def namespace_via_list(config)
    config.each do |namespace, columns|
      unknown = columns.map(&:to_s) - column_names
      raise "unknown column(s): #{unknown.to_sentence}" unless unknown.empty?

      klass = namespace.to_s.classify
      class2 self, klass => columns

      class_eval(<<-CODE)
        def #{namespace}
          @__#{namespace} ||= #{klass}.new(attributes.slice(*#{columns}))
        end

        def #{namespace}=(instance_or_attributes)
          @__#{namespace} = instance_or_attributes.is_a?(Hash) ? #{klass}.new(instance_or_attributes) : instance_or_attributes
        end

        before_validation do
          #{namespace}.to_h.each do |key, value|
            self[key] = value
          end
        end
      CODE
    end
  end

  def namespace_via_prefix(prefix)
    columns = column_names.select { |name| name.starts_with?(prefix) }
    raise "No attributes found with prefix #{prefix}" unless columns.any?

    method = prefix.sub(/[^[:alnum:]]*\z/i, "")
    klass  = method.classify
    prefix_regex = /\A#{Regexp.quote(prefix)}[^[:alnum:]]*/

    class2 self, klass => columns.map { |name| name.sub(prefix_regex, "") }

    class_eval(<<-CODE)
      def #{method}
        @__#{method} ||= #{klass}.new(attributes.slice(*#{columns}).transform_keys! { |k| k.sub(/#{prefix_regex}/, "") })
      end

      def #{method}=(instance_or_attributes)
        @__#{method} = instance_or_attributes.is_a?(Hash) ? #{klass}.new(instance_or_attributes) : instance_or_attributes
      end

      before_validation do
        #{method}.to_h.each do |key, value|
          self["#{prefix}\#{key}"] = value
        end
      end
    CODE
  end
end
