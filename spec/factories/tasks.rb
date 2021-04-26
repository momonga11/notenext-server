# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    date_to { '2021-04-23' }
    completed { false }
    lock_version { 0 }
    association :project
    association :note

    factory :task_completed do
      completed { true }
    end

    factory :task_date_to_null do
      date_to { nil }
    end

    factory :task_date_to_greater_than do
      date_to { '2021-05-23' }
    end
  end
end
