require "spec_helper"
require 'ostruct'

describe JsonapiSerializer::Polymorphic, "relationship" do
  before(:each) {
    class BirdSerializer
      include JsonapiSerializer::Base
      attributes :name, :wing_span
    end

    class FishSerializer
      include JsonapiSerializer::Base
      attributes :name, :fin_count
    end

    class MemberSerializer
      include JsonapiSerializer::Polymorphic
      polymorphic_for BirdSerializer, FishSerializer
    end

    class ZooSerializer
      include JsonapiSerializer::Base
      attributes :name, :address
      has_many :members
    end

    class Bird < OpenStruct; end
    class Fish < OpenStruct; end
    class Zoo < OpenStruct; end
  }

  after(:each) {
    %w(Bird Fish Zoo)
      .map { |klass| [klass, klass + "Serializer"] }
      .flatten
      .each { |klass| Object.send(:remove_const, klass) }
    Object.send(:remove_const, "MemberSerializer")
  }

  it "serializes parts properly" do
    serializer = ZooSerializer.new(include: [:members])

    eagle = Bird.new(id: 1, name: "Eagle", wing_span: 7)
    carp = Fish.new(id: 2, name: "Carp", fin_count: 8)
    zoo = Zoo.new(id: 1, name: "Franklin", address: "Boston, MA", members: [eagle, carp])

    hash = serializer.serializable_hash(zoo)
    expect(hash[:data]).to include(id: "1", type: :zoo)
    expect(hash[:data][:attributes]).to include(name: "Franklin", address: "Boston, MA")
    expect(hash[:data][:relationships][:members][:data]).to include({id: "1", type: :bird}, {id: "2", type: :fish})
    expect(hash[:included].length).to eq 2

    eagle_hash = {id: "1", type: :bird, attributes: {name: "Eagle", wing_span: 7}}
    carp_hash = {id: "2", type: :fish, attributes: {name: "Carp", fin_count: 8}}
    expect(hash[:included]).to contain_exactly(eagle_hash, carp_hash)
  end
end
