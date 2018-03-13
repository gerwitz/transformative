module Transformative
  class Server < Sinatra::Application
    helpers Sinatra::LinkHeader
    helpers ViewHelper

    enable :sessions

    configure do
      # use Rack::SSL if settings.production?

      # this feels like an odd hack to avoid Sinatra's natural directory structure
      root_path = "#{File.dirname(__FILE__)}/../../"
      set :config_path, "#{root_path}config/"
      set :syndication_targets,
        JSON.parse(File.read("#{settings.config_path}syndication_targets.json"))
      set :markdown, layout_engine: :erb
      set :server, :puma

      set :views, "#{root_path}views/"
    end

    before do
      headers \
        "Referrer-Policy" => "no-referrer",
        "Content-Security-Policy" => "script-src 'self'"
    end

    get '/' do
      @sites = Site.all
      erb :index
    end

    get '/login' do
      if params.key?('code') # this is probably an indieauth callback
        url = Auth.url_via_indieauth(request.host_with_port, params[:code])
        login_url(url)
      end
      if session[:domain]
        redirect "/#{session[:domain]}/"
      else
        redirect '/'
      end
    end

    get '/logout' do
      session.clear
      redirect '/'
    end

    get '/:domain' do
      redirect "/#{params[:domain]}/"
    end

    get '/:domain/' do
      @site = find_site
      erb :site
    end

    post '/:domain/stores' do
      auth_for_domain
      @site = find_site
      if params.key?('type_id')
        type_id = params['type_id'].to_i
        store_class = Store.sti_class_from_sti_key(type_id)
        # puts "type: #{type_id}, class: #{store_class}"
        store = store_class.create(site_id: @site.id)
        store.update_fields(params, [:location, :user, :key])
      else
        raise TransformativeError.new("bad_request", "Can't POST a store without a type")
      end
      redirect "/#{@site.domain}/"
    end

    post '/:domain/flows' do
      auth_for_domain
      # auth_for_domain(params[:domain])
      @site = find_site
      if params.key?('flow_id')
        # editing
        flow = Flow.first(id: params[:flow_id].to_i)
        flow.update_fields(params, [:post_type_id, :name, :allow_media, :allow_meta, :path_template, :url_template, :content_template])
      else
        # creating
        flow = Flow.find_or_create(site_id: @site.id)
        flow.update_fields(params, [:post_type_id])
      end
      redirect "/#{@site.domain}/flows/#{flow.id}"
    end

    get '/:domain/flows/:id' do
      auth_for_domain
      @site = find_site
      @flow = Flow.find(id: params[:id].to_i, site_id: @site.id)
      erb :flow
    end

    post '/:domain/micropub' do
      puts "Micropub params=#{params}"
      site = find_site
      flows = site.flows_dataset
      # start by assuming this is a non-create action
      if params.key?('action')
        verify_action
        require_auth
        verify_url
        post = Micropub.action(params)
        status 204
      elsif params.key?('file')
        # assume this a file (photo) upload
        flow = flows.first(allow_media: true)
        require_auth
        url = Media.save(params[:file])
        headers 'Location' => url
        status 201
      else
        # assume this is a create
        require_auth
        verify_create
        post = Micropub.create(params)
        flow = flows.first(post_type_id: post.type_id)
        # post.syndicate(services) if services.any?
        # Store.save(post)
        flow.store.save(post)
        headers 'Location' => post.absolute_url
        status 202
      end
    end

    get '/:domain/micropub' do
      if params.key?('q')
        require_auth
        content_type :json
        case params[:q]
        when 'source'
          verify_url
          render_source
        when 'config'
          render_config
        when 'syndicate-to'
          render_syndication_targets
        else
          # Silently fail if query method is not supported
        end
      else
        'Micropub endpoint'
      end
    end

    get '/:domain/webmention' do
      "Webmention endpoint"
    end

    post '/:domain/webmention' do
      puts "Webmention params=#{params}"
      Webmention.receive(params[:source], params[:target])
      headers 'Location' => params[:target]
      status 202
    end

    not_found do
      status 404
      erb :'404'
    end

    error TransformativeError do
      e = env['sinatra.error']
      json = {
        error: e.type,
        error_description: e.message
      }.to_json
      halt(e.status, { 'Content-Type' => 'application/json' }, json)
    end

    error do
      erb :'500', layout: false
    end

    def deleted
      status 410
      erb :'410'
    end

  private

    # login with domain from url
    def login_url(url)
      domain = URI.parse(url).host.downcase
      @site = Site.find_or_create(domain: domain)
      @site.url = url
      @site.save
      session[:domain] = domain
    end

    def find_site
      if params[:domain]
        site = Site.first(domain: params[:domain].to_s)
        if site.nil?
          raise StandardError.new("No site found for '#{params[:domain].to_s}'")
        else
          return site
        end
      else
        not_found
      end
    end

    def auth_for_domain(domain = nil)
      domain ||= params[:domain]
      if domain != session[:domain]
        raise StandardError.new("Can't authenticate for domain '#{domain}'")
      end
    end

    def require_auth
      return unless settings.production?
      token = request.env['HTTP_AUTHORIZATION'] || params['access_token'] || ""
      token.sub!(/^Bearer /,'')
      if token.empty?
        raise Auth::NoTokenError.new
      end
      scope = params.key?('action') ? params['action'] : 'post'
      Auth.verify_token_and_scope(token, scope)
    end

    def verify_create
      if params.key?('h') && Post.valid_types.include?("h-#{params[:h]}")
        return
      elsif params.key?('type') && Post.valid_types.include?(params[:type][0])
        return
      else
        raise Micropub::InvalidRequestError.new(
          "You must specify a Microformats 'h-' type to create a new post. " +
          "Valid post types are: #{Post.valid_types.join(' ')}."
        )
      end
    end

    def verify_action
      valid_actions = %w( create update delete undelete )
      unless valid_actions.include?(params[:action])
        raise Micropub::InvalidRequestError.new(
          "The specified action ('#{params[:action]}') is not supported. " +
          "Valid actions are: #{valid_actions.join(' ')}."
        )
      end
    end

    def verify_url
      unless params.key?('url') && !params[:url].empty? &&
          Store.exists_url?(params[:url])
        raise Micropub::InvalidRequestError.new(
          "The specified URL ('#{params[:url]}') could not be found."
        )
      end
    end

    def render_syndication_targets
      content_type :json
      { "syndicate-to" => settings.syndication_targets }.to_json
    end

    def render_config
      content_type :json
      {
        "media-endpoint" => "#{ENV['SITE_URL']}micropub",
        "syndicate-to" => settings.syndication_targets
      }.to_json
    end

    def render_source
      content_type :json
      relative_url = Utils.relative_url(params[:url])
      not_found unless post = Store.get("#{relative_url}.json")
      data = if params.key?('properties')
        properties = {}
        Array(params[:properties]).each do |property|
          if post.properties.key?(property)
            properties[property] = post.properties[property]
          end
        end
        { 'type' => [post.h_type], 'properties' => properties }
      else
        post.data
      end
      data.to_json
    end

    # don't cache posts for the first 10 mins (to allow editing)
    def cache_unless_new
      published = Time.parse(@post.properties['published'][0])
      if Time.now - published > 600
        cache_control :s_maxage => 300, :max_age => 600
      else
        cache_control :max_age => 0
      end
    end
  end
end
