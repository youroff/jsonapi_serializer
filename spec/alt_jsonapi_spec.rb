require "spec_helper"

describe AltJsonapi do
  it "has a version number" do
    expect(AltJsonapi::VERSION).not_to be nil
  end

  it "provides key transforms" do
    variants = ["SomeAttribute", "some-attribute", "some_attribute"]
    variants += variants.map(&:to_sym)
    transform = lambda { variants.map { |v| AltJsonapi.key_transform(v) }.uniq }

    expect(transform.call).to contain_exactly(:some_attribute)

    AltJsonapi.set_key_transform(:dasherize)
    expect(transform.call).to contain_exactly(:"some-attribute")

    AltJsonapi.set_key_transform(:camelize)
    expect(transform.call).to contain_exactly(:someAttribute)

    AltJsonapi.set_key_transform do |str|
      str.to_s.upcase.gsub(/[^A-Z]/, "").to_sym
    end
    expect(transform.call).to contain_exactly(:SOMEATTRIBUTE)

    AltJsonapi.set_key_transform(:underscore)
  end

  it "provides type transform" do
    transform = lambda {  AltJsonapi.type_transform "CoolNameSpace::ModelClass" }

    expect(transform.call).to eq :cool_name_space_model_class

    AltJsonapi.set_type_namespace_separator :ignore
    expect(transform.call).to eq :model_class

    AltJsonapi.set_type_namespace_separator "-_-"
    expect(transform.call).to eq :"cool_name_space-_-model_class"

    AltJsonapi.set_type_transform :camelize
    expect(transform.call).to eq :"coolNameSpace-_-modelClass"

    AltJsonapi.set_type_transform :dasherize
    expect(transform.call).to eq :"cool-name-space-_-model-class"

    AltJsonapi.set_type_namespace_separator "_"
    AltJsonapi.set_type_transform :underscore
  end
end
