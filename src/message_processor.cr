require "amqp-client"

AMQP::Client.start ENV["AMQP_URL"] do |amqp|
  amqp.channel do |channel|
    channel.exchange_declare "example-exchange", type: "fanout"
    exchange = channel.fanout_exchange "example-exchange"
    q = channel.queue "example-queue"

    q.bind exchange.name, ""
    q.subscribe do |message|
      # Route message to handlers here

      channel.basic_ack message.delivery_tag
    end

    sleep
  end
end
