require 'active_support/core_ext/object'
require 'active_support/concern'
require 'multi_json'
require 'jsonapi_serializer/dsl/polymorphic'
require 'jsonapi_serializer/utils'
require 'jsonapi_serializer/common'
require 'set'

module JsonapiSerializer::Polymorphic
  extend ActiveSupport::Concern
  include JsonapiSerializer::DSL::Polymorphic
  include JsonapiSerializer::Utils
  include JsonapiSerializer::Common

  def initialize(opts = {})
    super(opts)
    unless self.class.meta_inherited
      unless self.class.meta_resolver.respond_to? :call
        raise "Polymorphic serializer must implement a block resolving an object into type."
      end

      poly_fields = [*opts.dig(:fields, @type)].map { |f| JsonapiSerializer.key_transform(f) }
      if self.class.meta_poly.present?
        @poly = self.class.meta_poly.each_with_object({}) do |poly_class, hash|
          serializer = poly_class.new(opts.merge poly_fields: poly_fields)
          hash[serializer.type] = serializer
        end
      else
        raise "You have to create at least one children serializer for polymorphic #{self.class.name}"
      end
    end
  end

  def id_hash(record)
    serializer_for(record).id_hash(record)
  end

  def attributes_hash(record)
    serializer_for(record).attributes_hash(record)
  end

  def relationships_hash(record, context = {})
    serializer_for(record).relationships_hash(record, context)
  end

  def record_hash(record, context = {})
    hash = id_hash(record)

    attributes = attributes_hash(record)
    hash[:attributes] = attributes if attributes.present?

    relationships = relationships_hash(record, context)
    hash[:relationships] = relationships if relationships.present?

    hash
  end

  private
  def serializer_for(record)
    @poly[self.class.meta_resolver.call(record)] || (raise "Could not resolve serializer for #{record} associated with #{self.class.name}")
  end
end
