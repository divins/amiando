require 'pry'

module Amiando
  class Payment < Resource

    ##
    # Find all Payments of an event
    #
    # @param event_id
    #
    # @return [Result] with the list of payments for that event.
    def self.find_all_by_event_id(event_id)
      object = Result.new do |response_body, result|
        if response_body['success']
          response_body['payments'].map do |payment|
            find(payment)
          end
        else
          result.errors = response_body['errors']
          false
        end
      end

      get object, "api/event/#{event_id}/payments"

      object
    end

    ##
    # Find a Payment
    #
    # @param payment_id
    #
    # @return [Payment] the payment with that id
    def self.find(payment_id)
      object = new
      get object, "api/payment/#{payment_id}"

      object
    end

    def self.find_ticket_ids(payment_id)
      object = Result.new do |response_body, result|
        if response_body['success']
          response_body['tickets'].map do |ticket|
            ticket
          end
        else
          result.errors = response_body['errors']
          false
        end
      end

      get object, "api/payment/#{payment_id}/tickets"

      object
    end

    protected

    def populate(response_body)
      extract_attributes_from(response_body, 'payment')
    end
  end
end
