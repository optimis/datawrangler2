class Role < ActiveRecord::Base
  has_many :permissions
  has_many :clinics,    :through => :permissions, :source => :location, :source_type => "Clinic"
  has_many :practices,  :through => :permissions, :source => :location, :source_type => "Practice"
  has_many :users,      :through => :permissions
end