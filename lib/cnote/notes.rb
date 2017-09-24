require "colorize"
require "fileutils"
require "time"
require "ap"
require "cnote/commands"
require "cnote/note"

class Notes
  include Commands

  def initialize(config)
    @config = config
    @index = 1
    @notes = Hash.new

    notes = Dir[File.join(@config.note_path, "**/*")].select do |f|
      [".txt", ".md"].include?(File.extname(f))
    end

    notes.each do |path|
      note = Note.new(path)
      note.index = @index

      @notes[@index] = note

      @index += 1
    end

    @indent = notes.length.to_s.length + 2

    set_filtered(@notes)
  end

  #/================================\#
  #          REPL type thing         #
  #\================================/#

  def await_command(message = nil)
    puts message if message
    print "#{@config.prompt} ".magenta
    input = STDIN.gets.chomp

    # Strip and process
    action, *params = input.strip.gsub(/\s{2,}/, " ").split(" ")
    run_command(action || "help", params)
  end

  def run_command(action, params)
    case action.downcase
    when "new", "create", "n", "c"
      create(params)
    when "edit", "open", "e", "o"
      open(params)
    when "delete", "d", "rm"
      delete(params)
    when "peek", "p"
      peek(params)
    when "tag", "t"
      tag(params)
    when "tags"
      tags(params)
    when "untag", "ut"
      untag(params)
    when "search", "find", "s", "f"
      search(params.join(" "))
    when "list", "l", "ls"
      list
    when "info", "i"
      info(params)
    when "help", "h"
      help
    when "config", "conf"
      config(params)
    when "quit", "exit", "close", "q"
      exit
    else
      puts "Sorry, didn't quite get that..."
      help
    end

    await_command # Drop back to REPL
  end

  #/================================\#
  #             Utilities            #
  #\================================/#

  private def indent
    " " * @indent
  end

  private def set_filtered(notes)
    @filtered = Hash.new

    case notes.class.to_s
    when "Array"
      notes.each do |note|
        @filtered[note.index] = note
      end
    when "Hash"
      notes.each do |num, note|
        @filtered[num] = note
      end
    else
      puts "Unrecognized notes format for set_filtered. Got #{notes.class}!"
    end
    
    @filtered
  end

  private def print_list(title, notes, verbose = false)
    path_length = @config.note_path.split("/").length
    count = 0;

    puts
    puts "#{indent}#{title}".bold
    puts "#{indent}#{"-" * title.length}"
    puts

    if verbose
      notes.each do |num, note|
        count += 1

        if !note
          puts "#{num}.".ljust(@indent) + " DELETED".italic
          next
        end

        puts "#{num}.".ljust(4) + note.title_limit(70).bold
        puts "#{indent}#{note.path.gsub(@config.note_path, "")}".italic.light_magenta
        if note.tags.length > 0
          tags = note.tags.map { |tag| tag.yellow }
          puts "#{indent}tags: " + "[#{tags.join('] [')}]"
        else
          puts "#{indent}<no tags>"
        end
        puts "#{indent}modified: " + note.modified.strftime("%a, %b %e %Y, %l:%M%P").italic
        puts "#{indent}created:  " + note.created.strftime("%a, %b %e %Y, %l:%M%P").italic
        puts
      end
    else
      notes.each do |num, note|
        count += 1

        if !note
          puts "#{num}.".ljust(@indent) + "DELETED".colorize(color: :white, background: :red).italic
          next
        end

        print "#{num}.".ljust(@indent) + note.title_limit(70).bold
        if note.tags.length > 0
          tags = note.tags.map { |tag| tag.yellow }
          print " [#{tags.join('] [')}]"
        end
        print "\n"
      end
    end
    
    puts
    puts "#{indent}Listed #{count.to_s.bold} Notes"
    puts
  end

  private def confirm(message = "Confirm")
    print "#{message} [y/n]: "
    case gets&.chomp&.strip&.downcase
    when "y", "yes", "yeah", "sure", "yep", "okay", "aye"
      return true
    when "n", "no", "nope", "nay"
      return false
    else
      return confirm("Sorry, didn't quite get that...")
    end
  end

  private def multi_note(params)
    notes = []

    params.first.split(",").each do |num|
      note = @notes[num.to_i]
      if note
        notes << note
      else
        puts "Note #{num} doesn't exist!"
      end
    end

    notes
  end

  private def recently_edited_first(notes)
    ap notes

    notes.sort_by { |note| note.modified }.reverse
  end

  private def has_tags(note, tags)
    has = true
    note_tags = note.tags
    tags.each do |tag|
      if !note_tags.include? tag
        has = false
        break
      end
    end
    has
  end

  private def does_not_have_tags(note, tags)
    doesnt_have = true
    note_tags = note.tags
    tags.each do |tag|
      if note_tags.include? tag
        doesnt_have = false
        break
      end
    end
    doesnt_have
  end
end