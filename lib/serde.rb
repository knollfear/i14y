module Serde
  def self.serialize_hash(hash, language, language_field_keys)
    language_field_keys.each do |key|
      value = hash[key.to_sym]
      if value.present?
        sanitized_value = Loofah.fragment(value).text(encode_special_chars: false).squish
        hash.store("#{key}_#{language}", sanitized_value)
        hash.delete(key)
      end
    end
    hash.merge!(uri_params_hash(hash[:path])) if hash[:path].present?
    hash[:tags] = hash[:tags].extract_array if hash[:tags].present?
    hash
  end

  def self.deserialize_hash(hash, language, language_field_keys)
    derivative_language_fields = language_field_keys.collect { |key| "#{key}_#{language}" }
    (derivative_language_fields & hash.keys).each do |field|
      hash[field.chomp("_#{language}")] = hash.delete(field)
    end
    misc_fields = %w(basename extension url_path domain_name bigrams)
    hash.except(*(misc_fields))
  end

  private

  def self.uri_params_hash(path)
    hash = {}
    uri = URI.parse(path)
    hash[:basename] = File.basename(uri.path, '.*')
    hash[:extension] = File.extname(uri.path).sub(%r{^.}, '').downcase
    hash[:url_path] = uri.path
    hash[:domain_name] = uri.host
    hash
  end
end
