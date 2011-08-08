class Permission < ActiveRecord::Base
  belongs_to :user
  belongs_to :role

  belongs_to :location, :polymorphic => true
end
