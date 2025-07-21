# name: discourse-custom-user-creation
# about: Allows creating users with custom created_at timestamps via API
# version: 1.0.0
# authors: Forum Dashboard
# url: https://github.com/your-repo/discourse-custom-user-creation

enabled_site_setting :custom_user_creation_enabled

# Load our custom initializer
load File.expand_path('../config/initializers/custom_user_creation.rb', __FILE__)

after_initialize do
  # Plugin is ready
  Rails.logger.info "[Custom User Creation Plugin] Loaded successfully"
end 