class TransformerController
  def initialize(connection, transformer)
    channel = AMQP::Channel.new(connection)

    receiving_queue = channel.queue('etl.transform', :durable => true)

    receiving_queue.subscribe(:ack => true, &method(:receive_message))

    @exchange = channel.direct('')
    @transformer = transformer
  end

  def receive_message(payload)
    log_messages = ['starting to transform message']
    log_attributes = {:start_time => Time.now, :application => 'datawrangler2-transformer', :error => false}
    log_attributes[:message] = BSON.deserialize(payload)

    begin
      @transformer.process_message(BSON.deserialize(payload))
      log_messages << 'finished transforming and saving the message'
    rescue
      log_messages << 'message transformation failed'

      log_attributes[:error] = true
      log_attributes[:error_message] = $!.message
      log_attributes[:traceback] = $!.backtrace.join("\n")
    end


    log_attributes[:end_time] = Time.now
    
    DataWrangler2.logger.info log_messages, log_attributes

  end
end
