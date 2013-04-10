require 'pry'

module Amiando
  class Ticket< Resource

    ##
    # Find all Tickets of an event
    #
    # @param event_id
    #
    # @return [Result] with the list of tickets for that event.
    def self.find_all_by_event_id(event_id)
      payments = Payment.find_all_by_event_id(event_id)

      DeferredResult.new(payments) do |result|
        result.result.map do |payment|
          Amiando::Ticket.find_all_by_payment_id(payment.id)
        end
      end
    end

    ##
    # Find all Tickets of a given Payment
    #
    # @param payment_id
    #
    # @return [Result] with the list of tickets for that payment.
    def self.find_all_by_payment_id(payment_id)
      ticket_ids = Payment.find_ticket_ids(payment_id)

      DeferredResult.new(ticket_ids) do |result|
        result.result.map do |ticket_id|
          Amiando::Ticket.find(ticket_id)
        end
      end
    end

    class DeferredResult
      attr_reader :result

      def initialize(parent_result, &block)
        @block = block
        parent_result.on_populate(&populate)
      end

      def populate
        lambda do |result|
          @result = @block.call(result)
        end
      end
    end

    ##
    # Find a Ticket
    #
    # @param ticket_id
    #
    # @return [Ticket] the ticket with that id
    def self.find(ticket_id)
      object = new
      get object, "api/ticket/#{ticket_id}"

      object
    end

    protected

    def populate(response_body)
      extract_attributes_from(response_body, 'ticket')
    end
  end
end
