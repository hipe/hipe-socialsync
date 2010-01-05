require 'fakeweb'
require 'json'
require 'md5'
module Hipe::SocialSync
  class RecordingTransport
    # this is a base class for transports that can optionally record their requests and responses using fakeweb
    # it's also a general base class.  if we really really needed to we could break it up more but probably won't neeed to

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

    boolean_accessor :read_recordings
    boolean_accessor :write_recordings
    boolean_accessor :clobber_recordings
    string_accessors :base_recordings_dir

    def initialize
      @write_recordings = false
      @read_recordings = false
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

    def read_recordings= bool
      raise ArgumentError.new("need boolean had #{bool.inspect}") unless [TrueClass,FalseClass].detect{|x| bool.kind_of? x}
      return if @use_recordings == bool
      @use_recordings = bool
      if (bool)
        FakeWeb.allow_net_connect = false # raises FakeWeb::NetConnectNotAllowedError
        mani = manifest
        base = File.join(my_recordings_dir,'files')
        mani[1]["files"].each_with_index do |elem,idx|
          response_file_path = File.join(base, elem["filename"])
          response = File.read response_file_path
          FakeWeb.register_uri(elem["method"].to_sym, elem["url"], :response => response)
        end
      else
        raise "turning read_recordings off is not yet implemented"
      end
    end

    def write_recordings= bool
      raise ArgumentError.new("need boolean had #{bool.inspect}") unless [TrueClass,FalseClass].detect{|x| bool.kind_of? x}
      return if @write_recordings == bool
      @write_recordings = bool
      if (bool)
        dir = my_recordings_dir
        unless File.exist? dir
          init_recordings_dir
        end
      end
    end

    def init_recordings_dir
      raise "check that the folder doesn't already exist before you call this." if File.exist? my_recordings_dir
      unless File.exist? base_recordings_dir
        raise "something is really wrong. doesn't exist: #{relativize_path(base_recordings_dir)}"
      end
      FileUtils.mkdir_p File.join(my_recordings_dir,'files')
      @manifest = [
       {"comment" => "This data is part of Hipe::SocialSync::RecordingTransport api"},
       {"files" => []}
      ]
      save_manifest!
    end

    # Check that the appropriate folders are writable
    # @return [Boolean] true if everything's ok, else raise RuntimeException
    def assert_environment
      init_recordings_dir unless File.exist? my_recordings_dir
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

    # @return [GoldenHammer] response object
    def record_response method, url, response
      method = method.to_s
      my_response = Response.new
      mani = manifest
      idx = index_of_recorded_response url
      if ! @clobber_recordings and idx
        raise "Response already exists for #{url.inspect}.  Do you want to turn @clobber_recordings on?"
      end
      if idx
        verb = 'Rewrote'
      else
        verb = 'Wrote'
        md5 = MD5.new(url).to_s
        mani[1]["files"] << { "url" => url, "filename" => md5 }
        idx = mani[1]["files"].size - 1
      end
      mani[1]["files"][idx]["method"] = method
      filename = mani[1]["files"][idx]["filename"]
      full_path = File.join(my_recordings_dir,'files',filename)
      File.open(full_path,'w+'){|fh| fh.write response}
      save_manifest!
      my_response.puts "#{verb} response for #{method.upcase} #{url} to #{relativize_path(full_path)}"
      my_response
    end

    def index_of_recorded_response url
      manifest[1]["files"].index{|x| x["url"] == url }
    end

    def has_recorded_response? url
      !! index_of_recorded_response(url)
    end
  end
end
