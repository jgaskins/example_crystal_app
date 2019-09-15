require "http"
require "uuid"
require "uuid/json"

require "./queries"

class App
  include HTTP::Handler

  def call(context)
    products = Queries::ListProducts.call

    {
      products: products.map { |product|
        {
          id: product.id,
          name: product.name,
          description: product.description,
          price_cents: product.price_cents,
          created_at: product.created_at,
          updated_at: product.updated_at,
        }
      }
    }.to_json context.response
  end
end

port = (ENV["PORT"]? || 8080).to_i
puts "Listening on #{port}"
HTTP::Server.new([App.new]).listen "0.0.0.0", port
