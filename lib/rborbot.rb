require 'forwardable'
require 'optparse'
require 'pry'
require 'xmpp4r'
require 'xmpp4r/client'
require 'xmpp4r/muc'
require 'xmpp4r/roster'

require 'rborbot/cli'
require 'rborbot/client'
require 'rborbot/client/muc'
require 'rborbot/env'
require 'rborbot/interactor'
require 'rborbot/version'

module Rborbot
  Error         = Class.new(StandardError)
  RuntimeError  = Class.new(RuntimeError)

  PRESENCE_STATUS = 'rborboting'.freeze
end
