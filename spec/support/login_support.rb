module LoginSupport
  def sign_in(user); end
end

RSpec.configure do |config|
  config.include LoginSupport
end
