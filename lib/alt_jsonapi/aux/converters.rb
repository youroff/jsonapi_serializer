module AltJsonapi::AUX
  module Converters

    # http://jsonapi.org/format/#fetching-includes
    # This method converts include string into hash accepted by serializer
    def convert_include(include_string)
      include_string.split(",").each_with_object({}) do |path, includes|
        path.split(".").reduce(includes) do |ref, segment|
          ref[segment.to_sym] ||= {}
          ref[segment.to_sym]
        end
      end
    end

    # http://jsonapi.org/format/#fetching-sparse-fieldsets
    def convert_fields(fields)
      Hash[fields.map do |type, fields|
        [type.to_sym, fields.split(",").map(&:to_sym)]
      end]
    end
  end
end
