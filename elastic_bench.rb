# elastic_bench.rb

require_relative 'sample_data_and_mesure_time'
require 'elasticsearch'
require 'securerandom'

puts '...started ElasticSearch Benchmark...'

client = Elasticsearch::Client.new(url: ELASTIC_URL, log: false,
                                   transport_options: { request: { timeout: 60 } })

index_name = 'benchamrk_test_index'

# Create a new index with settings and mappings
client.indices.delete(index: index_name) if client.indices.exists?(index: index_name)
client.indices.create(index: index_name, body: {
                        settings: {
                          number_of_shards: 1,
                          number_of_replicas: 0
                        },
                        mappings: {
                          properties: {
                            name: { type: 'keyword' },
                            description: { type: 'text' },
                            age: { type: 'integer' }
                          }
                        }
                      })

measure_time("Uploading #{SAMPLE_DATA.count} documents") do
  SAMPLE_DATA.each do |document|
    client.index(index: index_name, body: document)
  end
end

search_queries = [
  { term:  { name: 'Oliver' } },
  { match: { description: 'companion for exact matching' } },
  { range: { age: { gte: 23, lte: 35 } } }
]

search_queries.each do |search_query|
  retries = 0
  indexes_with_retries = []

  measure_time("Running 10000 #{search_query.first[0]} queries") do
    10_000.times do |ind|
      client.search(index: index_name, body: { query: search_query })
    rescue StandardError
      if retries < 50
        retries += 1
        sleep(0.8)
        indexes_with_retries << ind
        retry
      else
        puts "Max search retries (50), Elastic isn't able to process this amount of requests."
      end
    end
  end

  puts "Search retries: #{retries}, failed indexes: #{indexes_with_retries}" if indexes_with_retries.any?
end

measure_time('Removing index') do
  client.indices.delete(index: index_name)
end
