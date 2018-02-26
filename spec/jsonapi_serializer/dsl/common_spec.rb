require "spec_helper"

describe JsonapiSerializer::DSL::Common, "attributes" do
  class AttributeSerializer
    include JsonapiSerializer::DSL::Common
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
    }.to raise_error(RuntimeError, "You attempted to inherit from AttributeSerializer, if you want to create Polymorphic serializer, include JsonapiSerializer::Polymorphic")
  end
end

describe JsonapiSerializer::DSL::Common, "relationships" do
  class CharacterSerializer; end
  class WriterSerializer; end

  class BookSerializer
    include JsonapiSerializer::DSL::Common
    has_many :characters, from: :heroes
    belongs_to :author, serializer: WriterSerializer
  end

  it "defines relationships" do
    expect(BookSerializer.meta_relationships.length).to eq 2
    dummy = OpenStruct.new(heroes: "heroes", author: "author")

    has_many = BookSerializer.meta_relationships[:characters]
    expect(has_many[:serializer]).to eq "CharacterSerializer"
    expect(has_many[:from].call(dummy)).to eq "heroes"

    belongs_to = BookSerializer.meta_relationships[:author]
    expect(belongs_to[:serializer]).to eq "WriterSerializer"
    expect(belongs_to[:from].call(dummy)).to eq "author"
  end
end

describe JsonapiSerializer::DSL::Common, "type" do
  class ModelSerializer
    include JsonapiSerializer::DSL::Common
    type :modello
  end

  class SuperModelSerializer
    include JsonapiSerializer::DSL::Common
    type "super_modello"
  end

  it "stores type in attribute" do
    expect(ModelSerializer.meta_type).to eq :modello
  end

  it "converts type into symbol" do
    expect(SuperModelSerializer.meta_type).to eq :super_modello
  end
end
