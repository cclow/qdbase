$:.unshift File.dirname(__FILE__)

require 'json'
require 'sinatra/base'

module Qdbase
  class Collection
    def initialize(name)
      @name = name
      @objects = {}
    end

    def insert(data)
      id = data['id']
      object = get_object(id)
      if object
        [nil, nil] # don't allow create if same id exist
      else
        id = canonize_id(SecureRandom::uuid) unless id # reuse id
        @objects[id] = data.merge!(id: id, created_at: (now = Time.now), updated_at: now)
        [id, @objects[id]]
      end
    end

    def get(id)
      object = get_object(id)
      [id, object]
    end

    def update(id, data)
      object = get_object(id)
      if object && data
        object.merge!(data).merge!(id: id, updated_at: Time.now)
        [id, object]
      else
        [nil, nil]
      end
    end

    def destroy(id)
      @objects.delete(canonize_id(id))
    end

    private
    def get_object(id)
      @objects[canonize_id(id)] if id
    end

    def canonize_id(id)
      id.gsub('-','').downcase
    end
  end

  class Database
    def initialize
      @collections = {}
    end
    def collection(name)
      @collections[name] || new_collection(name)
    end

    private
    def new_collection(name)
      @collections[name] = Collection.new(name)
    end
  end

  class App < ::Sinatra::Base
    configure do
      set :database, ::Qdbase::Database.new
    end

    post "/:collection" do
      collection = get_collection
      data = ::JSON.parse(params["data"])
      id, object = collection.insert(data)
      id ? set_response(201, "/#{params[:collection]}/#{id}", object) : status(409) # conflict
    end

    get "/:collection/:id" do
      collection = get_collection
      id, object = collection.get(params[:id])
      object ? set_response(200, "/#{params[:collection]}/#{id}", object) : status(404)
    end

    put "/:collection/:id" do
      collection = get_collection
      data = ::JSON.parse(params[:data])
      id, object = collection.update(params[:id], data) if data
      id ? set_response(200, "/#{params[:collection]}/#{id}", object) : status(404)
    end

    delete "/:collection/:id" do
      collection = settings.database.collection(params[:collection])
      collection.destroy(params[:id])
      status 200 # delete is idempotent so success even if object not found
    end

    private
    def get_collection
      settings.database.collection(params[:collection])
    end

    def set_response(status_code, location=nil, object=nil)
      status status_code
      headers "Location" => location if location
      body object.to_json if object
    end
  end
end
