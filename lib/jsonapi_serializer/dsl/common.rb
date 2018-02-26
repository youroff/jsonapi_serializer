require 'active_support/concern'
require 'active_support/inflector'

module JsonapiSerializer::DSL
  module Common
    extend ActiveSupport::Concern

    included do
      @meta_id = lambda { |obj| obj.id.to_s }
      @meta_attributes = {}
      @meta_relationships = {}

      class << self
        alias_method :has_many, :relationship
        alias_method :belongs_to, :relationship

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
            @meta_attributes[attr.to_sym] = lambda { |obj| obj.public_send(attr) }
          when Hash
            attr.each do |key, val|
              @meta_attributes[key] = lambda { |obj| obj.public_send(val) }
            end
          end
        end
      end

      def attribute(attr, &block)
        @meta_attributes[attr.to_sym] = block_given? ? block : lambda { |obj| obj.public_send(attr) }
      end

      def relationship(name, opts = {})
        @meta_relationships[name.to_sym] = {}.tap do |relationship|
          from = opts.fetch(:from, name)
          relationship[:from] = from.respond_to?(:call) ? from : lambda { |r| r.public_send(from) }

          serializer = opts[:serializer]
          relationship[:serializer] = serializer ? serializer.to_s : "#{name.to_s.singularize.classify}Serializer"
        end
      end

      def inherited(subclass)
        raise "You attempted to inherit from #{self.name}, if you want to create Polymorphic serializer, include JsonapiSerializer::Polymorphic"
      end
    end
  end
end
