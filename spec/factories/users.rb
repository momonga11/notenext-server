FactoryBot.define do
  factory :user do
    name { 'testUser1' }
    sequence(:email) { |n| "test#{n}@example.com" }
    password { 'password1' }
    provider { 'email' }
    sequence(:uid) { |n| "test#{n}@example.com" }
    confirmed_at { Time.now }

    trait :user_with_projects do
      after(:build) do |user|
        create(:users_project, user: user, project: create(:project))
      end
    end
  end

  factory :user_new, class: 'User' do
    name { 'testNewUser1' }
    email { 'testNew@example.com' }
    password { 'password1' }
    password_confirmation { 'password1' }
    uid { 'testNew@example.com' }

    factory :user_new_name_null do
      name { '' }
    end

    factory :user_new_email_null do
      email { '' }
    end

    factory :user_new_password_null do
      password { '' }
    end

    factory :user_new_password_confirmation_null do
      password_confirmation { '' }
    end
  end

  factory :user_new_not_name, class: 'User' do
    email { 'test1@example.com' }
    password { 'password1' }
    password_confirmation { 'password1' }
    confirm_success_url { 'http://ng-token-auth.dev' }
  end

  factory :user_new_not_email, class: 'User' do
    name { 'testUser1' }
    password { 'password1' }
    password_confirmation { 'password1' }
    confirm_success_url { 'http://ng-token-auth.dev' }
  end

  factory :user_new_not_password, class: 'User' do
    name { 'testUser1' }
    email { 'test1@example.com' }
    password_confirmation { 'password1' }
    confirm_success_url { 'http://ng-token-auth.dev' }
  end

  factory :user_for_update, class: 'User' do
    name { 'testUser2' }

    trait :update_email do
      email { 'testupdate@example.com' }
    end

    trait :create_user do
      email { 'testupdate@example.com' }
      password { 'password1' }
      provider { 'email' }
      uid { 'testupdate@example.com' }
      confirmed_at { Time.now }
    end

    trait :update_password do
      password { 'password2' }
      password_confirmation { 'password2' }
    end

    trait :not_equal_current_password do
      current_password { 'password3' }
      password { 'password2' }
      password_confirmation { 'password2' }
    end

    trait :not_equal_password_confirmation do
      password { 'password2' }
      password_confirmation { 'password3' }
    end

    trait :exist_current_password do
      current_password { 'password1' }
    end

    trait :not_exist_password do
      password_confirmation { 'password2' }
    end

    trait :not_exist_password_confirmation do
      password { 'password2' }
    end
  end
end
