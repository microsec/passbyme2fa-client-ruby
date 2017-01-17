module JSONHelper
  def get_json_field(json, field)
    json[field] or raise IOError.new("Missing JSON field: #{field}")
  end
end
