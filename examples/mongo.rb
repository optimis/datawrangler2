module DataWrangler2
  module Config
    def self.mongo
      case ENV['RACK_ENV']
        when 'test'
          {
            :connection => ["localhost"],
            :database   => "reporting_v2_test"
          }
        when 'development'
          {
            :connection => ["localhost"],
            :database   => "reporting_v2_development"
          }
      end
    end
  end
end
