require 'active_support/concern'
require 'active_support/inflector'

module AltJsonapi::DSL
  module Common
    extend ActiveSupport::Concern

    included do
      @meta_id = lambda { |obj| obj.id.to_s }
      @meta_attributes = {}
      @meta_relationships = {}

      class << self
        attr_reader :meta_type, :meta_id, :meta_attributes, :meta_relationships
      end
    end

    class_methods do
      def type(name)
        @meta_type = name.to_sym
      end

      def id(attr = nil, &block)
        case
        when attr.nil? && block_given?
          @meta_id = block
        when attr.present? && !block_given?
          @meta_id = lambda { |obj| obj.public_send(attr) }
        else
          raise ArgumentError, "ID hook requires either attribute name or block"
        end
      end

      def attributes(*attrs)
        attrs.each do |attr|
          case attr
          when Symbol, String
            @meta_attributes[attr.to_sym] = lambda { |obj| obj.public_send(attr.to_sym) }
          when Hash
            attr.each do |key, val|
              @meta_attributes[key] = lambda { |obj| obj.public_send(val) }
            end
          end
        end
      end

      def attribute(attr, &block)
        @meta_attributes[attr.to_sym] = block
      end

      def has_many(name, opts = {})
        @meta_relationships[name] = {
          type: :has_many,
          from: opts.fetch(:from, name),
          serializer: opts[:serializer] || guess_serializer(name.to_s.singularize)
        }
      end

      def belongs_to(name, opts = {})
        @meta_relationships[name] = {
          type: :belongs_to,
          from: opts.fetch(:from, name),
          serializer: opts[:serializer] || guess_serializer(name.to_s)
        }
      end

      def inherited(subclass)
        raise "You attempted to inherit regular serializer class, if you want to create Polymorphic serializer, include PolymorphicSerializer mixin"
      end

      private
      def guess_serializer(name)
        "#{name.classify}Serializer".constantize
      end
    end
  end
end
