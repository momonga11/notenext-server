require 'rails_helper'

RSpec.describe Note, type: :model do
  it 'ファクトリで関連するデータを生成する' do
    note = FactoryBot.build(:note)
    puts "This note's project is #{note.project.inspect}"
    puts "This note's folder is #{note.folder.inspect}"
  end
end
