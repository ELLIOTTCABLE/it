($:.unshift File.expand_path(File.join(
  File.dirname(__FILE__)                ))).uniq!
($:.unshift File.expand_path(File.join(
  File.dirname(__FILE__), '..', 'lib'   ))).uniq!

require 'speck'
