require 'restclient'
require 'hipe-core/infrastructure/strict-setter-getter'
require 'hipe-socialsync/transport/recording-transport'
require 'hipe-core/struct/table'
require 'hipe-core/struct/open-struct-extended'
require 'json'

module Hipe::SocialSync
  class TumblrTransport < RecordingTransport
    register_transport_as :tumblr

    extend Hipe::StrictSetterGetter
    string_setter_getter :generator_name
    string_setter_getter :name_credential
    string_setter_getter :username
    string_setter_getter :password
    integer_setter_getter :read_offset, :min => 0
    integer_setter_getter :num_posts, :min => 0
    symbol_setter_getter :post_type, :enum => [:all, :text, :quote, :photo, :link, :chat, :video, :audio]
    integer_setter_getter :post_id, :min => 0
    symbol_setter_getter :filter, :enum => [:text,:none]
    kind_of_setter_getter :tag, String, NilClass
    kind_of_setter_getter :search, String, NilClass
    boolean_setter_getter :as_json
    attr_reader :response, :json_struct

    BaseUrl = 'http://www.tumblr.com/api'   # http://www.tumblr.com/docs/api#api_write

    def initialize
      super
      @generator_name = 'ADE - slow burn'
      @write_url = 'http://www.tumblr.com/api/write'
      @read_url = 'http://%s.tumblr.com/api/read'
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
      @as_json = false
    end

    # We override inspect so we see pretty output from interactive irb
    #
    def inspect
      transport = self
      # %{#{(/^([^ ]*) /.match(super))[1]} @name_credential=#{@name_credential.inspect} @password=} <<
      # %{#{@password.inspect}>}
      Hipe::Table.make do
        field(:object_id){|x| x.object_id }
        field(:transport_name){|x| x.class.transport_name }
        field(:name_credential){|x| x.name_credential.inspect }
        field(:username){|x| x.username.inspect }
        field(:password){|x| x.password.nil? ? 'nil' : '********'.inspect }
        field(:read_offset){|x| x.read_offset.inspect }
        field(:num_posts){|x| x.num_posts.inspect}
        field(:post_type){|x| x.post_type.inspect << " (can be " << en{ list(x.class.post_type_enum)}.either << ')'}
        field(:post_id){|x| x.post_id.inspect}
        field(:filter){|x| x.filter.inspect << " (can be " << en{list(x.class.filter_enum)}.either << ')' }
        field(:tag){|x| x.tag.inspect << "  (search for this tag)"}
        field(:search){|x| x.search.inspect << " (search for this string)"}
        field(:as_json){|x| x.as_json.inspect }

        self.axis = :horizontal
        self.list = [transport]
      end.render(:ascii)
    end

    # @return nil on success and Exception on failure. (or raise it?)
    def read
      @resource = nil
      @get_params = nil
      @read_url = nil
      e = nil
      begin
        raise RuntimeError.new("you must indicate a username to read") unless @username
        url = read_url
        @resource = RestClient::Resource.new(url)
        @json_struct = nil
        @response =  @resource.get
        if (@as_json)
          # resp = @response.dup
          # var_thing = resp.slice!(0,22)
          # should_match = %r{^var tumblr_api_read = $}
          # unless var_thing.match(should_match)
          #   raise Exception.new(%{Expecting #{should_match.inspect} had #{var_thing.inspect}})
          # end
          # @json_struct = JSON.parse(resp)
          @json_struct = JSON.parse(@response)
        end
        debugger
        if record?
          record_tumblr_read_response
        end
        ret = nil
      rescue RestClient::ResourceNotFound => e
        ret = RestClient::ResourceNotFound.new("Resource not Found: #{@resource.to_s} (#{e.message.inspect})")
      rescue JSON::ParserError => e
        ret = e
      rescue Exception => e
        ret = e
      end
      raise e if e
      ret
    end

    def record_tumblr_read_response
      url = @read_url
      response = @response
      record_response url, response
    end

    def read_url
      @read_url ||= begin
        base_url = (@as_json ? @json_read_url : @read_url) % @username
        params = parameters_as_string(prepare_read_get_parameters)
        %{#{base_url}?#{params}}
      end
    end

    # make sure your keys are strings!
    def parameters_as_string(hash)
      hash.keys.sort.map{|key| %{#{key}=#{hash[key]}}} * '&'
    end


    # def write(item)
    #
    # end



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


  end
end
