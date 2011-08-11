require 'lib/init'

RSpec.configure do |config|
  config.after :each do
    DataWrangler2.mongo_db.collections.select {|c| c.name !~ /system/}.each(&:drop)
  end
end
