require 'rails_helper'

RSpec.describe User, type: :model do
  it '重複したメールアドレスなら無効な状態であること' do
    User.create(
      name: 'taro',
      email: 'taro@example.com',
      password: 'password'
    )

    user = User.new(
      name: 'jun',
      email: 'taro@example.com',
      password: 'password'
    )
    user.valid?
    expect(user.errors[:email]).to include('はすでに存在します')
  end
end
