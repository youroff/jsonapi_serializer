require "spec_helper"

describe JsonapiSerializer::DSL::Polymorphic, "relationship" do
  class CarSerializer; end
  class MotorcycleSerializer; end

  class VehicleSerializer
    include JsonapiSerializer::DSL::Polymorphic
    polymorphic_for "CarSerializer", "MotorcycleSerializer"
  end

  it "registers children" do
    expect(VehicleSerializer.meta_poly).to contain_exactly("CarSerializer", "MotorcycleSerializer")
  end
end
