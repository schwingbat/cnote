require "colorize"
require "cnote/config"
require "cnote/notes"
require "cnote/version"

config = Config.new("~/.cnote.yaml")

# Start REPL
notes = Notes.new(config)
notes.await_command("\nWelcome to CNote! Type #{'help'.white} or #{'h'.white} to see a list of available commands.")
