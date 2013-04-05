ENV['RACK_ENV'] = 'test'
$:.unshift File.expand_path("..", File.dirname(__FILE__))

require 'rack/test'
require 'minitest/spec'
require 'minitest/autorun'
require 'qdbase'
require 'faker'

include Rack::Test::Methods

def app
  Qdbase::App.new
end

def returned_uri(last_response)
  last_response.header['Location']
end

def verify_same_attributes(data, object)
  object['name'].must_equal(data['name'])
  object['email'].must_equal(data['email'])
end

describe 'qdbase' do
  before do
    @user_1 = {"name" => Faker::Name.name, "email" => Faker::Internet.email}
    @user_2 = {"name" => Faker::Name.name, "email" => Faker::Internet.email}
    @no_such_object_uri = "/users/no-such-object"
  end

  describe 'GET "/"' do
    before do
      get '/'
    end
    it 'should return not found' do
      last_response.status.must_equal 404
    end
  end

  describe 'GET nonexisting object' do
    before do
      get @no_such_object_uri
    end
    it "should return not found" do
      last_response.status.must_equal 404
    end
  end

  describe 'POST new object' do
    before do
      post '/users',  data: @user_1.to_json
    end
    it "should return created" do
      last_response.status.must_equal 201
    end
    it "should return the object location" do
      returned_uri(last_response).wont_be_empty
      returned_uri(last_response).must_match %r|/users/.*|
    end
    it "should return the object" do
      object = JSON.parse(last_response.body)
      verify_same_attributes(object, @user_1)
    end

    describe "with already existing id" do
      before do
        id = returned_uri(last_response).gsub('/users/', '')
        post '/users', data: @user_2.merge(id: id).to_json
      end

      it "should return with conflict status" do
        last_response.status.must_equal 409
      end
    end
  end

  describe 'GET object' do
    before do
      post '/users', data: @user_1.to_json
      get returned_uri(last_response)
    end

    it "should return the saved object" do
      object = JSON.parse(last_response.body)
      verify_same_attributes(object, @user_1)
    end
    it "should return the object location" do
      returned_uri(last_response).wont_be_empty
      returned_uri(last_response).must_match %r|/users/.*|
    end
  end

  describe 'PUT "/:collection/:id"' do
    describe "for existing object" do
      before do
        post '/users',  data: @user_1.to_json
        put returned_uri(last_response), data: @user_2.to_json
      end

      it "should return 200" do
        last_response.status.must_equal 200
      end
      it "should update the object" do
        get returned_uri(last_response)
        object = JSON.parse(last_response.body)
        verify_same_attributes(object, @user_2)
      end
      it "should return the object location" do
        returned_uri(last_response).wont_be_empty
        returned_uri(last_response).must_match %r|/users/.*|
      end
    end

    describe "for non existing object" do
      before do
        put @no_such_object_uri, data: @user_2.to_json
      end

      it "should return 404" do
        last_response.status.must_equal 404
      end
    end
  end

  describe 'DELETE "/:collection/:id"' do
    it "should return 200" do
      delete @no_such_object_uri
      last_response.status.must_equal 200
    end

    describe "for existing object" do
      before do
        post '/users',  data: @user_1.to_json
        delete (@uri = returned_uri(last_response))
      end

      it "should return 200" do
        last_response.status.must_equal 200
      end
      it "should delete the object" do
        get @uri
        last_response.status.must_equal 404
      end
    end
  end
end
