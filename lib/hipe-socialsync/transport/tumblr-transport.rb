require 'restclient'
require 'hipe-core/loquacious/all'
require 'hipe-socialsync/transport/recording-transport'
require 'hipe-core/struct/table'
require 'hipe-core/struct/open-struct-extended'
require 'json'

module Hipe::SocialSync
  class TumblrTransport < RecordingTransport
    # extend Hipe::Loquacious::AttrAccessor   @todo -- deal w/ this vis-a-vis inheiritance
    include Hipe::Interactive::InterfaceReflector

    register_transport_as :tumblr

    # this reveals a certain part of our "interface" to whoever asks
    interface.define do
      interactive :read, :description => "sends a read request to tumblr"
      interactive :write
      interactive :response, :description => "view the last response"
      interactive :response_as_pretty_json
      interactive :record_this_response
    end

    class << self
      alias_method :attrs, :defined_accessors
    end

    string_accessor  :generator_name
    string_accessor  :name_credential
    string_accessor  :username
    string_accessor  :password
    integer_accessor :read_offset, :min => 0
    integer_accessor :num_posts, :min => 0
    enum_accessor    :post_type, [:all, :text, :quote, :photo, :link, :chat, :video, :audio]
    integer_accessor :post_id, :min => 0
    enum_accessor    :filter, [:text,:none]
    string_accessor  :tag, :nil => true
    string_accessor  :search, :nil => true
    boolean_accessor :ask_for_json
    boolean_accessor :prettify_json_when_recording
    attr_reader :response

    def initialize
      super
      @generator_name = 'ADE - slow burn'
      @write_url =     'http://www.tumblr.com/api/write'
      @read_url =      'http://%s.tumblr.com/api/read'
      @json_read_url = 'http://%s.tumblr.com/api/read/json'
      @username = nil
      @name_credential = nil
      @password = nil
      @read_offset = 0
      @num_posts = 1
      @post_type = :all
      @post_id = nil
      @filter = :none
      @tag = nil
      @search = nil
      @ask_for_json = true
      @prettify_json_when_recording = true
      @table = nil
    end

    def to_table
      @table ||= begin
        transport = self
        Hipe::Table.make do
          field(:object_id, :visible => false){|x| x.object_id }
          field(:transport_name){|x| x.class.transport_name }
          field(:name_credential){|x| x.name_credential.inspect }
          field(:username){|x| x.username.inspect }
          field(:password){|x| x.password.nil? ? 'not set' : '********'.inspect }
          field(:read_offset){|x| x.read_offset.inspect }
          field(:num_posts){|x| x.num_posts.inspect}
          field(:post_type){|x| x.post_type.inspect << " (can be " << en{ list(x.class.attrs[:post_type].enum)}.either << ')'}
          field(:post_id){|x| x.post_id.inspect}
          field(:filter){|x| x.filter.inspect << " (can be " << en{list(x.class.attrs[:filter].enum)}.either << ')' }
          field(:tag){|x| x.tag.inspect << "  (search for this tag)"}
          field(:search){|x| x.search.inspect << " (search for this string)"}
          field(:ask_for_json){|x| x.ask_for_json.inspect }
          field(:prettify_json_when_recording){|x| x.prettify_json_when_recording.inspect }
          field(:read_recordings){|x| x.read_recordings.inspect }
          field(:write_recordings){|x| x.write_recordings.inspect}
          field(:clobber_recordings){|x| x.clobber_recordings.inspect}
          self.axis = :horizontal
          self.list = [transport]
          self.labelize = lambda{|x| x.to_s} # don't humanize the labels
        end
      end
    end

    # for pretty output from irb
    def inspect
      to_table.render :ascii
    end

    # @return [GoldenHammer] response object, possibly invalid with exceptions
    def read
      result = Response.new
      @resource = @response = nil
      exception = nil
      begin
        raise RuntimeError.new("you must indicate a username to read") unless @username
        @resource = RestClient::Resource.new read_url
        @response = @resource.get
        @method = :get
        result.puts "@response is set."
        if write_recordings?
          sub_result = record_this_response
          result.merge! sub_result
        end
      rescue RestClient::ResourceNotFound => e
        msg = "Resource not Found: #{@resource.to_s} (#{e.message.inspect})"
        exception = RestClient::ResourceNotFound.new(msg)
      rescue JSON::ParserError => e
        exception = e
      rescue Exception => e
        exception = e
      end
      if (exception)
        result.errors << exception
      end
      result
    end

    def record_this_response
      raise RuntimeError.new("where is @repsonse?") unless @response
      response = @response
      if (@ask_for_json && @prettify_json_when_recording)
        response = json_prettify_string response
      end
      record_response @method, @resource.url, response
    end

    def response_as_pretty_json
      json_prettify_string @response
    end

    def read_url
      base_url = if @ask_for_json
        @json_read_url % @username
      else
        @read_url % @username
      end
      params = parameters_as_string(prepare_read_get_parameters)
      %{#{base_url}?#{params}}
    end

    # make sure your keys are strings!
    def parameters_as_string(hash)
      hash.keys.sort.map{|key| %{#{key}=#{hash[key]}}} * '&'
    end

    def prepare_read_get_parameters
      o = Hipe::OpenStructExtended.new
      o.start      = @read_offset
      o.num        = @num_posts
      o.type       = @post_type
      o.id         = @post_id
      o.filter     = @type == :all ? nil : @type
      o.tagged     = @tag
      o.search     = @search
      o.debug      = '1' # for json read
      hash = {}
      o._table.each do |k,v|
        next if v.nil?
        hash[k.to_s] = v.to_s
      end
      hash
    end

    def prepare_write_post_parameters(item)
      o = Hipe::OpenStructExtended.new
      o.title       =   item.title
      o.body        =   item.content
      o.email       =   @name_credential
      o.password    =   @password
      o.type        =   @type == :all ? nil : @type
      o.generator   =   @generator_name
      o.date        =   item.published_at
      o.private     =   0
      o.tags        =   item.keywords
      o.format      =   'html'  # html | markdown
      o._table
    end

    # def push_item out, item, account, password, num_pushed, opts
    #   post_data = post_data_from_item item, account, password
    #   out.puts %{attempting to post article from #{@post_date_str} ...}
    #   begin
    #     resp = RestClient.post(Url, post_data)
    #     out.puts %{(tublr id: "#{resp}")}
    #     num_pushed += 1
    #     true
    #   rescue SocketError => e
    #     out.errors << [%{Got a socket error: "#{e.message}" -- Is your internet on?  }+
    #       %{Do you *have* the Internet?},{:exception=>e}]
    #     false
    #   rescue RestClient::RequestFailed => e
    #     out.errors << [%{Failed to push item ##{item.id} to tumblr.  Exception: #{e}} <<
    #       %{#{e.response.body.inspect}},{:exception => e}]
    #     false
    #   end
    # end
    #
    # resp = @response.dup
    # var_thing = resp.slice!(0,22)
    # should_match = %r{^var tumblr_api_read = $}
    # unless var_thing.match(should_match)
    #   raise Exception.new(%{Expecting #{should_match.inspect} had #{var_thing.inspect}})
    # end
    # @json_struct = JSON.parse(resp)


  end
end
