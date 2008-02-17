class Relevance::Tarantula::Result
  HASHABLE_ATTRS = [:success, :method, :url, :response, :referrer, :data, :description]
  attr_accessor *HASHABLE_ATTRS
  include Relevance::Tarantula

  def initialize(hash)
    hash.each do |k,v|
      raise ArgumentError, k unless HASHABLE_ATTRS.member?(k)
      self.instance_variable_set("@#{k}", v)
    end
  end
  def short_description
    [method,url].join(" ")
  end
  def sequence_number
    @sequence_number ||= (self.class.next_number += 1)
  end
  def file_name
    "#{sequence_number}.html"
  end
  def code
    response && response.code
  end
  def body
    response && response.body
  end
  ALLOW_NNN_FOR = /^allow_(\d\d\d)_for$/
  class <<self
    attr_accessor :next_number
    def handle(result)
      retval = result.dup
      retval.success = successful?(result.response) || can_skip_error?(result)
      retval.description = "Bad HTTP Response" unless retval.success
      retval
    end
    def success_codes 
      %w{200 201 302 401}
    end
    
    # allow_errors_for is a hash 
    #  k=error code,
    #  v=array of matchers for urls that can skip said error
    attr_accessor :allow_errors_for
    def can_skip_error?(result)
      coll = allow_errors_for[result.code]
      return false unless coll
      coll.any? {|item| item === result.url}
    end
    def successful?(response)
      success_codes.member?(response.code)
    end
    def method_missing(meth, *args)
      super unless ALLOW_NNN_FOR =~ meth.to_s
      error = $1.to_i
      (allow_errors_for[error] ||= []).push(*args)
    end
  end
  self.allow_errors_for = {}
  self.next_number = 0
  
  
end