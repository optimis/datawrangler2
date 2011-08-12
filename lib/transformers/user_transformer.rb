class UserTransformer < Transformer::Base

  self.model_class = ::User
  self.model_attributes = %w(first_name last_name practice_id state email)
  
  field :first_name
  field :last_name
  field :practice_id
  field :state
  field :email
  
  field :flatten_permissions do
    model_object.permissions.map do |p|
        { 'role'          => p.role.try(:name) || "",
          'location_type' => p.location_type,
          'location_name' => p.location.try(:name)
        }
    end
  end
  
end
