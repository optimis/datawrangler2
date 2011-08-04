class UserObservable < ReportingObserver

  watch :permissions, :on => :create_and_destroy do |record| 
    push_updated_records_to_store_by_ids( record["user_id"] )
  end

  watch :permissions do |record, changes| 
    if ( changes.keys.include?("role_id") || changes.keys.include?("location_id") || changes.keys.include?("location_type") )
      push_updated_records_to_store_by_ids( record["user_id"] )
    end
  end
  
  watch :roles do |record, changes|
    if changes.keys.include?("name")      
      user_ids = Permission.all( :select => :user_id, :conditions => { :role_id => record["id"] } ).map{ |p| p.user_id }
      push_updated_records_to_store_by_ids( user_ids )
    end
  end
  
  watch :clinics do |record, changes|
    if changes.keys.include?("name")      
      user_ids = Permission.all( :select => :user_id, :conditions => { :location_type => "Clinic", :location_id => record["id"] } ).map{ |p| p.user_id }
      push_updated_records_to_store_by_ids( user_ids )
    end
  end
  
  watch :practices do |record, changes|
    if changes.keys.include?("name")      
      user_ids = Permission.all( :select => :user_id, :conditions => { :location_type => "Practice", :location_id => record["id"] } ).map{ |p| p.user_id }
      push_updated_records_to_store_by_ids( user_ids )
    end
  end
    
end