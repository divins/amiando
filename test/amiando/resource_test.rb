require 'test_helper'

describe Amiando::Resource do
  class Wadus < Amiando::Resource
    map :creation, :creationTime, :type => :time

    def self.create(params = {})
      object = new
      post object, 'somewhere', :params => params, :populate_method => :populate_create
      object
    end

    def self.find(id)
      object = new
      get object, 'somewhere', :populate_method => :populate_test
      object
    end

    private

    def populate_test(body)
      extract_attributes_from(body, 'wadus')
    end
  end

  it 'raises error when amiando is down' do
    stub_request(:post, /somewhere/).to_return(:status => 503)
    lambda {
      Wadus.create
      Amiando.run
    }.must_raise Amiando::Error::ServiceDown
  end

  it 'raises error when the request times out' do
    stub_request(:post, /somewhere/).to_timeout
    lambda {
      Wadus.create
      Amiando.run
    }.must_raise Amiando::Error::Timeout
  end

  it 'raises error when the request returns code 0' do
    stub_request(:post, /somewhere/).to_return(:status => 0)

    lambda {
      Wadus.create
      Amiando.run
    }.must_raise Amiando::Error
  end


  it 'raises an error if populate method is not implemented' do
    lambda {
      Wadus.new.populate(nil)
    }.must_raise Amiando::Error::NotImplemented
  end

  it "raises an error when the call doesnt supply the required api key" do
    stub_request(:post, /somewhere/).to_return(
      :status => 400,
      :body => "{\"errors\":[\"com.amiando.api.rest.MissingParam.apikey\"],\"success\":false}"
    )

    lambda {
      Wadus.create
      Amiando.run
    }.must_raise Amiando::Error::MissingApiKey
  end

  it 'maps attributes appropriately' do
    expected = {:firstName => '1', :lastName => '2', :wadus => '3'}
    Wadus.map_params(:first_name => '1', :last_name => '2', :wadus => '3').must_equal expected
  end

  it 'reverse maps attributes appropriately' do
    expected = {:first_name => '1', :last_name => '2', :wadus => '3'}
    Wadus.reverse_map_params(:firstName => '1', :lastName => '2', :wadus => '3').must_equal expected
    Wadus.reverse_map_params('firstName' => '1', 'lastName' => '2', 'wadus' => '3').must_equal expected
  end

  it 'maps attributes with typecasting' do
    time      = Time.at(0).utc
    expected  = { :creationTime => '1970-01-01T00:00:00Z' }
    Wadus.map_params(:creation => time).must_equal expected
  end

  it 'automatically typecasts if the object is a Time' do
    time      = Time.at(0).utc
    expected  = { :firstName => '1970-01-01T00:00:00Z' }
    Wadus.map_params(:first_name => time).must_equal expected
  end

  it 'reverse maps attributes with typecasting' do
    time      = Time.at(0).utc
    expected  = { :creation => time }
    Wadus.reverse_map_params(:creationTime => '1970-01-01T00:00:00Z').must_equal expected
  end

  it 'automatically maps attributes for a request' do
    result = Wadus.create :first_name => 'George'
    result.request.params.must_equal(:firstName => 'George')
  end

  it 'automatically reverse maps attributes on responses' do
    stub_request(:any, /somewhere/).to_return(:status => 200, :body => '{"wadus":{"firstName":"George"}}')
    result = Wadus.find(1)
    Amiando.run

    result.attributes.must_equal(:first_name => "George")
  end

  describe 'respond_to behavior' do
    def setup
      stub_request(:any, /somewhere/).to_return(:status => 200, :body => '{"wadus":{"firstName":"George"}}')
      @result = Wadus.sync_find(1)
    end

    it 'will return true for present attributes' do
      @result.respond_to?(:first_name).must_equal true
    end

    it 'will return true for defined methods' do
      @result.respond_to?(:populate).must_equal true
    end

    it 'will return false for not defined attributes' do
      @result.respond_to?(:i_dont_exists).must_equal false
    end
  end

  describe 'synchronous calls' do
    it 'accepts synchronous calls' do
      stub_request(:post, /somewhere/).to_return(:status => 200, :body => '{"success":true}')
      Wadus.sync_create.success.must_equal true
    end
  end

  describe 'autorun' do
    before do
      Amiando.autorun = true
      stub_request(:post, /somewhere/).to_return(:status => 200, :body => '{"success":true, "id": 1}')
    end

    after do
      Amiando.autorun = nil
    end

    let(:wadus) { Wadus.create }

    it 'should return the result when calling autorun' do
      wadus.id.must_equal 1
    end

    it 'should return the success' do
      wadus.success.must_equal true
    end

    it 'should return no errors' do
      wadus.errors.must_be_nil
    end

    it 'should return the request' do
      wadus.request.wont_be_nil
    end

    it 'should return the response' do
      wadus.response.wont_be_nil
    end
  end
end
