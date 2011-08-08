class Message

  def initialize(message)
    @message = message
    @message['observer'] = {}
  end

  def action
    @message['sql']['action'] == 'UPDATE' ? :update : :create_and_destroy
  end

  def table_name
    @message['sql']['table'].to_sym
  end

  def query
    @message['sql']['query']
  end

  def data
    @message['sql']['data']
  end

  def observer_class=(clazz)
    @message['observer']['class'] = clazz
  end

  def observer_select_statement=(statement)
    @message['observer']['sql'] = statement
  end


  def updated_any_of_these?(keys)
    catch(:found) do
      @message['sql']['data'].keys.each do |key|
        throw :found, true if keys.include? key
      end
      return false
    end 
  end

  def observer_action=(action)
    @message['observer']['action'] = action
  end

  def not_observered?
    @message['observer'].empty?
  end

  def to_h
    @message
  end
end
