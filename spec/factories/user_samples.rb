# frozen_string_literal: true

FactoryBot.define do
  factory :user_sample do
    association :user
    payout { false }
  end
end
