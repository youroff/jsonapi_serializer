require 'active_support/core_ext/object'
require 'active_support/concern'
require 'multi_json'
require 'oj'

module AltJsonapi::Common
  extend ActiveSupport::Concern

  def initialize(opts = {})
    @type = self.class.meta_type || guess_type
  end

  def type
    @type
  end

  def serializable_hash(payload, opts = {})
    hash = {}
    context = {tracker: {}, included: []}

    if payload.is_a? Array
      hash[:data] = payload.map { |p| record_hash(p, context) }
    else
      hash[:data] = record_hash(payload, context)
    end

    hash[:meta] = opts[:meta] if opts.has_key? :meta
    hash[:included] = context[:included] if context[:included].present?
    hash
  end

  def serialized_json(payload, opts = {})
    MultiJson.dump(serializable_hash payload, opts)
  end

  private
  def guess_type
    if self.class.name.end_with?('Serializer')
      AltJsonapi.type_transform(self.class.name.chomp('Serializer'))
    else
      raise "Serializer class must end with `Serializer` in order to be able to guess type"
    end
  end
end
