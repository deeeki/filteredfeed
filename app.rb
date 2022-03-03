require 'bundler'
Bundler.require(:default)
require 'sinatra/reloader' if development?
require 'yaml'
require 'open-uri'

feeds_config = YAML.load_file('feeds.yml')

get '/' do
  links = feeds_config.map{|c| %[<li><a href="/#{c[:url]}" >#{c[:url]}</a></li>] }
  erb %[<ul>#{links.join}</ul>]
end

get '/*' do |url|
  config = feeds_config.find{|c| URI.decode_www_form_component(c[:url]) == url.sub(':/', '://') }
  halt unless config

  body = URI.open(config[:url]).read
  feed = RSS::Parser.parse(body)

  if config[:exclude]
    feed.items.reject! do |item|
      config[:exclude].any? do |field, values|
        values.any? {|value| item.public_send(field).include?(value) }
      end
    end
  end

  feed.to_s
end
