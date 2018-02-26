require 'active_support/core_ext/object'
require 'active_support/concern'
require 'jsonapi_serializer/dsl/common'
require 'jsonapi_serializer/utils'
require 'jsonapi_serializer/common'
require 'set'

module JsonapiSerializer::Base
  extend ActiveSupport::Concern
  include JsonapiSerializer::DSL::Common
  include JsonapiSerializer::Utils
  include JsonapiSerializer::Common

  def initialize(opts = {})
    super(opts)
    @id = self.class.meta_id
    unless opts[:id_only]
      fields = normalize_fields(opts.fetch(:fields, {}))
      if opts[:poly_fields].present?
        fields[@type] = fields.fetch(@type, []) + opts[:poly_fields]
      end

      includes = normalize_includes(opts.fetch(:include, {}))

      prepare_attributes(fields)
      prepare_relationships(fields, includes)
    end
  end

  def id_hash(record)
    {id: @id.call(record), type: @type}
  end

  def attributes_hash(record)
    @attributes.each_with_object({}) do |(key, val), hash|
      hash[key] = val.call(record)
    end
  end

  def relationships_hash(record, context = {})
    @relationships.each_with_object({}) do |(key, from, serializer, included), hash|
      if relation = from.call(record)
        if relation.respond_to?(:map)
          relation_ids = relation.map do |item|
            process_relation(item, serializer, context, included)
          end
          hash[key] = {data: relation_ids}
        else
          hash[key] = {data: process_relation(relation, serializer, context, included)}
        end
      else
        hash[key] = {data: nil}
      end
    end
  end

  def record_hash(record, context = {})
    hash = id_hash(record)
    if context[:tracker]
      (context[:tracker][hash[:type]] ||= Set.new).add?(hash[:id])
    end
    hash[:attributes] = attributes_hash(record) if @attributes.present?
    hash[:relationships] = relationships_hash(record, context) if @relationships.present?
    hash
  end

  private
  def prepare_attributes(all_fields)
    @attributes = []
    fields = all_fields[@type]
    self.class.meta_attributes.each do |attribute, getter|
      key = JsonapiSerializer.key_transform(attribute)
      if fields.nil? || fields.include?(key)
        @attributes << [key, getter]
      end
    end
  end

  def prepare_relationships(all_fields, includes)
    @relationships = []
    relations = all_fields[@type]
    self.class.meta_relationships.each do |relation, cfg|
      key = JsonapiSerializer.key_transform(relation)
      if relations.nil? || relations.include?(key)
        included = includes.has_key?(relation)
        serializer = cfg[:serializer].to_s.constantize.new(
          fields: all_fields,
          include: includes.fetch(relation, {}),
          id_only: !included
        )
        @relationships << [relation, cfg[:from], serializer, included]
      end
    end
  end

  def process_relation(item, serializer, context, included)
    id = serializer.id_hash(item)
    if included && (context[:tracker][id[:type]] ||= Set.new).add?(id[:id]).present?
      attributes = serializer.attributes_hash(item)
      relationships = serializer.relationships_hash(item, context)
      inc = id.clone
      inc[:attributes] = attributes if attributes.present?
      inc[:relationships] = relationships if relationships.present?
      context[:included] << inc
    end
    id
  end
end
