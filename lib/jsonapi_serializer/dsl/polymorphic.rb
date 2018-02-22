require 'active_support/concern'
require 'jsonapi_serializer/dsl/common'

module JsonapiSerializer::DSL
  module Polymorphic
    extend ActiveSupport::Concern
    include JsonapiSerializer::DSL::Common

    included do
      @meta_poly = []
      @meta_resolver = lambda { |record| JsonapiSerializer.type_transform(record.class.name) }

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

      def polymorphic_for(*serializers)
        @meta_poly += serializers
      end

      def inherited(subclass)
        parent = self
        subclass.class_eval do
          include JsonapiSerializer::Base
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
