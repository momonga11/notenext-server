# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersProject, type: :model do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:user) }

  it 'ユーザーが1つ目のプロジェクトを作成する場合、is_owner=trueとなる' do
    user = FactoryBot.build(:user, :user_with_projects)
    expect(user.users_projects[0].is_owner).to be_truthy
  end
end
