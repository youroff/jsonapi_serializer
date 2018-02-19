require 'active_support/concern'
require 'alt_jsonapi/dsl/common'

module AltJsonapi::DSL
  module Polymorphic
    extend ActiveSupport::Concern
    include AltJsonapi::DSL::Common

    included do
      @meta_poly = []
      @meta_resolver = lambda { |record| AltJsonapi.type_transform(record.class.name) }

      class << self
        attr_reader :meta_poly, :meta_resolver, :meta_inherited
      end
    end

    class_methods do
      def resolver(&block)
        if block_given?
          @meta_resolver = block
        else
          raise ArgumentError, "Resolver hook requires a block that takes record and returns its type."
        end
      end

      def inherited(subclass)
        parent = self
        subclass.class_eval do
          include AltJsonapi::Serializer
          @meta_attributes = parent.meta_attributes.clone
          @meta_relationships = parent.meta_relationships.clone
          @meta_id = parent.meta_id
          @meta_inherited = true
        end
        @meta_poly << subclass
      end
    end
  end
end
