require_relative 'speck_helper'

require 'it'
It::Battery = Speck::Battery.new

It::Battery << Speck.new(It) {}
