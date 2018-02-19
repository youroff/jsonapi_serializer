# Alt JSON API

JSONApi serializer for Ruby objects. Inspired by [Fast JSON API](https://github.com/Netflix/fast_jsonapi).

### Features

  * Flexible mapping of attributes
  * Custom computed attributes
  * Custom ID-mapping
  * Manual type setting
  * Key and type transforms
  * Polymorphic associations
  * Sparse fieldsets support
  * Nested includes (arbitrary depth)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'alt_jsonapi'
```

And then execute:

```bash
$ bundle
```

## Usage

### Record identification

Records in JSONApi are identified by `type` and `id`. Normally these attributes can be derived implicitly from serializer name and id by default is just `object.id`. But you can redefine this behavior by using following DSL-methods:

```ruby
class MovieSerializer
  include AltJsonapi::Serializer
  # Without type hook, type of the record will be derived
  # from the serializer name. In this case it would be :movie
  type :film

  # Using id hook, you can define how id would be retrieved.
  # By default it will be taken from `id` attribute of the model.
  id { |object| object.slug }
end
```

You can use public method `MovieSerializer.new.id_hash(record)` to get identification object (for example): `{id: 'matrix', type: :film}`

### Attributes configuration

Alt JSON API supports direct mapping of attributes, as well as remapping and custom attributes that are returned by lambda.

```ruby
class MovieSerializer
  include AltJsonapi::Serializer
  # attributes accepts names of attributes
  # and/or pairs (hash) of attributes of serialized model
  # pointing to attributes of target model
  attributes :name, release_year: :year

  # attribute accepts a block with serializable record as parameter
  attribute :rating do |movie|
    "%.2g" % (movie.rating / 10.0)
  end
end
```

In this example, serializer will access `record.name` and `record.year` to fill attributes `name` and `release_year` respectively. Rating block will convert 95 into 9.5 and make it string.

### Relationships configuration

In order to define relationships, you can use `belongs_to` and `has_many` DSL methods. They accept options `serializer` and `from`. By default, serializer will try to guess relationship serializer by the name of relation. In case of `:director` relation, it would try to use `DirectorSerializer` and crash since it's not defined. Use `serializer` parameter to set serializer explicitly. Option `from` is used to point at the attribute of the model that actually returns the relation object(s) if it's different.

```ruby
class MovieSerializer
  include AltJsonapi::Serializer
  belongs_to :director, serializer: PersonSerializer
  has_many :actors, from: :cast
end
```

From the perspective of serializer, there is no distinction between `belongs_to` and `has_one` relations. Current implementation does not use ActiveRecord's specifics, such as `object.{relation}_id` or `object.{relation}_ids` to access relation ids, which means you will have to preload these relations to avoid DB-calls during serialization. This is done deliberately for two reasons:

  * Identifier of serialized object (`id`) can be remapped to another attribute, for example `slug`.
  * This library is intended to be ORM-agnostic, you can easily use it to serialize some graph structures.

### Polymorphic relationships

Polymorphic serializers can handle objects whose type is unknown in advance. You can use them in relations or standalone. In order to define polymorphic serializer you need to create a root class by including `AltJsonapi::PolymorphicSerializer` and optionally defining `resolver` callback that'll help to determine what is the type of the model you're trying to serialize. There is an implicit resolver that applies `AltJsonapi.type_transform` to the record class name.

```ruby
class CommentableSerializer
  include AltJsonapi::PolymorphicSerializer
  # You can define common attributes and relations
  # that will be shared by all nested serializers
  attributes :title, :date
  has_many :tags
  belongs_to :author

  # You must implement the resolver, a block
  # that takes the model and returns a type of the model.
  # For safety you might define a fallback case and corresponding fallback serializer
  # that will inherit its config from polymorphic serializer.
  resolver do |model|
    case model
    when Post then :post
    when Item then :item
    else
      :commentable_fallback
    end
  end
end
```

Then you need to inherit from the parent class and it'll trigger automatic registration of sublasses at the parent class. So in this example `CommentableSerializer` will just know that it has `PostSerializer`, `ItemSerializer` and `CommentableFallbackSerializer` linked to it.

```ruby
class PostSerializer < CommentableSerializer
  # You can define additional attributes and relations in child serializer
  # and it will be merged.
  attributes :body
end

class ItemSerializer < CommentableSerializer
  attributes :description
end

class CommentableFallbackSerializer < CommentableSerializer; end
```

Then use it exactly the same as regular serializers. You shouldn't use children serializers directly. Also you cannot randomly inherit serializer classes, an attempt to inherit regular serializer's class will cause an error.

### Initialization and serialization

Once serializers are defined, you can instantiate them with several options. Currently supported options are: `fields` and `include`.

`fields` must be a hash, where keys represent record types and values are list of attributes and relationships of the corresponding type that will be present in serialized object. If some type is missing, that means all attributes and relationships defined in serializer will be serialized. In case of `polymorphic` serializer, you can supply shared fields under polymorphic type. **_There is a caveat, though: if you define a fieldset for a parent polymorphic class and omit fieldsets for subclasses it will be considered that you did not want any of attributes and relationships defined in subclass to be serialized._**  

`include` defines an arbitrary depth tree of included relationships in a similar way as ActiveRecord's `includes`. Bear in mind that `fields` has precedence, which means that if some relationship is missing in fields, it will not be included either.  

```ruby
options = {}

# We're omitting fieldset for ItemSerializer here,
# only attributes/relationships defined in CommentableSerializer
# will be serialized for Item objects
options[:fields] = {
  commentable: [:title],
  post: [:body]
}

# You can define arbitrary nesting here
options[:include] = [:tags, author: :some_authors_relation]

serializer = CommentableSerializer.new(options)
```

Then you can just reuse serializer's instance to serialize appropriate datasets, while supplying optional parameters, such as meta object.

```ruby
serializer.serialazable_hash(movies, meta: meta)
# or
serializer.serialized_json(movies, meta: meta)
```

## Performance

By running `bin/benchmark` you can launch performance test locally, however numbers are fluctuating widely. The example output is as follows:

### Base case

|       Adapters       |  10 hash/json (ms)   |  100 hash/json (ms)  | 1000 hash/json (ms)  | 10000 hash/json (ms) |
| -------------------- |:--------------------:|:--------------------:|:--------------------:|:--------------------:|
|    AltJsonapiTest    |     0.36 / 1.17      |     1.55 / 1.98      |    13.74 / 20.18     |   156.31 / 208.86    |
|   FastJsonapiTest    |     0.16 / 0.19      |     1.14 / 1.75      |    11.86 / 18.13     |   124.13 / 176.97    |

### With includes

|       Adapters       |  10 hash/json (ms)   |  100 hash/json (ms)  | 1000 hash/json (ms)  | 10000 hash/json (ms) |
| -------------------- |:--------------------:|:--------------------:|:--------------------:|:--------------------:|
|    AltJsonapiTest    |     0.51 / 0.46      |     2.05 / 2.50      |    15.28 / 21.59     |   159.89 / 214.49    |
|   FastJsonapiTest    |     0.26 / 0.25      |     2.01 / 2.47      |    15.54 / 20.11     |   154.82 / 211.48    |

Performance tests do not include any advanced features, such as fieldsets, nested includes or polymorphic serializers, and were mostly intended to make sure that adding these features did not make serializer slower (or at least significantly slower), but there are models prepared to extend these tests. PRs are welcome.

## Roadmap

  * Removing as many dependencies as possible. Opt-in JSON-library. Possibly removing dependency on `active_support`.
  * Creating alt_jsonapi_rails to make rails integration simple
  * ...

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/alt_jsonapi. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
