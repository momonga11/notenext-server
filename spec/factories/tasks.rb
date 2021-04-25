# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    date_to { '2021-04-23' }
    completed { false }
    association :project
    association :note
  end

  factory :task2, class: 'Task' do
    date_to { '2021-05-23' }
    completed { true }
    lock_version { 0 }
    association :project
    association :note
  end
end
