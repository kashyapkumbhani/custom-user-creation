# name: discourse-custom-user-creation
# about: Allows creating users with custom created_at timestamps via API
# version: 1.0.0
# authors: Forum Dashboard
# url: https://github.com/your-repo/discourse-custom-user-creation

enabled_site_setting :custom_user_creation_enabled

after_initialize do
  # Modify the UsersController to accept custom created_at parameter
  module ::CustomUserCreationExtension
    def create
      # Check if custom_created_at parameter is provided
      custom_created_at = params[:custom_created_at]
      
      # Call the original create method
      result = super
      
      # If user was created successfully and custom_created_at was provided
      if result.is_a?(User) && custom_created_at.present?
        begin
          # Parse the custom timestamp
          parsed_time = Time.parse(custom_created_at)
          
          # Update the user's timestamps directly in the database
          # Using update_columns to skip validations and callbacks
          result.update_columns(
            created_at: parsed_time,
            updated_at: parsed_time
          )
          
          # Log the custom timestamp setting
          Rails.logger.info "User #{result.username} (ID: #{result.id}) created with custom timestamp: #{parsed_time}"
          
        rescue ArgumentError => e
          # Log error if timestamp parsing fails
          Rails.logger.warn "Failed to parse custom_created_at for user #{result.username}: #{e.message}"
        end
      end
      
      result
    end
  end
  
  # Apply the extension to UsersController
  ::UsersController.prepend(CustomUserCreationExtension)
  
  # Also extend the Admin::UsersController for admin API
  module ::AdminCustomUserCreationExtension
    def create
      # Check if custom_created_at parameter is provided
      custom_created_at = params[:custom_created_at]
      
      # Call the original create method
      result = super
      
      # Extract user from the response if it's successful
      user = nil
      if result.is_a?(Hash) && result[:user]
        user = result[:user]
      elsif result.is_a?(User)
        user = result
      end
      
      # If user was created successfully and custom_created_at was provided
      if user && custom_created_at.present?
        begin
          # Parse the custom timestamp
          parsed_time = Time.parse(custom_created_at)
          
          # Update the user's timestamps directly in the database
          user.update_columns(
            created_at: parsed_time,
            updated_at: parsed_time
          )
          
          # Log the custom timestamp setting
          Rails.logger.info "Admin created user #{user.username} (ID: #{user.id}) with custom timestamp: #{parsed_time}"
          
        rescue ArgumentError => e
          # Log error if timestamp parsing fails
          Rails.logger.warn "Failed to parse custom_created_at for admin-created user: #{e.message}"
        end
      end
      
      result
    end
  end
  
  # Apply the extension to Admin::UsersController
  ::Admin::UsersController.prepend(AdminCustomUserCreationExtension)
end 