FactoryBot.define do
  factory :user_sample do
    association :user
    payout { false }
  end
end
