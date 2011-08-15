class ObserverController
  def initialize(connection, observer)
    channel = AMQP::Channel.new(connection)

    receiving_queue = channel.queue('etl.observer', :durable => true)
    sending_queue = channel.queue('etl.transform', :durable => true)

    receiving_queue.subscribe(:ack => true, &method(:receive_message))

    @exchange = channel.direct('')
    @observer = observer
  end

  def receive_message(payload)
    #begin
      message = @observer.process_message(BSON.deserialize(payload))
    #rescue
    #  puts BSON.deserialize(payload).inspect
    #end

    @exchange.publish(BSON.serialize(message).to_s, :routing_key => 'etl.transform') if message != false
  end
end
