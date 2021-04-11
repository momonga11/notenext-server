# frozen_string_literal: true

# ActiveRecord::Baseを継承した独自クラス
class ApplicationRecord < ActiveRecord::Base
  include ActiveStorageSupport::SupportForBase64

  self.abstract_class = true
end
