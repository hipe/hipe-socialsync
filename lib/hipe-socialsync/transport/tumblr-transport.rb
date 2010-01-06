require 'restclient'
require 'hipe-core/loquacious/all'
require 'hipe-socialsync/transport/recording-transport'
require 'hipe-core/struct/table'
require 'hipe-core/struct/open-struct-extended'
require 'json'

module Hipe::SocialSync
  class TumblrTransport < RecordingTransport
    register_transport_as :tumblr



    # reveal a certain subset of our "interface" (our methods) to whoever asks
    include Hipe::Interactive::InterfaceReflector
    interface.define do
      interactive :read, :description => "sends a read request to tumblr"
      interactive :write
      interactive :response, :description => "view the last response"
      interactive :json_prettify_response, :method => :response_as_pretty_json
      interactive :save_this
      interactive :load_last_post, :description => "load last recorded response"
      interactive :view, :description => "which mode to view the table in"
    end



    # use Hipe::Loquacious::AttrAccessor to create a bunch of setter getters
    # they have been grouped into "view modes:" read and write.  If we were to do this again we might
    # make separate request classes for each of the above operations.

    extend Hipe::Loquacious::AttrAccessor

    # read parameters (parameters related to reading tumblr blogs)
    string_accessor  :username
    integer_accessor :read_offset , :min => 0
    integer_accessor :num_posts   , :min => 0
    integer_accessor :post_id     , :min => 0
    enum_accessor    :filter      , [:text,:none]
    string_accessor  :tag         , :nil => true
    string_accessor  :search      , :nil => true
    boolean_accessor :ask_for_json
    boolean_accessor :prettify_json_when_recording
    @@read_parameters = [
      :username         ,
      :read_offset      ,
      :num_posts        ,
      :post_id          ,
      :filter           ,
      :tag              ,
      :search           ,
      :ask_for_json     ,
      :prettify_json_when_recording,
      :read_get_recordings, :write_recordings, :clobber_recordings,
      :response
    ]


    # write parameters (parameters related to writing tumblr blogs)
    string_accessor  :generator_name
    string_accessor  :name_credential
    string_accessor  :password
    string_accessor  :item_title
    string_accessor  :item_body
    string_accessor  :item_date
    string_accessor  :item_tags
    @@write_parameters = [
      :generator_name  ,
      :name_credential ,
      :password        ,
      :item_title      ,
      :item_body       ,
      :item_date       ,
      :item_tags       ,
      :post_type       ,
      :write_recordings, :clobber_recordings,
      :response
    ]


    # read and write parameters
    enum_accessor    :post_type, [:all, :text, :quote, :photo, :link, :chat, :video, :audio]


    # properties related to using this transport
    enum_accessor :view, [:read, :write, :all], :use => :to_sym
    string_accessor :response



    def initialize
      super
      @ask_for_json = true
      @filter = :none
      @generator_name = 'ADE - slow burn'
      @item_body = nil
      @item_title = nil
      @item_title = nil
      @json_read_url = 'http://%s.tumblr.com/api/read/json'
      @name_credential = nil
      @num_posts = 1
      @password = nil
      @post_id = nil
      @post_type = :all
      @prettify_json_when_recording = true
      @read_offset = 0
      @read_url =      'http://%s.tumblr.com/api/read'
      @response = 'blah'
      @search = nil
      @table = nil
      @tag = nil
      @username = nil
#      self.view = :all
      self.view = :write
      @write_url =     'http://www.tumblr.com/api/write'
    end

    class << self
      alias_method :attrs, :defined_accessors # just for table fields below
    end

    include Hipe::SocialSync::ViewCommon # truncate

    def to_table
      @table ||= begin
        transport = self
        Hipe::Table.make do
          field(:object_id, :visible => false){|x| x.object_id }
          field(:transport_name)    { |x|     x.class.transport_name }
          field(:generator_name)    { |x|     x.generator_name }
          field(:name_credential)   { |x|     x.name_credential.inspect }
          field(:username)          { |x|     x.username.inspect }
          field(:password)          { |x|     x.password.nil? ? 'not set' : '********'.inspect }
          field(:read_offset)       { |x|     x.read_offset.inspect }
          field(:num_posts)         { |x|     x.num_posts.inspect}
          field(:post_type){|x| x.post_type.inspect << " (can be " << en{ list(x.class.attrs[:post_type].enum)}.either << ')'}
          field(:post_id)           { |x| x.post_id.inspect}
          field(:filter){|x| x.filter.inspect << " (can be " << en{list(x.class.attrs[:filter].enum)}.either << ')' }
          field(:tag){|x| x.tag.inspect << "  (search for this tag)"}
          field(:search){|x| x.search.inspect << " (search for this string)"}
          field(:ask_for_json)      { |x|     x.ask_for_json.inspect }
          field(:prettify_json_when_recording){|x| x.prettify_json_when_recording.inspect }
          field(:item_title      )  { |x|     x.item_title.inspect }
          field(:item_body       )  { |x|     x.item_body ? transport.truncate(x.item_body,20) : x.item_body.inspect }
          field(:item_date       )  { |x|     x.item_date.inspect  }
          field(:item_tags       )  { |x|     x.item_tags.inspect  }
          field(:response        )  { |x|     x.response ? transport.truncate(x.response,20) : x.response.inspect }

          field(:read_get_recordings){|x|     x.read_get_recordings.inspect }
          field(:write_recordings)  { |x|     x.write_recordings.inspect}
          field(:clobber_recordings){ |x|     x.clobber_recordings.inspect}

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

    alias_method :orig_view=, :view=

    def view= mode
      if mode == @view
        return Response.new "view mode is already #{mode}"
      end
      old_mode = @view
      self.orig_view=(mode) # just validate value against enum and set @view
      to_table              # make @table
      case @view
        when :all:   @table.show_all
        when :read:  @table.show_only(*@@read_parameters)
        when :write: @table.show_only(*@@write_parameters)
        else raise TransportRuntimeError.new("invalid mode: #{mode.inspect}")
      end
      Response.new "Changed view mode from #{old_mode.inspect} to #{@view.inspect}"
    end

    # @return [GoldenHammer] response object, possibly invalid with exceptions
    def read
      result = Response.new
      @resource = @response = nil
      exception = nil
      begin
        raise TransportRuntimeError.new("you must indicate a username to read") unless @username
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

    def save_this
      msg = Hipe::Loquacious::PrimitiveEnumSet.new(:read, :write).issues_with(@view).map{|x| x.message}.join
      raise TransportRuntimeError.new(%{#{msg} with @view}) if msg.length > 0
      case @view
        when :read  then record_this_response
        when :write then record_this_post_response
      end
    end

    def record_this_response
      raise TransportRuntimeError.new("where is @repsonse?") unless @response
      response = @response
      if (@ask_for_json && @prettify_json_when_recording)
        response = json_prettify_string response
      end
      record_response @method, @resource.url, response
    end

    def record_this_post_response
      raise TransportRuntimeError.new("where is @response?") unless @response
      @post_operation ||= prepare_post_operation # hack so we can save unsent posts
      record_response :post, @post_operation, @response
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

    def prepare_post_operation
      o = PostOperation.new
      o.url = @write_url
      o.parameters = prepare_write_post_parameters
      o.headers = {}
      o
    end

    def load_last_post
      mani = manifest
      i = mani[1][EntriesKey].size
      while ((i-=1) >= 0) do
        next unless mani[1][EntriesKey][i]['method'] == 'post'
        load_entry mani[1][EntriesKey][i]
        return Response.new("loaded last post")
      end
      ret = Response.new
      ret.errors << "There are no recorded POST operations"
      ret
    end

    def load_entry entry
      raise TransportRuntimeError.new("load entry not yet implemented for #{entry['method'].inspect}") unless
        entry['method'] == 'post'
      request_path  =  request_path_for_md5(entry[RequestFilenameKey])
      response_path =  response_path_for_md5(entry[RequestFilenameKey])
      response_str = File.read response_path
      request_json = File.read request_path
      request_structure_as_array = JSON::parse(request_json)
      request_struct = array_to_hash_recursive( request_structure_as_array, 2 )
      params = request_struct['parameters']

      # ignore 'url' and 'headers', just set each parameter
      @item_title       = params['title']
      @item_body        = params['body']
      @name_credential  = params['email']
      @password         = params['password']
      @type             = params['type'] == nil ? :all : params['type'].to_sym
      @generator_name   = params['generator']
      @item_date        = params['date']
      @item_tags        = params['tags']
    end

    def prepare_write_post_parameters
      o = Hipe::OpenStructExtended.new
      o.title       =   @item_title
      o.body        =   @item_body
      o.email       =   @name_credential
      o.password    =   @password
      o.type        =   @post_type == :all ? nil : @post_type
      o.generator   =   @generator_name
      o.date        =   @item_date
      o.private     =   0
      o.tags        =   @item_tags
      o.format      =   'html'  # html | markdown
      o._table
    end

    def push
      result = Response.new
      unless @object_to_push
        result.errors << "must have object to push"
        return result
      end
      @post_operation = prepare_post_operation
      p = @post_operation
      begin
        @response = RestClient.post p.url, p.parameters, p.headers
      rescue SocketError => e
        result.errors << [%{Got a socket error: "#{e.message}" -- Is your internet on?  }<<
          %{Do you *have* the Internet?},{:exception=>e}]
      rescue RestClient::RequestFailed => e
        result.errors << [%{Failed to push item ##{item.id} to tumblr.  Exception: #{e}} <<
          %{#{e.response.body.inspect}},{:exception=>e}]
      end
      if result.valid?
        result.puts "@response is set."
        if write_recordings?
          sub_result = record_this_post_response
          result.merge! sub_result
        end
      end
      response
    end
  end
end
# resp = @response.dup
# var_thing = resp.slice!(0,22)
# should_match = %r{^var tumblr_api_read = $}
# unless var_thing.match(should_match)
#   raise Exception.new(%{Expecting #{should_match.inspect} had #{var_thing.inspect}})
# end
# @json_struct = JSON.parse(resp)
