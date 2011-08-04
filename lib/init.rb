ENV['RACK_ENV'] ||= 'development'

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default, ENV['RACK_ENV'])

require 'active_record'

#require all of the config files
Dir['config/*.rb'].each { |file_name|  require file_name }

Dir['lib/models/*.rb'].each {|name| require name }

Dir['lib/observers/*.rb'].each {|name| require name }


ActiveRecord::Base.establish_connection(DataWrangler2::Config.database)

