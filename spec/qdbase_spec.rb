ENV['RACK_ENV'] = 'test'
$:.unshift File.expand_path("..", File.dirname(__FILE__))

require 'rack/test'
require 'minitest/spec'
require 'minitest/autorun'
require 'qdbase'

include Rack::Test::Methods

def app
  Qdbase::App.new
end

describe 'qdbase' do
  before do
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
      @user = {"name" => "John Doe"}
      post '/users',  data: @user.to_json
    end
    it "should return created" do
      last_response.status.must_equal 201
    end
    it "should return the object location" do
      last_response.header['Location'].wont_be_empty
      last_response.header['Location'].must_match %r|/users/.*|
    end
    it "should return the object" do
      object = JSON.parse(last_response.body)
      object['name'].must_equal(@user['name'])
    end

    describe "with already existing id" do
      before do
        id = last_response.header['Location'].gsub('/users/', '')
        @user1 = {"id" => id, "name" => "Jane Foe"}
        post '/users', data: @user1.to_json
      end

      it "should return with conflict status" do
        last_response.status.must_equal 409
      end
    end
  end

  describe 'GET object' do
    before do
      @user = {"name" => "John Doe"}
      post '/users', data: @user.to_json
      get last_response.header['Location']
    end

    it "should return the saved object" do
      object = JSON.parse(last_response.body)
      object['name'].must_equal @user['name']
    end
    it "should return the object location" do
      last_response.header['Location'].wont_be_empty
      last_response.header['Location'].must_match %r|/users/.*|
    end
  end

  describe 'PUT "/:collection/:id"' do
    before do
      @user = {"name" => "John Doe"}
      @user1 = {"name" => "Jane Doe"}
    end

    describe "for existing object" do
      before do
        post '/users',  data: @user.to_json
        put last_response.header['Location'], data: @user1.to_json
      end

      it "should return 200" do
        last_response.status.must_equal 200
      end
      it "should update the object" do
        get last_response.header['Location']
        object = JSON.parse(last_response.body)
        object['name'].must_equal @user1['name']
      end
      it "should return the object location" do
        last_response.header['Location'].wont_be_empty
        last_response.header['Location'].must_match %r|/users/.*|
      end
    end

    describe "for non existing object" do
      before do
        put @no_such_object_uri, data: @user1.to_json
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
        @user = {"name" => "John Doe"}
        post '/users',  data: @user.to_json
        @uri = last_response.header['Location']
        delete @uri
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
