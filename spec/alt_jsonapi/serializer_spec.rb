require "spec_helper"

describe AltJsonapi::Serializer do
  before(:each) {
    class ASerializer
      include AltJsonapi::Serializer
      attributes :a, b: :c
      attribute :d do |object|
        object.e
      end
    end

    @record = OpenStruct.new(id: 1, a: :a, c: :b, e: :d)
  }

  after(:each) { Object.send(:remove_const, "ASerializer") }

  it "serializes parts properly" do
    hash = ASerializer.new.serializable_hash(@record)
    expect(hash[:data]).to include(id: "1", type: :a, attributes: Hash[[:a, :b, :d].map {|x| [x, x]}])
  end

  it "allows to remap id and type" do
    ASerializer.class_eval do
      id { |obj| obj.a }
      type :a_type
    end

    hash = ASerializer.new.serializable_hash(@record)
    expect(hash[:data]).to include(id: :a, type: :a_type)
  end

  it "allows to define fieldset and fields config is properly normalized" do
    hash = ASerializer.new(fields: {a: ["a", :b]}).serializable_hash(@record)
    expect(hash[:data][:attributes].keys).to contain_exactly(:a, :b)
  end

  it "serializes relationships and selected includes" do
    class XSerializer
      include AltJsonapi::Serializer
      attributes :z, :ignored
    end

    class YSerializer
      include AltJsonapi::Serializer
    end

    ASerializer.class_eval do
      has_many :xs, serializer: XSerializer
      belongs_to :y
    end

    serializer = ASerializer.new(fields: {x: ["z"]}, include: "xs")
    @record.xs = (1..2).map do |i|
      OpenStruct.new(id: i, z: "x#{i}", ignored: "never mind")
    end
    @record.y = OpenStruct.new(id: 3)

    hash = serializer.serializable_hash(@record)
    expect(hash[:data][:relationships][:xs][:data]).to include({id: "1", type: :x})
    expect(hash[:data][:relationships][:xs][:data]).to include({id: "2", type: :x})
    expect(hash[:data][:relationships][:y][:data]).to include(id: "3", type: :y)
    expect(hash[:included].length).to eq 2
    expect(hash[:included].first).to include(id: "1", type: :x)
    expect(hash[:included].first[:attributes].keys).to contain_exactly(:z)

    # Let's check that includes are not duplicating
    record2 = OpenStruct.new(id: 2, xs: [@record.xs.last])
    hash = serializer.serializable_hash([@record, record2])
    expect(hash[:data].length).to eq 2
    expect(hash[:included].length).to eq 2

    ["XSerializer", "YSerializer"].each { |s| Object.send(:remove_const, s) }
  end

  it "does not include records that appear in the main collection (circular relations)" do
    class SSerializer; end
    class TSerializer
      include AltJsonapi::Serializer
      has_many :ss, serializer: SSerializer
    end

    SSerializer.class_eval do
      include AltJsonapi::Serializer
      belongs_to :t
    end

    t = OpenStruct.new(id: 2)
    s = OpenStruct.new(id: 1, t: t)
    s2 = OpenStruct.new(id: 3)
    t.ss = [s, s2]

    serializer = SSerializer.new(include: [t: :ss])
    hash = serializer.serializable_hash(s)
    expect(hash[:included].map { |i| i[:id] }).to contain_exactly("2", "3")

    ["TSerializer", "SSerializer"].each { |s| Object.send(:remove_const, s) }
  end
end
