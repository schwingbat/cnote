require "colorize"
require_relative "cnote/config"
require_relative "cnote/notes"
require_relative "cnote/version"

# module Cnote
  # Your code goes here...
# end

config = Config.new("~/.cnote.yaml")

# Start REPL
notes = Notes.new(config)
notes.await_command("\nWelcome to CNote! Type #{'help'.white} or #{'h'.white} to see a list of available commands.")
