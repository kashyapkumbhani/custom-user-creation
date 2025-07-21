Rails.application.config.after_initialize do
  # Hook into User model to support custom created_at timestamps
  User.class_eval do
    attr_accessor :custom_created_at_timestamp
    
    # Add callback to set custom timestamp after user is created
    after_create :apply_custom_timestamp
    
    private
    
    def apply_custom_timestamp
      if custom_created_at_timestamp.present?
        begin
          parsed_time = Time.parse(custom_created_at_timestamp)
          
          # Update both created_at and updated_at to the custom time
          self.update_columns(
            created_at: parsed_time,
            updated_at: parsed_time
          )
          
          Rails.logger.info "[Custom User Creation] User #{username} (ID: #{id}) backdated to #{parsed_time}"
          
        rescue ArgumentError => e
          Rails.logger.error "[Custom User Creation] Failed to parse timestamp '#{custom_created_at_timestamp}': #{e.message}"
        end
      end
    end
  end
  
  # Extend UsersController to handle the custom_created_at parameter
  UsersController.class_eval do
    # Override the create method to capture custom_created_at
    alias_method :original_create, :create
    
    def create
      # Store the custom timestamp if provided
      custom_timestamp = params[:custom_created_at] || params[:user]&.[](:custom_created_at)
      
      # Call original create method first
      result = original_create
      
      # If user was created successfully and we have a custom timestamp
      if response.status == 200 && custom_timestamp.present?
        # Find the created user and set the custom timestamp
        begin
          response_data = JSON.parse(response.body)
          if response_data['success'] && response_data['user_id']
            user = User.find(response_data['user_id'])
            user.custom_created_at_timestamp = custom_timestamp
            user.save # This will trigger the after_create callback
          end
        rescue => e
          Rails.logger.error "[Custom User Creation] Error processing custom timestamp: #{e.message}"
        end
      end
      
      result
    end
  end
end 