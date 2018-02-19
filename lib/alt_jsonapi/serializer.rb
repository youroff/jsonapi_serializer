require 'active_support/core_ext/object'
require 'active_support/concern'
require 'alt_jsonapi/dsl/common'
require 'alt_jsonapi/utils'
require 'alt_jsonapi/common'
require 'set'

module AltJsonapi::Serializer
  extend ActiveSupport::Concern
  include AltJsonapi::DSL::Common
  include AltJsonapi::Utils
  include AltJsonapi::Common

  def initialize(opts = {})
    super(opts)
    @id = self.class.meta_id
    unless opts[:id_only]
      @attributes = []
      @relationships = []
      @includes = normalize_includes(opts.fetch(:include, []))
      prepare_fields(opts)
      prepare_attributes
      prepare_relationships
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
    @relationships.each_with_object({}) do |(key, type, from, serializer), hash|
      if rel = record.public_send(from)
        if rel.is_a?(Array)
          hash[key] = {data: []}
          rel.each do |item|
            id = serializer.id_hash(item)
            hash[key][:data] << id
            add_included(serializer, item, id, context) if @includes.has_key?(key)
          end
        else
          id = serializer.id_hash(rel)
          hash[key] = {data: id}
          add_included(serializer, rel, id, context) if @includes.has_key?(key)
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
  def prepare_fields(opts)
    @fields = opts.fetch(:fields, {})
    if opts[:poly_fields].present? || @fields[@type].present?
      @fields[@type] = opts.fetch(:poly_fields, []) + [*@fields.fetch(@type, [])].map { |f| AltJsonapi.key_transform(f) }
      @fields[@type].uniq!
    end
  end

  def prepare_attributes
    key_intersect(@fields[@type], self.class.meta_attributes.keys).each do |key|
      @attributes << [key, self.class.meta_attributes[key]]
    end
  end

  def prepare_relationships
    key_intersect(@fields[@type], self.class.meta_relationships.keys).each do |key|
      rel = self.class.meta_relationships[key]
      serializer = rel[:serializer].new(
        fields: @fields,
        include: @includes.fetch(key, []),
        id_only: !@includes.has_key?(key)
      )
      @relationships << [key, rel[:type], rel[:from], serializer]
    end
  end

  def add_included(serializer, item, id, context)
    if (context[:tracker][id[:type]] ||= Set.new).add?(id[:id]).present?
      attributes = serializer.attributes_hash(item)
      relationships = serializer.relationships_hash(item, context)
      inc = id.clone
      inc[:attributes] = attributes if attributes.present?
      inc[:relationships] = relationships if relationships.present?
      context[:included] << inc
    end
  end
end
