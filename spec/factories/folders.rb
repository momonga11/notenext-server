FactoryBot.define do
  factory :folder do
    name { 'testFolder1' }
    association :project
  end
end
