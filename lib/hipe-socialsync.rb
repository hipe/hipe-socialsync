#!/usr/bin/env ruby
require 'rubygems'
require 'ruby-debug'
require 'ostruct'
require 'hipe-cli'
require 'hipe-core'
require 'hipe-core/io/buffer-string'
require 'hipe-core/exception-like'

module Hipe
  module SocialSync
    VERSION = '0.0.3'
    DIR = File.expand_path('../..',__FILE__)       
    module Plugins; end  
    class Exception < Hipe::Exception
      include Hipe::ExceptionLike  
      self.modules = [Hipe::SocialSync]
      class << self
        alias_method :f, :factory
      end
    end    
  end
  class Exception  
    include Hipe::ExceptionLike
    class << self
      alias_method :f, :factory
    end
  end
  require 'hipe-socialsync/model'  
  module Experimental
    module CliClassExtensions
      def class_in_file! filename, container_module
        mod = container_module
        require filename
        raise Exception.f(%{filenames with classes must be lowcase and dashes, not "#{filename}"},
          :type => :bad_plugin_filename) unless md = %r{/([-a-z]+)\.rb$}.match(filename)
        class_name_singular = md[1].gsub(/(?:^|-)[a-z]/){|x| x.upcase}        
        class_names = [class_name_singular, %{#{class_name_singular}s}]
        class_name = class_names.detect { |class_name| mod.constants.include?(class_name) }
        return mod.const_get(class_name) if class_name
        raise Exception.f(%{couldn't find class "#{class_name_singular}(s)" in #{filename}},
          :type=>:plugin_not_found)
      end
      def load_plugins_from_dir(full_path,container_module)
        skip_file = (File.join full_path, 'ignore-list')
        skip_list = File.exist?(skip_file) ? File.read(skip_file).split("\n") : []
        files = Dir[File.join full_path, '*.rb']
        raise Exception.f(%{no plugins in directory: "#{full_path}"}) unless files.size > 0
        files.each do |filename|
          next if skip_list.include?(File.basename(filename))
          cli.plugins << class_in_file!(filename,container_module)
        end
      end    
    end  
    module Erroneous
      def errors
        @errors ||= []
        @errors
      end
      def valid?
        !@errors || @errors.size == 0
      end
    end  
    module HashOpenStructExtension
      def init_hash_openstruct_extension
        super()
        @open_struct = OpenStruct.new
        @open_struct.instance_variable_set('@table',self)
      end
      def method_missing(method_name, *args)
        @open_struct.method_missing(method_name, *args)
      end
    end
    class GoldenHammer < Hipe::Io::BufferString
      include Erroneous
      attr_reader :data
      def initialize
        super()
        @data = {}
        @data.extend HashOpenStructExtension
      end
    end  
  end
  module SocialSync
    class App
      include Hipe::Cli      
      extend Hipe::Experimental::CliClassExtensions
      load_plugins_from_dir %{#{DIR}/lib/hipe-socialsync/controllers}, Plugins
      cli.description = 'Import your wordpress blogs into tumblr.'
      cli.does '-h','--help' , 'display this help screen (for the sosy app)'
      cli.out[:golden_hammer] = Hipe::Experimental::GoldenHammer
    end     
  end
end

