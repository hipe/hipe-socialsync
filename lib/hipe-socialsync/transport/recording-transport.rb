require 'fakeweb'
require 'json'
require 'hipe-socialsync'

module Hipe::SocialSync
  class RecordingTransport
    # this is a base class for transports that can optionally record their requests and responses using fakeweb

    # create a class method to set and get the transport name (for child classes)
    class << self
      extend Hipe::StrictSetterGetter
      symbol_setter_getter :transport_name
      def register_transport_as name
        self.transport_name = name
        Transports.register_factory transport_name, self
      end
    end

    extend Hipe::StrictSetterGetter
    include ViewCommon

    boolean_setter_getters :use_recordings, :record # we override the setters but we want the foo? form
    string_setter_getters :base_recordings_dir

    def initialize
      @record = false
      @use_recordings = false
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

    def use_recordings=(bool)
      raise TypeError.new("need boolean had #{bool.inspect}") unless [TrueClass,FalseClass].detect{|x| bool.kind_of? x}
      return if @use_recordings == bool
      @use_recordings = bool
      if (bool)
      end
    end

    def record=(bool)
      raise TypeError.new("need boolean had #{bool.inspect}") unless [TrueClass,FalseClass].detect{|x| bool.kind_of? x}
      return if @record == bool
      @record = bool
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
      FileUtils.mkdir_p my_recordings_dir
      @manifest = [
       {:comment => "This data is part of Hipe::SocialSync::RecordingTransport api"},
       {:files => []}
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

    def manifest
      @manifest ||= JSON.parse File.read(my_manifest_path)
    end

    def save_manifest!
      json = @manifest.to_json
      File.open(my_manifest_path,'w'){|fh| fh.write json}
    end
  end
end