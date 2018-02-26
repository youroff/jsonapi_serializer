require "spec_helper"

describe JsonapiSerializer::DSL::Polymorphic, "STI style" do
  class FruitSerializer; end
  class OwnerSerializer; end

  class Polymorphic
    include JsonapiSerializer::DSL::Polymorphic
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

  class TypeASerializer < Polymorphic
    attributes :two
    belongs_to :owner
  end

  class TypeBSerializer < Polymorphic
    attributes :two, :three
  end

  it "registers children" do
    expect(Polymorphic.meta_poly).to contain_exactly("TypeASerializer", "TypeBSerializer")
  end

  it "inherits parents attributes" do
    expect(Polymorphic.meta_attributes.keys).to contain_exactly(:one)
    expect(TypeASerializer.meta_attributes.keys).to contain_exactly(:one, :two)
    expect(TypeBSerializer.meta_attributes.keys).to contain_exactly(:one, :two, :three)
  end

  it "inherits parents relationships" do
    expect(Polymorphic.meta_relationships.keys).to contain_exactly(:fruits)
    expect(TypeASerializer.meta_relationships.keys).to contain_exactly(:fruits, :owner)
    expect(TypeBSerializer.meta_relationships.keys).to contain_exactly(:fruits)
  end

  it "inherits id hook" do
    object = double("object", slug: "yay")
    expect(TypeASerializer.meta_id).to eq TypeBSerializer.meta_id
    expect(TypeASerializer.meta_id.call(object)).to eq "yay"
  end

  it "provides resolver" do
    class TypeA; end

    expect(Polymorphic.meta_resolver.call(TypeA.new)).to eq :type_a
  end
end
