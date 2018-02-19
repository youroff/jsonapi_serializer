module AltJsonapi::Utils

  def normalize_includes(includes)
    case includes
    when String
      normalize_includes([includes.to_sym])
    when Symbol
      normalize_includes([includes])
    when Hash
      includes.each_with_object({}) do |(key, val), hash|
        hash[key] = normalize_includes(val)
      end
    when Array
      includes.each_with_object({}) do |entry, hash|
        case entry
        when Symbol
          hash[entry] = {}
        when Hash
          hash.merge!(normalize_includes(entry))
        end
      end
    end
  end

  def apply_splat(item, &block)
    if item.is_a? Array
      item.map { |i| block.call(i) }
    else
      block.call(item)
    end
  end

  def key_intersect(limited, full)
    limited && limited & full || full
  end
end
