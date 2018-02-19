require "spec_helper"

describe AltJsonapi::DSL::Common, "attributes" do
  class AttributeSerializer
    include AltJsonapi::DSL::Common
    attributes :simple, renamed: :original
    attribute :custom do |record|
      record.custom_operation
    end
  end

  it "defines attributes configuration on the class level" do
    expect(AttributeSerializer.meta_attributes.length).to eq 3

    object = double("object", simple: 1, original: 2, custom_operation: 3)
    expect(AttributeSerializer.meta_attributes[:simple].call(object)).to eq 1
    expect(AttributeSerializer.meta_attributes[:renamed].call(object)).to eq 2
    expect(AttributeSerializer.meta_attributes[:custom].call(object)).to eq 3
  end

  it "raises if regular serializer is inherited" do
    expect {
      class InheritedSerializer < AttributeSerializer; end
    }.to raise_error(RuntimeError, "You attempted to inherit regular serializer class, if you want to create Polymorphic serializer, include PolymorphicSerializer mixin")
  end
end

describe AltJsonapi::DSL::Common, "relationships" do
  class CharacterSerializer; end
  class WriterSerializer; end

  class BookSerializer
    include AltJsonapi::DSL::Common
    has_many :characters, from: :heroes
    belongs_to :author, serializer: WriterSerializer
  end

  it "defines relationships" do
    expect(BookSerializer.meta_relationships.length).to eq 2

    has_many = BookSerializer.meta_relationships[:characters]
    expect(has_many[:serializer]).to eq CharacterSerializer
    expect(has_many[:type]).to eq :has_many
    expect(has_many[:from]).to eq :heroes

    belongs_to = BookSerializer.meta_relationships[:author]
    expect(belongs_to[:serializer]).to eq WriterSerializer
    expect(belongs_to[:type]).to eq :belongs_to
    expect(belongs_to[:from]).to eq :author
  end
end

describe AltJsonapi::DSL::Common, "type" do
  class ModelSerializer
    include AltJsonapi::DSL::Common
    type :modello
  end

  class SuperModelSerializer
    include AltJsonapi::DSL::Common
    type "super_modello"
  end

  it "stores type in attribute" do
    expect(ModelSerializer.meta_type).to eq :modello
  end

  it "converts type into symbol" do
    expect(SuperModelSerializer.meta_type).to eq :super_modello
  end
end
