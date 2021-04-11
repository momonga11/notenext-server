# frozen_string_literal: true

# Json形式への変換を実施するモジュール
module JsonSupport
  def json_parse_body(response)
    JSON.parse(response.body, symbolize_names: true)
  end
end

RSpec.configure do |config|
  config.include JsonSupport
end
