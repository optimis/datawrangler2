class TransformerController
  def initialize(connection, transformer)
    channel = AMQP::Channel.new(connection)

    receiving_queue = channel.queue('etl.transform', :durable => true)

    receiving_queue.subscribe(:ack => true, &method(:receive_message))

    @exchange = channel.direct('')
    @transformer = transformer
  end

  def receive_message(payload)
    #begin
      @transformer.process_message(BSON.deserialize(payload))
    #rescue
    #  puts BSON.deserialize(payload).inspect
    #end

  end
end
