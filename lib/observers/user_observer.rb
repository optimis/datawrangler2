class UserObserver < ReportingObserver

  watch :permissions, :on => :create_and_destroy do |message| 
    message.observer_action = 'UPDATE'
    message.observer_select_statement = User.joins(:permissions).where(:permissions => {:id => message.query['id']}).to_sql
  end

  watch :permissions do |message| 
    if message.updated_any_of_these?(["role_id", "location_id","location_type"])
      message.observer_action = 'UPDATE'
      message.observer_select_statement = User.joins(:permissions).where(:permissions => {:id => message.query['id']}).to_sql
    end
  end
  
  watch :roles do |message|
    if message.data.keys.include?("name")      
      message.observer_action=('UPDATE')
      message.observer_select_statement=(User.joins(:permissions => :role).where(:role => { :permissions =>  {:id => message.query['id']} }).to_sql)
    end
  end
  
  watch :clinics do |message|
    if message.updated_any_of_these? "name"      
      message.observer_action=('UPDATE')
      message.observer_select_statement = User.joins(:permissions).where(:permissions => {:location_id => message.query['id'], :location_type => 'CLinic' }).to_sql
    end
  end
  
  watch :practices do |message|
    if message.updated_any_of_these? "name"      
      message.observer_action=('UPDATE')
      message.observer_select_statement = User.joins(:permissions).where(:permissions => {:location_id => message.query['id'], :location_type => 'Practice' }).to_sql
    end
  end
    
end
