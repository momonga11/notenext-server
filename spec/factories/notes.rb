# frozen_string_literal: true

FactoryBot.define do
  factory :note do
    title { 'testNote1' }
    text { '恥の多い生涯を送って来ました。自分には、人間の生活というものが、見当つかないのです。' }
    htmltext { '<div>恥の多い生涯を送って来ました。</div><div>自分には、人間の生活というものが、見当つかないのです。</div>' }
    association :project
    association :folder
  end

  factory :note2, class: 'Note' do
    title { 'testNote2' }
    text { '自分は東北の田舎に生れましたので、汽車をはじめて見たのは、よほど大きくなってからでした' }
    htmltext { '<div>自分は東北の田舎に生れましたので、</div><div>汽車をはじめて見たのは、よほど大きくなってからでした</div>' }
    lock_version { 0 }
    association :project
    association :folder
  end

  factory :note3, class: 'Note' do
    title { 'testNoteT3' }
    text { '自分は北陸の田舎に生れました' }
    htmltext { '' }
    lock_version { 0 }
    association :project
    association :folder
  end
end
