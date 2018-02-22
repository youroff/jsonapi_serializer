require "spec_helper"

describe JsonapiSerializer::AUX::Converters do

  it "converts include string into hash" do
    hash = JsonapiSerializer.convert_include("author,comments.author,comments.theme")
    expect(hash).to include(author: {}, comments: {author: {}, theme: {}})
  end

  it "converts fields" do
    hash = JsonapiSerializer.convert_fields({"articles" => "title,body", "people" => "name"})
    expect(hash).to include(articles: [:title, :body], people: [:name])
  end
end
