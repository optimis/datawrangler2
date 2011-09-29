require 'lib/init'
# require 'rspec/core/rake_task'

# desc "Run all examples"
# RSpec::Core::RakeTask.new(:spec)


desc "read new binlog statements and queue"
task :queue_statements do
  b = Bunny.new("amqp://#{DataWrangler2::Config.rabbit}", :logging => true)

  b.start

  q = b.queue("etl.transform", :durable => true)
  e = b.exchange("")


  e.publish(BSON.serialize({"binlog"=>{"location"=>"76141", "file_name"=>"/usr/local/Cellar/mysql/5.1.53/bin_log.000039", "statement"=>"UPDATE `users` SET `updated_at` = '2011-08-15 03:27:16', `perishable_token` = 'zZ-700delUVEwZhJSGWp', `last_name` = 'Test', `timezone` = 'Pacific Time (US & Canada)' WHERE `id` = 229"}, "sql"=>{"data"=>{}, "action"=>"INSERT", "table"=>"users", "query"=>{"id"=>"*"}}, "observer"=>{"class"=>"User", "sql"=>"SELECT `users`.id FROM `users`", "action"=>"INSERT"}}), :key => 'etl.transform')

  # r = BinlogETL::BinlogReader::Reader.new

  # messages = r.messages
  # messages.each {|m| e.publish(m, :key => 'etl.statements') }
  b.stop

end

namespace :deploy do
  task :post_setup => [:after_deploy] do
  end
  task :post_deploy => [:after_deploy] do
  end
  
  task :after_deploy do
    puts `RACK_ENV=#{ENV['RACK_ENV']} && ./scripts/etl_process stop`
    puts `RACK_ENV=#{ENV['RACK_ENV']} && ./scripts/etl_process start`
  end
end
