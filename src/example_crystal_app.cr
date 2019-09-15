require "http"
require "uuid"
require "uuid/json"

class App
  include HTTP::Handler

  PRODUCTS = [
    {
      id: UUID.random,
      name: "The First Product",
      description: "This is the first product in the collection",
      price_cents: 1000_00,
    },
    {
      id: UUID.random,
      name: "The Second Product",
      description: "This is the second product in the collection",
      price_cents: 1000_00,
    },
    {
      id: UUID.random,
      name: "The Third Product",
      description: "This is the third product in the collection",
      price_cents: 1000_00,
    },
  ]

  PAYLOAD = {
    customer: {
      id: UUID.random,
      name: "Jamie Gaskins",
      email: "jamie@example.com",
      created_at: Time.utc,
      updated_at: Time.utc,
    },
    order: {
      id: UUID.random,
      product_ids: PRODUCTS.map{ |p| p[:id] },
    },
    products: PRODUCTS,
  }

  def call(context)
    Fiber.yield # Simulate getting data from the DB
    PAYLOAD.to_json context.response
  end
end

port = (ENV["PORT"]? || 8080).to_i
puts "Listening on #{port}"
HTTP::Server.new([App.new]).listen "0.0.0.0", port
