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
      # Route message to handlers here

      channel.basic_ack message.delivery_tag
    end

    sleep
  end
end
