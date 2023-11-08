# postgres_bench.rb

require_relative 'sample_data_and_mesure_time'
require 'pg'

db_config = {
  host: 'localhost',
  port: 5432,
  user: 'your_username',
  password: 'your_password',
  dbname: 'your_database_name'
}

table_name = 'benchmark_test_table'

# Establish a connection to PostgreSQL
conn = PG.connect(db_config)

puts '...started PostgreSQL Benchmark...'

# Create a new table
conn.exec("DROP TABLE IF EXISTS #{table_name}")
conn.exec("CREATE TABLE #{table_name} (name VARCHAR(255), description TEXT, age INTEGER)")

measure_time("Inserting #{SAMPLE_DATA.count} records into PostgreSQL") do
  SAMPLE_DATA.each do |data|
    conn.exec_params("INSERT INTO #{table_name} (name, description, age) VALUES ($1, $2, $3)",
                     [data[:name], data[:description], data[:age]])
  end
end

# Define queries to be tested
queries = [
  "SELECT * FROM #{table_name} WHERE name = 'Oliver'",
  "SELECT * FROM #{table_name} WHERE description LIKE '%companion for exact matching%'",
  "SELECT * FROM #{table_name} WHERE age BETWEEN 23 AND 35"
]

queries.each do |query|
  measure_time("Running 10000 queries: #{query}") do
    10_000.times do
      conn.exec(query)
    end
  end
end

measure_time("Droping table") do
  conn.exec("DROP TABLE IF EXISTS #{table_name}")
end

conn.close
