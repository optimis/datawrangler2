module MongoLogger
  module Config
    def self.mongo_connection
      { :host => 'localhost', :database => 'monog-log-dev' }
    end

    def self.collection_name
      'binlog-reader-log'
    end

    def self.collection_size
      536870912 #512MB
    end

    def self.level
      :info
    end
  end
end
