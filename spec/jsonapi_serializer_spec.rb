require "spec_helper"

describe JsonapiSerializer do
  it "has a version number" do
    expect(JsonapiSerializer::VERSION).not_to be nil
  end

  it "provides key transforms" do
    variants = ["SomeAttribute", "some-attribute", "some_attribute"]
    variants += variants.map(&:to_sym)
    transform = lambda { variants.map { |v| JsonapiSerializer.key_transform(v) }.uniq }

    expect(transform.call).to contain_exactly(:some_attribute)

    JsonapiSerializer.set_key_transform(:dasherize)
    expect(transform.call).to contain_exactly(:"some-attribute")

    JsonapiSerializer.set_key_transform(:camelize)
    expect(transform.call).to contain_exactly(:someAttribute)

    JsonapiSerializer.set_key_transform do |str|
      str.to_s.upcase.gsub(/[^A-Z]/, "").to_sym
    end
    expect(transform.call).to contain_exactly(:SOMEATTRIBUTE)

    JsonapiSerializer.set_key_transform(:underscore)
  end

  it "provides type transform" do
    transform = lambda {  JsonapiSerializer.type_transform "CoolNameSpace::ModelClass" }

    expect(transform.call).to eq :cool_name_space_model_class

    JsonapiSerializer.set_type_namespace_separator :ignore
    expect(transform.call).to eq :model_class

    JsonapiSerializer.set_type_namespace_separator "-_-"
    expect(transform.call).to eq :"cool_name_space-_-model_class"

    JsonapiSerializer.set_type_transform :camelize
    expect(transform.call).to eq :"coolNameSpace-_-modelClass"

    JsonapiSerializer.set_type_transform :dasherize
    expect(transform.call).to eq :"cool-name-space-_-model-class"

    JsonapiSerializer.set_type_namespace_separator "_"
    JsonapiSerializer.set_type_transform :underscore
  end
end
