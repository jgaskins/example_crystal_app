require "amqp-client"
require "statsd"
require "uuid"
require "uuid/json"

abstract struct Message
  @@type : String = {{@type.stringify}}
  @@type_map = Hash(String, self.class).new

  macro type(my_type = nil)
    {% if my_type %}
      @@type : String = {{my_type.stringify}}
    {% else %}
      @@type
    {% end %}
  end

  class_getter type

  def self.[](json : String) : Message
    parser = JSON::PullParser.new(json)
    parser.on_key "type" do
      type = @@type_map.fetch parser.read_string do |key|
        @@type_map[key] = {{@type.subclasses}}.find(Default) do |subclass|
          subclass.type == key
        end
      end

      return type.from_json json
    end

    Default.from_json json
  end

  def self.[]=(key, value)
    @@type_map[key] = value
  end
end

struct Foo < Message
  type FooBar

  JSON.mapping(
    product_id: UUID,
    customer_email: String,
    product_details: FileData | String,
  )

  struct FileData
    JSON.mapping(data: String)

    def inspect(io)
      io << "FileData(...)"
    end
  end
end

struct Default < Message
  JSON.mapping(type: String)
end

id = UUID.random
data = File.read(__FILE__)

exchange_name = "example-exchange"
queue_name = "example-queue"

statsd = Statsd::Client.new

if ENV["PRODUCER"]?
  spawn do
    AMQP::Client.start ENV["AMQP_URL"] do |amqp|
      amqp.channel do |channel|
        channel.exchange_declare exchange_name, type: "fanout"
        exchange = channel.fanout_exchange(exchange_name)

        loop do
          json = {
            type: "FooBar",
            product_id: id,
            customer_email: "jamie@example.com",
            product_details: { data: data },
          }.to_json

          exchange.publish json, ""
        end

        sleep
      end
    end
  end
end

AMQP::Client.start ENV["AMQP_URL"] do |amqp|
  amqp.channel do |channel|
    q = channel.queue(queue_name)

    q.bind exchange_name, ""
    q.subscribe no_ack: false do |msg|
      spawn do
        # Route message to handlers here
        message = Message[msg.body_io.gets_to_end]

        channel.basic_ack msg.delivery_tag
        statsd.increment "worker.messages_processed", tags: ["worker:#{message.class.name.gsub("::", "-").underscore}"]
      rescue ex
        pp ex
        channel.basic_nack msg.delivery_tag, requeue: true
      end
    end

    sleep
  end
end
