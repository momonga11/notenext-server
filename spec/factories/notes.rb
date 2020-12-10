FactoryBot.define do
  factory :note do
    title { 'testNote1' }
    association :project
    association :folder
  end
end
