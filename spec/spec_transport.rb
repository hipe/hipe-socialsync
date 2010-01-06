# bacon spec/spec_transport.rb
require 'hipe-socialsync'
require 'bacon'
require 'hipe-core/test/bacon-extensions'
require 'hipe-socialsync/transport/recording-transport'

module Hipe::SocialSync

  TestHelper = Hipe::Test::Helper.singleton self

  class RecordingTransportTester < RecordingTransport
    register_transport_as :recording_test
  end

  describe Transports do
    it "not all transports should be loaded into the collection at first (trans1)" do
      the_transporters = Transports.new
      the_transporters.keys.should.equal [:recording_test]
    end

    it "not all transports should be loaded into the collection at first (trans1)" do
      the_transporters = Transports.new
      trans = the_transporters[:recording_test]
      trans.should.be.kind_of RecordingTransportTester
    end

    it "should initialize a folder" do
      trans = Transports.new[:recording_test]
      helper = TestHelper
      helper.clear_writable_temporary_directory!
      dir = helper.writable_temporary_directory
      trans.base_recordings_dir = dir
      trans.assert_environment

      trans = Transports.new[:recording_test]
      trans.base_recordings_dir = dir
      manifest = trans.manifest
      manifest.should.be.kind_of Array
      manifest.length.should.satisfy{|x| x >= 2 }
      manifest[0].should.be.kind_of Hash
      manifest[0].should.satisfy{|x| x.has_key? "comment" }
      manifest[1].should.be.kind_of Hash
      manifest[1].should.satisfy{|x| x.has_key? "entries" }
      manifest[1]["entries"].should.be.kind_of Array
      manifest[1]["entries"].length.should.equal 0
    end
  end
end
