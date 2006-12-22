class ActiveRecord::Extensions::FullTextSearching::MySQLFullTextExtension
  extend Forwardable
  
  class << self
    extend Forwardable
    
    def register( fulltext_key, options )
      @fulltext_registry ||= ActiveRecord::Extensions::Registry.new
      @fulltext_registry.register( fulltext_key, options )
    end
    
    def registry
      @fulltext_registry
    end
    
    def_delegator :@fulltext_registry, :registers?, :registers?
  end
  
  RGX = /^match_(.+)/
  
  def process( key, val, caller )
    match_data = key.to_s.match( RGX )
    return nil unless match_data
    fulltext_identifier = match_data.captures[0].to_sym
    if self.class.registers?( fulltext_identifier )
      fields = self.class.registry.options( fulltext_identifier )[:fields]
      str = "MATCH ( #{fields.join( ',' )} ) AGAINST (#{caller.connection.quote(val)})"
      return ActiveRecord::Extensions::Result.new( str, nil )
    end
    nil
  end
  
  def_delegator 'ActiveRecord::Extensions::FullTextSupport::MySQLFullTextExtension', :register    
end
ActiveRecord::Extensions.register ActiveRecord::Extensions::FullTextSearching::MySQLFullTextExtension.new, :adapters=>[:mysql]


class ActiveRecord::ConnectionAdapters::MysqlAdapter
  include ActiveRecord::Extensions::FullTextSearching::FullTextSupport

  def register_fulltext_extension( fulltext_key, options )
    ActiveRecord::Extensions::FullTextSearching::MySQLFullTextExtension.register( fulltext_key, options )
  end
end
