require "alt_jsonapi/version"
require "alt_jsonapi/aux/converters"
require "alt_jsonapi/serializer"
require "alt_jsonapi/polymorphic_serializer"
require "active_support/inflector"

module AltJsonapi

  TRANSFORMS = {
    dasherize: lambda { |str| str.to_s.underscore.dasherize.to_sym },
    underscore: lambda { |str| str.to_s.underscore.to_sym },
    camelize: lambda { |str| str.to_s.underscore.camelize(:lower).to_sym }
  }

  @@key_transform = TRANSFORMS[:underscore]
  @@type_transform = TRANSFORMS[:underscore]
  @@type_namespace_separator = "_"

  def self.key_transform(key)
    @@key_transform.call(key)
  end

  def self.type_transform(klass)
    segments = klass.split("::").map { |segment| @@type_transform.call(segment) }
    if @@type_namespace_separator == :ignore
      segments.last
    else
      segments.join(@@type_namespace_separator)
    end.to_sym
  end

  def self.set_key_transform(name = nil, &block)
    if name.nil? && block_given?
      @@key_transform = block
    elsif name.is_a?(Symbol) && !block_given?
      @@key_transform = TRANSFORMS[name]
    else
      raise ArgumentError, "set_key_transform accepts either a standard transform symbol (:dasherize, :underscore or :camelize) or a block"
    end
  end

  def self.set_type_namespace_separator(separator)
    if separator == :ignore || separator =~ /^( |-|_)+$/
      @@type_namespace_separator = separator
    else
      raise ArgumentError, "namespace separator can only contain spaces (not recommended), dashes or underscores"
    end
  end

  def self.set_type_transform(name = nil, &block)
    if name.nil? && block_given?
      @@type_transform = block
    elsif name.is_a?(Symbol) && !block_given?
      @@type_transform = TRANSFORMS[name]
    else
      raise ArgumentError, "set_type_transform accepts either a standard transform symbol (:dasherize, :underscore or :camelize) or a block"
    end
  end
end
