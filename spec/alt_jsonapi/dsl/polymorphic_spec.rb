require "spec_helper"

describe AltJsonapi::DSL::Polymorphic do
  class FruitSerializer; end
  class OwnerSerializer; end

  class PolymorphicSerializer
    include AltJsonapi::DSL::Polymorphic
    attributes :one
    has_many :fruits
    id { |obj| obj.slug }
    resolver do |obj|
      case obj
      when TypeA then :type_a
      when TypeB then :type_b
      end
    end
  end

  class TypeASerializer < PolymorphicSerializer
    attributes :two
    belongs_to :owner
  end

  class TypeBSerializer < PolymorphicSerializer
    attributes :two, :three
  end

  it "registers children" do
    expect(PolymorphicSerializer.meta_poly).to contain_exactly(TypeASerializer, TypeBSerializer)
  end

  it "inherits parents attributes" do
    expect(PolymorphicSerializer.meta_attributes.keys).to contain_exactly(:one)
    expect(TypeASerializer.meta_attributes.keys).to contain_exactly(:one, :two)
    expect(TypeBSerializer.meta_attributes.keys).to contain_exactly(:one, :two, :three)
  end

  it "inherits parents relationships" do
    expect(PolymorphicSerializer.meta_relationships.keys).to contain_exactly(:fruits)
    expect(TypeASerializer.meta_relationships.keys).to contain_exactly(:fruits, :owner)
    expect(TypeBSerializer.meta_relationships.keys).to contain_exactly(:fruits)
  end

  it "inherits id hook" do
    object = double("object", slug: "yay")
    expect(TypeASerializer.meta_id).to eq TypeBSerializer.meta_id
    expect(TypeASerializer.meta_id.call(object)).to eq "yay"
  end
end
