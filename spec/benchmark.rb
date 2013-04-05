ENV['RACK_ENV'] = 'test'
$:.unshift File.expand_path("..", File.dirname(__FILE__))

require 'rack/test'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/benchmark'

require 'qdbase'
require 'faker'

include Rack::Test::Methods

def app
  Qdbase::App.new
end

def returned_uri(last_response)
  last_response.header['Location']
end

describe "qdbase speed test" do
  before do
    @records_count = 10000
    @uris = []
    @records_count.times do
      user = {'name' => Faker::Name.name, 'email' => Faker::Internet.email}
      post '/users', data: user.to_json
      @uris << returned_uri(last_response)
    end
  end

  bench_range { bench_exp 1, 100 }
  bench_performance_linear "find record by id" do |n|
    n.times do
      get @uris[Random.rand(@records_count)]
      last_response.status.must_equal 200
    end
  end
#   
#   bench_performance_linear "find record by query - like", 0.999 do |n|
#     n.times do
#       get '/User/name/like/Jane'
#       last_response.status.must_equal 200
#     end
#   end  
#   
#   bench_performance_linear "find record by query - integer compare", 0.999 do |n|
#     n.times do
#       get '/User/age/gt/50?type=integer'
#       last_response.status.must_equal 200
#     end
#   end
#   
#   bench_performance_linear "find record by query - date compare", 0.999 do |n|
#     n.times do
#       get '/User/created_at/gt/6-6-1999?type=time'
#       last_response.status.must_equal 200
#     end
#   end  

  bench_performance_linear "insert single record" do |n|
    user = {'name' => Faker::Name.name, 'email' => Faker::Internet.email}
    n.times do
      post '/users', data: user.to_json
      last_response.status.must_equal 201
    end
  end

end
