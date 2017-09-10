require 'ap'
require 'yaml'
require 'fileutils'
require_relative 'classes/config'
require_relative 'classes/notes'

command = (ARGV[0] || '').strip.downcase
config = Config.new('~/.cnote.yaml')

def help
  puts "Try one of these:"
  puts "  cnote list"
  puts "  cnote search [term]"
end

case command
when 'list'
  notes = Notes.new(config)
  notes.list
when 'search', 'find'
  notes = Notes.new(config)
  notes.search(ARGV.slice(1, ARGV.length).join(' '))
when 'help'
  help
else
  # Start REPL
  notes = Notes.new(config)
  notes.await_command
end