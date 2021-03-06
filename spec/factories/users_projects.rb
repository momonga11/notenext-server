# frozen_string_literal: true

FactoryBot.define do
  factory :users_project do
    is_owner { true }
    association :project
    association :user
  end
end
