require "spec_helper"
require 'ostruct'

describe JsonapiSerializer::Polymorphic, "STI style" do
  before(:each) {
    class AnimalSerializer
      include JsonapiSerializer::Polymorphic
      attributes :name
    end

    class BirdSerializer < AnimalSerializer
      attributes :wing_span
    end

    class FishSerializer < AnimalSerializer
      attributes :fin_count
    end

    class ZooSerializer
      include JsonapiSerializer::Base
      attributes :name, :address
      has_many :animals
    end

    class Animal < OpenStruct; end
    class Bird < OpenStruct; end
    class Fish < OpenStruct; end
    class Zoo < OpenStruct; end
  }

  after(:each) {
    %w(Animal Bird Fish Zoo)
      .map { |klass| [klass, klass + "Serializer"] }
      .flatten
      .each { |klass| Object.send(:remove_const, klass) }
  }

  it "serializes parts properly" do
    serializer = ZooSerializer.new(include: [:animals], fields: {animal: [:name], bird: [:wing_span]})

    eagle = Bird.new(id: 1, name: "Eagle", wing_span: 7)
    carp = Fish.new(id: 2, name: "Carp", fin_count: 8)
    zoo = Zoo.new(id: 1, name: "Franklin", address: "Boston, MA", animals: [eagle, carp])

    hash = serializer.serializable_hash(zoo)
    expect(hash[:data]).to include(id: "1", type: :zoo)
    expect(hash[:data][:attributes]).to include(name: "Franklin", address: "Boston, MA")
    expect(hash[:data][:relationships][:animals][:data]).to include({id: "1", type: :bird}, {id: "2", type: :fish})
    expect(hash[:included].length).to eq 2

    eagle_hash = {id: "1", type: :bird, attributes: {name: "Eagle", wing_span: 7}}
    carp_hash = {id: "2", type: :fish, attributes: {name: "Carp"}}
    expect(hash[:included]).to contain_exactly(eagle_hash, carp_hash)
  end
end
