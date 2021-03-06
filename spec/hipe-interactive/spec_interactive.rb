# bacon spec/hipe-interactive/spec_interactive.rb
require 'hipe-socialsync/interactive'
require 'bacon'
require 'ruby-debug'

module Hipe::Interactive
  class Restaurant
    include InterfaceReflector

    interactive :give_menu
    def give_menu; "menu" end

    interactive :take_order
    def take_order request_object
      # ...
    end

    def wash_dishes
      # ...
    end

    def close
      interface.hide :give_menu, :take_order, :fancy_truffles
    end

    interactive :fancy_truffles, :hidden => true
    def fancy_truffles
    end

    def food_inspector!
      wash_dishes
      interface.show :fancy_truffles
    end

  end


  # alternate interface for interface
  class Restaurant2
    include InterfaceReflector

    interface.define do
      interactive :give_menu
      interactive :take_order
      interactive :fancy_truffles, :hidden => true
    end

    def give_menu; "menu" end

    def take_order request_object
      # ...
    end

    def wash_dishes
      # ...
    end

    def close
      interface.hide :give_menu, :take_order, :fancy_truffles
    end

    def fancy_truffles
    end

    def food_inspector!
      wash_dishes
      interface.show :fancy_truffles
    end
  end

  describe Hipe::Interactive do
    it "should hide and show (inter1)" do
      rest = Restaurant.new
      interface = rest.interface
      interface.should.be.kind_of Interface
      interface.commands.size.should.equal 2
      (interface.commands.map{|x| x.label } * ', ').should.equal "give menu, take order"
      rest.food_inspector!
      (interface.commands.map{|x| x.label } * ', ').should.equal "give menu, take order, fancy truffles"
      rest.close
      (interface.commands.map{|x| x.label } * ', ').should.equal ""
    end

    it "should create an equivalent interface with the alternate syntax (inter2)" do
      rest1 = Restaurant.new
      rest2 = Restaurant.new
      (rest1.interface == rest2.interface).should.equal true
    end
  end
  # @api-private
  def _table
    @table
  end

end
