require "colorize"
require "cnote/config"
require "cnote/notes"
require "cnote/version"

config = Config.new("~/.cnote.yaml")
notes = Notes.new(config)

if ARGV[0]
  notes.run_command(ARGV.shift, ARGV)
else
  notes.await_command("\nWelcome to CNote! Type #{'help'.white} or #{'h'.white} to see a list of available commands.")
end