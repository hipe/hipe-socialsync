require 'fakeweb'
require 'json'
require 'md5'
module Hipe::SocialSync

  class TransportRuntimeError < RuntimeError; end

  class RecordingTransport

    class PostOperation < Struct.new(:url, :headers, :parameters)
      def to_hash; { :url => url, :headers => headers, :parameters => parameters } end
    end


    # got tired of searching for string literals when refactoring
    EntriesKey = 'entries'
    RequestFilenameKey = 'request_file'
    ResponseFilenameKey = 'response_file'
    RequestFilesDir = 'request-files'
    ResponseFilesDir = 'response-files'
    UrlKey = 'url'

    ResponseFilename = 'response_filename'

    # this is a base class for transports that can optionally record their requests and responses
    # for use in something like fakeweb
    # it's also a general base class.  if we really really needed to we could break it up more but probably won't need to

    extend Hipe::Loquacious::AttrAccessor
    include ViewCommon
    Response = Hipe::Cli::Out.new
    Response.klass = Hipe::Io::GoldenHammer

    class << self
      extend Hipe::Loquacious::AttrAccessor
      symbol_accessor :transport_name
      def register_transport_as name
        self.transport_name = name
        Transports.register_factory transport_name, self
      end
    end

    boolean_accessors :read_get_recordings, :write_recordings, :clobber_recordings
    string_accessor :base_recordings_dir

    def initialize
      @write_recordings = false
      @read_get_recordings = false
      @clobber_recordings = false
    end

    def base_recordings_dir
      @base_recordings_dir ||= File.join(DIR,'spec','recordings')
    end

    def my_recordings_dir
      @my_recordings_dir ||= File.join(base_recordings_dir,self.class.transport_name.to_s)
    end

    def my_manifest_path
      File.join(my_recordings_dir,'manifest.json')
    end

    def read_get_recordings= bool
      raise ArgumentError.new("need boolean had #{bool.inspect}") unless [TrueClass,FalseClass].detect{|x| bool.kind_of? x}
      return if @use_recordings == bool
      @use_recordings = bool
      if (bool)
        FakeWeb.allow_net_connect = false # raises FakeWeb::NetConnectNotAllowedError
        mani = manifest
        base = File.join(my_recordings_dir,ResponseFilesDir)
        mani[1][EntriesKey].each_with_index do |elem,idx|
          next unless elem["method"] == "get"
          response_file_path = File.join(base, elem[ResponseFilenameKey])
          response = File.read response_file_path
          FakeWeb.register_uri(elem["method"].to_sym, elem[UrlKey], :response => response)
        end
      else
        raise "turning read_get_recordings off is not yet implemented"
      end
    end

    def write_recordings= bool
      raise ArgumentError.new("need boolean had #{bool.inspect}") unless [TrueClass,FalseClass].detect{|x| bool.kind_of? x}
      return if @write_recordings == bool
      @write_recordings = bool
      if bool
        dir = my_recordings_dir
        unless File.exist? dir
          init_recordings_dir
        end
      end
    end

    def init_recordings_dir
      # raise "check that the folder doesn't already exist before you call this." if File.exist? my_recordings_dir
      unless File.exist? base_recordings_dir
        raise "something is really wrong. doesn't exist: #{relativize_path(base_recordings_dir)}"
      end
      FileUtils.mkdir_p File.join(my_recordings_dir, RequestFilesDir)
      FileUtils.mkdir_p File.join(my_recordings_dir, ResponseFilesDir)
      @manifest = [
       {"comment" => "This data is part of Hipe::SocialSync::RecordingTransport api"},
       { EntriesKey => []}
      ]
      save_manifest!
    end

    # Check that the appropriate folders are writable
    # @return [Boolean] true if everything's ok, else raise RuntimeException
    def assert_environment
      init_recordings_dir # unless File.exist? my_recordings_dir subfolders
      unless File.writable? my_recordings_dir
        raise RuntimeError.new(%{File is not writable: #{relativize_path(my_recordings_dir)}})
      end
      true
    end

    def json_parser_for source
      JSON::Ext::Parser.new(source)
    end

    def json_parse source
      json_parser_for(source).parse
    end

    def json_prettify_string str
      JSON::pretty_generate(json_parse(str))
    end

    def manifest
      @manifest ||= json_parse File.read(my_manifest_path)
    end

    def save_manifest!
      json = json_prettify_string @manifest.to_json
      File.open(my_manifest_path,'w'){|fh| fh.write json}
    end

    # @param [mixed] url_or_post_operation, url if :get, [PostOperation] if :post
    # @return [GoldenHammer] response object
    def record_response method, url_or_post_operation, response
      case method
        when :get  then record_get_response url_or_post_operation, response
        when :post then record_post_response url_or_post_operation, response
        else raise "Must be get or post.  had #{method.inspect}"
      end
    end

    def record_get_response url, response
      my_response = Response.new
      mani = manifest
      idx = index_of_entry_for_request_url url
      if ! @clobber_recordings and idx
        raise "Response already exists for #{url.inspect}.  Do you want to turn @clobber_recordings on?"
      end
      if idx
        verb = 'Rewrote'
      else
        verb = 'Wrote'
        md5 = MD5.new(url).to_s
        mani[1][EntriesKey] << { UrlKey => url, ResponseFilenameKey => md5 }
        idx = mani[1][ResponseFilenameKey].size - 1
      end
      mani[1][EntriesKey][idx]["method"] = 'get'
      filename = mani[1][EntriesKey][idx][ResponseFilenameKey]
      full_path = File.join(my_recordings_dir,ResponseFilesDir,filename)
      File.open(full_path,'w+'){|fh| fh.write response}
      save_manifest!
      my_response.puts "#{verb} response for GET #{url} to #{relativize_path(full_path)}"
      my_response
    end

    def record_post_response post_operation, response
      my_response = Response.new
      mani = manifest
      norm = normalize_post_operation post_operation
      idx = index_of_entry_for_request_md5 norm[:md5]
      if ! @clobber_recordings and idx
        raise "Response already exists for this post operation.  Do you want to turn @clobber_recordings on?"
      end
      if idx
        verb = 'Rewrote'
      else
        verb = 'Wrote'
        mani[1][EntriesKey] << { UrlKey => post_operation.url, RequestFilenameKey => norm[:md5] }
        idx = mani[1][EntriesKey].size - 1
      end
      mani[1][EntriesKey][idx]['method'] = 'post'
      request_filename = mani[1][EntriesKey][idx][RequestFilenameKey]
      response_filename = request_filename
      request_path  = File.join(my_recordings_dir,RequestFilesDir, request_filename)
      response_path = File.join(my_recordings_dir,ResponseFilesDir,response_filename )
      File.open(request_path,'w+'){|fh| fh.write norm[:json]}
      File.open(response_path,'w+'){|fh| fh.write response}
      save_manifest!
      silly = relativize_path File.join(my_recordings_dir,%{(#{RequestFilesDir}|#{ResponseFilesDir})},norm[:md5])
      my_response.puts "#{verb} request & response for PUT #{post_operation.url} to #{silly}"
      my_response
    end

    def index_of_entry_for_request_url url
      manifest[1][EntriesKey].index{|x| x[UrlKey] == url }
    end

    def index_of_entry_for_request_md5 md5
      manifest[1][EntriesKey].index{|x| x[RequestFilenameKey] == md5 }
    end

    def normalize_post_operation post_operation
      res = {}
      as_array = hash_to_array_recursive post_operation.to_hash
      res[:json] = JSON.pretty_generate as_array
      res[:md5]  = MD5.new(res[:json]).to_s
      res
    end

    def hash_to_array_recursive hash
      sorted_keys_as_string = hash.keys.map{|x| x.to_s}.sort
      sorted_keys = []
      hash.keys.each do |key|
        use_idx = sorted_keys_as_string.index(key.to_s)
        sorted_keys[use_idx] = key
      end
      result = []
      sorted_keys.each do |key|
        result << [key.to_s, hash[key].kind_of?(Hash) ? hash_to_array_recursive(hash[key]) : hash[key] ]
      end
      result
    end

    def has_recorded_response? url
      !! index_of_recorded_response(url)
    end
  end
end
