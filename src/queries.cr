require "neo4j"
require "mutex"

module Queries
  @@connection_pool = ConnectionPool(Neo4j::Bolt::Connection).new(capacity: 200) do
    Neo4j::Bolt::Connection.new(ENV["NEO4J_URL"], ssl: !!ENV["NEO4J_USE_SSL"]?)
  end

  class_getter connection_pool

  abstract struct Query
    def self.call(*args, **kwargs)
      new.call(*args, **kwargs)
    end

    def self.[](*args, **kwargs)
      call(*args, **kwargs)
    end

    def initialize(@pool : ConnectionPool(Neo4j::Bolt::Connection) = Queries.connection_pool)
    end

    def exec_cast(query, params : Neo4j::Map, types : Tuple(*TYPES)) : TYPES forall TYPES
      @pool.connection do |connection|
        connection.exec_cast query, params, types
      end
    end

    def exec_cast(query, params : Neo4j::Map, types : Tuple(*TYPES)) forall TYPES
      @pool.connection do |connection|
        connection.exec_cast query, params, types do |row|
          yield row
        end
      end
    end
  end

  struct ListProducts < Query
    def call : Array(Product)
      products = Array(Product).new
      exec_cast <<-CYPHER, Neo4j::Map.new, {Product} do |(product)|
        MATCH (p:Product)
        RETURN p
      CYPHER
        products << product
      end

      products
    end

    struct Product
      Neo4j.map_node(
        id: UUID,
        name: String,
        description: String,
        price_cents: Int32,
        created_at: Time,
        updated_at: Time,
      )
    end
  end

  class ConnectionPool(T)
    @lock = Mutex.new

    def initialize(@capacity = 25, &@new_connection : -> T)
      @current_size = 0
      @channel = Channel(T).new(@capacity)
    end

    def connection
      connection = check_out
      yield connection
    ensure
      check_in connection if connection
    end

    private def check_out : T
      @lock.synchronize do
        if (queue = @channel.@queue) && queue.empty? && @current_size < @capacity
          @current_size += 1
          return @new_connection.call
        end
      end

      @channel.receive
    end

    private def check_in(connection : T) : Nil
      @channel.send connection
    end
  end
end
