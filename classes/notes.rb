require 'ap'
require 'colorize'
require 'fileutils'
require_relative 'note'

class Notes
  def initialize(config)
    @config = config
    @notes = Dir[File.join(@config.note_path, '**', '*')].select do |file|
      File.extname(file) == '.md'
    end.map do |file|
      Note.new(file)
    end
  end

  #/================================\#
  #          REPL type thing         #
  #\================================/#

  def await_command(message = nil)
    puts message if message
    print '> '.bold.magenta
    input = STDIN.gets.chomp

    # Strip and process
    action, *params = input.strip.gsub(/\s{2,}/, '').split(' ')
    run_command(action || 'help', params)
  end

  def run_command(action, params)
    case action.downcase
    when 'n', 'c', 'new', 'create'
      if params.first
        filename = File.basename(params.first, File.extname(params.first)) + '.md'
        dirname = File.join(@config.note_path, File.dirname(params.first))
        full_path = File.join(dirname, filename)
  
        puts "[NOT IMPLEMENTED] Creating new note at #{full_path.bold.cyan}"

        system "#{@config.editor} '#{full_path}'"

        # Once created, add to the list.
        if File.exists?(full_path)
          @notes << Note.new(full_path)
        end
      else
        puts "Please enter a filename as the first parameter"
      end
    when 'e', 'o', 'edit', 'open'
      num = params.first.to_i
      note = @filtered[num - 1]

      if note
        system "#{@config.editor} '#{note.path}'"
      else
        puts "Hey! There is no note #{num}! Nice try."
      end
    when 'd', 'rm', 'delete'
      puts "Deleting note number #{params.first}"
      num = params.first.to_i
      note = @filtered[num - 1]

      if note
        if confirm("You're #{'sure'.italic} you want to delete note #{num.to_s.bold.white} with title #{note.title.bold.white}?")
          FileUtils.rm(note.path)
          @notes.delete(note)
          @filtered.delete(note)
          puts "Deleted!"
        else
          puts "Whew! That was close."
        end
      else
        puts "Looks like your job is done here, since note #{num} doesn't exist anyway!"
      end
    when 's', 'f', 'search', 'find'
      term = params.join(' ')
      search(term)
    when 'l', 'ls', 'list'
      list
    when 'h', 'help'
      puts
      puts "Enter a command with the structure:"
      puts "    #{'>'.bold.magenta} action parameter(s)"
      puts
      puts "Action being one of:"
      puts "    - #{'new'.bold.white} (or #{'create'.bold.white}, or #{'c'.bold.white}, or #{'n'.bold.white})"
      puts "    - #{'edit'.bold.white} (or #{'e'.bold.white}, or #{'open'.bold.white}, or #{'o'.bold.white})"
      puts "    - #{'delete'.bold.white} (or #{'d'.bold.white}, or #{'rm'.bold.white})"
      puts "    - #{'search'.bold.white} (or #{'find'.bold.white}, or #{'f'.bold.white}, or #{'s'.bold.white})"
      puts "    - #{'list'.bold.white} (or #{'l'.bold.white}, or #{'ls'.bold.white})"
      puts
      puts "And 'parameter' usually being the number next to the note you want to work with."
      puts "In the case of #{'search'.bold.white} or #{'find'.bold.white}, it would be the search term."
      puts "#{'list'.bold.white} takes no parameters, since it just prints out everything."
      puts
      puts "You can also enter #{'q'.bold.white}, #{'quit'.bold.white}, or #{'exit'.bold.white} to quit the program."
      puts
    when 'q', 'quit', 'exit', 'close'
      exit
    else
      await_command("Sorry, didn't quite get that...")
    end

    await_command # Drop back to REPL
  end

  def confirm(message = 'Confirm')
    print "#{message} [y/n]"
    case gets.chomp.strip.downcase
    when 'y', 'yes', 'yeah', 'sure', 'yep', 'okay', 'aye'
      return true
    when 'n', 'no', 'nope', 'nay'
      return false
    else
      return confirm("Sorry, didn't quite get that...")
    end
  end

  def note_num_exists(number)
    return !!@filtered[number - 1]
  end

  #/================================\#
  #           The Commands           #
  #\================================/#

  def search(term)    
    term = term.downcase # Search is case insensitive

    @filtered = @notes.select do |note|
      note.title.downcase.include?(term) || note.content.downcase.include?(term)
    end
    len = @filtered.length

    print_list("Found #{len} Match#{'es' if len != 1}", @filtered)
  end

  def list
    @filtered = @notes
    print_list('All Notes', @filtered)
  end

  #/================================\#
  #             Utilities            #
  #\================================/#

  private def print_list(title, notes)
    path_length = @config.note_path.split('/').length
    i = 0

    puts
    puts "    #{title}".bold
    puts "    #{'-' * title.length}"
    puts

    notes.each do |note|
      i += 1
      puts "#{i}.".ljust(4) + note.title.bold
      puts "    #{note.path.gsub(@config.note_path, '')}".italic.light_magenta
      
      excerpt = note.excerpt
      if excerpt == ''
        puts '    No Content'
      else
        puts "    ...#{excerpt}..."
      end
      puts
    end

    puts "    Total Notes: #{i.to_s.bold}"
    puts
  end
end