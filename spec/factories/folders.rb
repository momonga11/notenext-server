FactoryBot.define do
  factory :folder do
    name { 'testFolder1' }
    description { '吾輩は猫である。名前はまだない' }
    association :project
  end

  factory :folder2, class: Folder  do
    name { 'testFolder2' }
    description { '木曾路はすべて山の中である。あるところは岨づたいに行く崖の道であり、あるところは数十間の深さに臨む木曾川の岸であり、あるところは山の尾をめぐる谷の入り口である。' }
    association :project
    lock_version { 0 }
  end
end
