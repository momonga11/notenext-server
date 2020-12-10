FactoryBot.define do
  factory :user do
    name { 'testUser1' }
    sequence(:email) { |n| "test#{n}@example.com" }
    password { 'password1' }

    trait :user_with_projects do
      after(:build) do |user|
        create(:users_project, user: user, project: create(:project))
      end
    end
  end
end
