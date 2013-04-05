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
      object = @objects[canonize_id(id)] if id
      if object
        [nil, nil] # don't allow create if same id exist
      else
        id = canonize_id(SecureRandom::uuid) unless id # reuse id
        @objects[id] = data.merge!(id: id, created_at: Time.now, updated_at: Time.now)
        [id, @objects[id]]
      end
    end

    def get(id)
      object = @objects[canonize_id(id)] if id
      [id, object]
    end

    def update(id, data)
      object = @objects[canonize_id(id)] if id
      if object && data
        object.merge!(data).merge!(updated_at: Time.now)
        object['id'] = id
        [id, object]
      else
        [nil, nil]
      end
    end

    def destroy(id)
      @objects.delete(canonize_id(id))
    end

    private
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
      @collections[name] = (collection = Collection.new(name))
      collection
    end
  end

  class App < ::Sinatra::Base
    configure do
      set :database, ::Qdbase::Database.new
    end

    post "/:collection" do
      collection = settings.database.collection(params[:collection])
      data = ::JSON.parse(params["data"])
      id, object = collection.insert(data)
      if id
        status 201
        headers "Location" => "/#{params[:collection]}/#{id}"
        body object.to_json
      else
        status 409 # conflict
      end
    end

    get "/:collection/:id" do
      collection = settings.database.collection(params[:collection])
      id, object = collection.get(params[:id])
      if object
        status 200
        headers "Location" => "/#{params[:collection]}/#{id}"
        body object.to_json
      else
        status 404
      end
    end

    put "/:collection/:id" do
      collection = settings.database.collection(params[:collection])
      data = ::JSON.parse(params[:data])
      id, object = collection.update(params[:id], data) if data
      if id
        status 200
        headers "Location" => "/#{params[:collection]}/#{id}"
        body object.to_json
      else
        status 404 # not found
      end
    end

    delete "/:collection/:id" do
      collection = settings.database.collection(params[:collection])
      collection.destroy(params[:id])
      status 200 # delete is idempotent so success even if object not found
    end
  end
end
