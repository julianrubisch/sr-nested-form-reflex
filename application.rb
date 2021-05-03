require "action_controller/railtie"
require "action_cable/engine"
require "active_model"
require "active_record"
require "nulldb/rails"
require "rails/command"
require "rails/commands/server/server_command"
require "cable_ready"
require "stimulus_reflex"

module ApplicationCable; end

class ApplicationCable::Connection < ActionCable::Connection::Base
  identified_by :session_id

  def connect
    self.session_id = request.session.id
  end  
end

class ApplicationCable::Channel < ActionCable::Channel::Base; end

class ApplicationController < ActionController::Base; end

class ApplicationReflex < StimulusReflex::Reflex; end

class Book < ActiveRecord::Base
  has_many :chapters
  
  accepts_nested_attributes_for :chapters
end

class Chapter < ActiveRecord::Base
end

class NestedFormReflex < ApplicationReflex
  before_reflex do
    session[:forms] ||= {}
    session[:forms]["Book"] ||= Book.new
  end
  
  def add    
    session[:forms]["Book"].chapters.build
  end
end

class DemosController < ApplicationController
  def show
    @book = session.fetch(:forms, {}).fetch("Book", Book.new)
    render inline: <<~HTML
      <html>
        <head>
          <title>NestedFormReflex Pattern</title>
          <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta2/dist/css/bootstrap.min.css" rel="stylesheet">
          <%= javascript_include_tag "/index.js", type: "module" %>
        </head>
        <body>
          <div class="container my-3">
            <h1>NestedFormReflex</h1>
            <%= form_for(@book, url: "#") do |form| %>
              <div class="mb-3 row">
                <%= form.label :title, class: "col-sm-2 col-form-label" %>
                <div class="col-sm-10">
                  <%= form.text_field :title, class: "form-control", placeholder: "Enter a book title" %>
                </div>
              </div>
              
              <hr/>
              
              <%= form.fields_for :chapters do |chapter_fields| %>
                <h4>Chapter <%= chapter_fields.index + 1 %></h4>
                <div class="mb-3 row">
                  <%= chapter_fields.label :title, class: "col-sm-2 col-form-label" %>
                  <div class="col-sm-10">
                    <%= chapter_fields.text_field :title, class: "form-control", placeholder: "Enter a chapter title", data: {reflex_permanent: true} %>
                  </div>
                </div>                
              <% end %>
              
              <button type="button" class="btn btn-outline-primary" data-reflex="click->NestedForm#add">Add Chapter</button>
            <% end %>
          </div>
        </body>
      </html>
    HTML
  end
end

class MiniApp < Rails::Application
  require "stimulus_reflex/../../app/channels/stimulus_reflex/channel"

  config.action_controller.perform_caching = true
  config.consider_all_requests_local = true
  config.public_file_server.enabled = true
  config.secret_key_base = "cde22ece34fdd96d8c72ab3e5c17ac86"
  config.secret_token = "bf56dfbbe596131bfca591d1d9ed2021"
  config.session_store :cache_store
  config.hosts.clear

  Rails.cache = ActiveSupport::Cache::RedisCacheStore.new(url: "redis://localhost:6379/1")
  Rails.logger = ActionCable.server.config.logger = Logger.new($stdout)
  ActionCable.server.config.cable = {"adapter" => "redis", "url" => "redis://localhost:6379/1"}

  routes.draw do
    mount ActionCable.server => "/cable"
    get '___glitch_loading_status___', to: redirect('/')    
    resource :demo, only: :show
    root "demos#show"
  end
end

ActiveRecord::Base.establish_connection adapter: :nulldb, schema: "schema.rb"

Rails::Server.new(app: MiniApp, Host: "0.0.0.0", Port: ARGV[0]).start
