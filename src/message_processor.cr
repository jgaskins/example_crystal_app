require "amqp-client"

AMQP::Client.start ENV["AMQP_URL"] do |amqp|
  amqp.channel do |channel|
    exchange_name = "example-exchange"
    queue_name = "example-queue"

    channel.exchange_declare exchange_name, type: "fanout"
    exchange = channel.fanout_exchange(exchange_name)

    q = channel.queue(queue_name)

    q.bind exchange_name, ""
    q.subscribe no_ack: false do |message|
      spawn do
        # Route message to handlers here
        message.body_io.gets_to_end

        channel.basic_ack message.delivery_tag
      rescue
        channel.basic_nack message.delivery_tag
      end
    end

    sleep
  end
end
