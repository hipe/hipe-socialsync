require 'hipe-core/infrastructure/strict-setter-getter'

module Hipe::Interactive
  # this is an experimental library that is similar on the surface to Hipe::Cli
  # but different in its inspiration and ultimate goal.  Whereas Hipe::Cli tries to
  # provide an api for modeling command-line grammars and routing requests to functions
  # and providing help and validation; this library attempts to provide a more
  # abstract api for a class to use to reveal "public" (very public) interface
  # information about itself to whatever controller or view layer is being used.
  # Whereas hipe-cli had to concern itself w/ the order of arguments, etc;
  # this will not.  Nor should this assume any responsibility for carrying out requests.

  # In one sentence this is a library for modeling interface reflection.

  # what we're aiming for may be something like form-generation but on a
  # higher, interface-wide level.

  # it is also possible that this may one day be used in tandem with Hipe::Cli,
  # possibly to generate reflections from it.

  # this might simply be an addendum to hipe-cli.  Cli will worry about parameters, validation and
  # routing, and this will worry about revealing interface information

  # it bears pointing out that neither one is a subset of the other.  Classes
  # can be cli and not be an interface reflector, and vice-versa

  module InterfaceReflector
    # classes include this if they want to reveal parts of their interface
    # as an interactive interface (usu. to the end user)
    # By pulling this in, the class gets the class method "interactive()"
    # which indicates that a command exists as somehow callable (it may one day be context sensitive
    # to the object state or to user permissions, etc)

    # the class also gets an interface() method and @interface member. see Interface for more.
    def self.included klass
      interface_prototype = Interface.new
      klass.instance_variable_set('@interface_prototype',interface_prototype) # why eigenclass instead? @todo
      klass.send(:extend, InterfaceReflectorClassMethods)
    end

    def interface
      @interface ||= self.class.interface_prototype.dup_two_levels
    end
  end

  module InterfaceReflectorClassMethods
    def interactive name, *args
      @interface_prototype.add_command name, *args
    end
    def interface_prototype
      @interface_prototype
    end
  end

  class Interface
    # classes that Are an IntefaceReflector (er.. that mix it in) have an Interface.
    # objects of those classes also have an Interface (the details of this are in flux:)
    # If the interface is requested (either by the object or by someone else), the object gets its own instance
    # of its interface, which can change over the lifetime of the object.
    # hm... maybe *only* objects have an interface?   This might take a javascript-like prototype-based tack.
    # because the objects can change state of their interface over time, it's meaningless
    # to ask for the interface divorced from object state.  If you want to know the inteface of objects of class X
    # you should create a new object of that class and query it, not the class

    # yes that's it.  A class has an "interface prototype" (which happens to be an Interaface object)
    # and when objects of this class are created they get a deep copy of this prototype (two levels deep...)

    # the interface is experimental - we are reluctant to reveal the commands object to the api
    # this is a wrapper that enforces the visibility or hidden-ness of commands

    # an equivalent to all of the following should be possible w/ the below methods  each(), has_key?, size


    # @param [Interface] "prototype" -- this form of the constructor is private to this class.
    # @private { if present, do a semi-deep copy from this interface, which is probably
    #            the prototype interface that the class defined}

    def initialize(prototype = nil)
      if prototype.nil?
        @commands = Commands.new
        @frozen_accessor = nil # callers should be able to use the accesors of the Commands object in a read-only style
      else
        @commands = prototype.instance_variable_get('@commands').dup
        @frozen_accessor = nil
      end
    end

    # why two levels? because for now command-objects don't point to anything but primitives
    def dup_two_levels
      self.class.new self
    end

    # @return [Array] a list of visible commands
    def commands
      @commands.select{ |command| command.visible?  }
    end

    # @return [Array] a list of all commands, visible, invisible, or otherwise
    def all_commands
      @order.map{ |k| @commands[k] }
    end

    # @return [Commands] this is just an easy way for us to let callers use the openstruct-like or hash-liek accessor
    def command
      @frozen_accesssor ||= @commands.dup.freeze
    end

    def add_command name, *args
      @frozen_accessor = nil
      @commands << Command.new(name, *args)
    end

    def hide(*names); with(*names){|x| x.hide} end

    def show(*names); with(*names){|x| x.show} end

    protected
      def with *names
        names.each do |name|
          yield @commands[name]
        end
      end
  end

  class Commands
    include Enumerable
    #
    # @api private
    #
    # Experimental - the OpenStruct-iness of this may change.  To be safe use the hash-like accessor []
    #
    # You cannot remove commands only add them (or hide them once they are added.)
    #
    # It's an interface for accessing the collection of commands that is a subset of OrderedHash and OpenStruct.
    # Because the namespace of methods that are nouns is the domain of the open-structed-ness
    # of this, any singular or plural nouns that we define here will have an (ugly) leading underscore
    # (That is, we can't define a method called keys() because there might be a command called keys() that this reflects)
    # crap that goes for verbs too.   ug.
    # we need to make an exception for "each()", so we can be enumerable

    def initialize(dup_from = nil)
      @meta  = class << self; self end   # it's good to keep this lying around
      if dup_from.nil?
        @order = []
        @table = {}
      else
        @order = dup_from.instance_variable_get('@order').dup
        their_table = dup_from.instance_variable_get('@table')
        @table = {}
        their_table.each do |k,v|
          @table[k] = their_table[k].dup
        end
      end
    end

    def dup
      self.class.new self
    end

    def << command
      raise TypeError.new "Need Command have #{command.class}" unless Command === command
      name = command.name
      raise RuntimeError("Duplicate name #{name.inspect}") if @table[name]
      @table[name] = command
      @order << name
      @meta.send(:define_method, name) { @table[name] } # thanks ostruct
    end

    def each
      @order.each do |key|
        yield @table[key]
      end
    end

    def _size
      @order.size
    end

    def [](name)
      @table[name]
    end
  end

  # if you ever end up pointing to other objects, see dup_two_levels above, and implement dup() appropriately
  class Command
    extend Hipe::StrictSetterGetter
    symbol_setter_getters  :name, :method_name
    boolean_setter_getter :visible
    string_setter_getter :label

    def initialize name, opts=nil
      raise TypeError.new("opts must be hash") unless opts.nil? || Hash === opts
      @visible = true
      opts ||= {}
      opts[:name] = name
      opts.each do |k, v|
        if respond_to? "#{k}="
          send "#{k}=",v
        else
          raise ArgumentError.new(%{No such option #{k.inspect}})
        end
      end
    end
    def hide; self.visible = false end
    def show; self.visible = true  end
    def hidden?; ! visible end
    def hidden= bool; self.visible = ! bool end
    def method_name; @method_name || @name end
    def label
      @label || @name.to_s.gsub('_', ' ')
    end
  end
end
