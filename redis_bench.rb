# redis_bench.rb

require_relative 'sample_data_and_mesure_time'
require 'redis'
require 'json'

redis = Redis.new(url: REDIS_URL)

set_name = 'benchmark_test_set'

puts '...started Redis Benchmark...'

# Flush the Redis database to start with a clean slate
redis.flushdb

measure_time("Inserting #{SAMPLE_DATA.count} records into Redis") do
  SAMPLE_DATA.each do |data|
    redis.hmset(set_name, data[:name], data.to_json)
  end
end

# Define keys for the queries
keys = SAMPLE_DATA.map { |data| data[:name] }

# Define search queries to be tested
search_queries = [
  'Oliver',
  'companion for exact matching',
  'age:23-35'
]

search_queries.each_with_index do |query, index|
  measure_time("Running 10000 hmget: #{query}") do
    10_000.times do
      redis.hmget(set_name, keys[index % keys.size])
    end
  end
end

# Clear the Redis set
measure_time('clearing cluster') do
  redis.del(set_name)
end
