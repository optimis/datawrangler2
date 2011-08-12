require 'lib/init'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |file| require File.expand_path(file) }

include TransformerHelper 

RSpec.configure do |config|
  config.after :each do
    DataWrangler2.mongo_db.collections.select {|c| c.name !~ /system/}.each(&:drop)
  end
end
