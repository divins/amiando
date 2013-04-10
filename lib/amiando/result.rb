module Amiando

  ##
  # This object is intended to be used when an api will return value that is
  # not a resource object (a User, an Event, etc), but due to the delayed
  # nature of doing requests in parallel, can't be initialized from the beginning.
  #
  # After the object is populated, you can ask the result with the result
  # method.
  class Result
    include Amiando::Autorun

    attr_accessor :request, :response, :errors
    attr_reader :result, :success, :after_populate_callbacks

    autorun :request, :response, :result, :errors, :success

    def initialize(&block)
      @populator = block
      @after_populate_callbacks = []
      @populator ||= Proc.new do |response_body, result|
        result.errors = response_body['errors']
        response_body['success']
      end
    end

    def populate(response_body)
      if @populator.arity == 1
        @result = @populator.call(response_body)
      elsif @populator.arity == 2
        @result = @populator.call(response_body, self)
      end
      @success = response_body['success']
      run_after_populate_callbacks

      @success
    end

    def on_populate(&block)
      after_populate_callbacks << block
    end

    def run_after_populate_callbacks
      after_populate_callbacks.each do |callback|
        callback.call(self)
      end
    end
  end
end
