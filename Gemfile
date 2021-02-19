source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.3', '>= 6.0.3.4'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.4.4'
# Use Puma as the app server
gem 'puma', '~> 4.1'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# 環境変数管理
gem 'dotenv-rails'

# devise関連
gem 'devise'
# masterブランチで改修されているバグがあるので指定する
gem 'devise_token_auth', :git => 'git://github.com/lynndylanhurley/devise_token_auth.git'
gem 'devise-i18n'

# シリアライズ関連
gem 'active_model_serializers', '~> 0.10.0'

# 複合PK対応
gem 'composite_primary_keys', '=12.0.3'

# Active_Storageを添付ファイルのbase64に対応させる
gem 'active_storage_base64'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails', '~> 4.0.1'
  gem 'factory_bot_rails', '~> 6.1.0'

  # Debug関連
  gem 'pry-rails'
  gem 'pry-byebug'

  # Test関連
  gem 'shoulda-matchers', '~> 4.0'

  # N+1問題を検知するgem
  gem 'bullet'
end

group :development do
  gem 'listen', '~> 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Debug関連
  gem "ruby-debug-ide"
  gem "debase"

  # Test関連
  gem 'spring-commands-rspec'
  gem 'rubocop-rspec', require: false
end
