# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    name { 'testProject1' }
    description { 'あいうえおかきくけこさしすせそ' }
  end

  factory :project2, class: 'Project' do
    name { 'testProject2' }
    description { 'たちつてとなにぬねのはひふへほ' }
    lock_version { 0 }
  end
end
