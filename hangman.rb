require 'yaml'

class Hangman

  attr_reader :hangman, :res
  attr_accessor :incorrect_guesses

  def initialize(word, res, hangman, incorrect_guesses)
    @word = word
    @res = res
    @hangman = hangman
    @incorrect_guesses = incorrect_guesses
  end

  def to_yaml
    YAML.dump ({
      :word => @word,
      :res => @res,
      :hangman => @hangman,
      :incorrect_guesses => @incorrect_guesses
    })
  end

  def self.from_yaml(string)
    data = YAML.load(string)
    self.new(data[:word], data[:res], data[:hangman], data[:incorrect_guesses])
  end

  def self.new_word()
    word = ''
    until word.length >= 5 && word.length <= 12
      n = rand(61405)
      word = File.readlines("5desk.txt")[n][0..-3] # remove /r/n from the end of word
    end
    return word
  end

  def self.new_res(word)
    "-" * word.length
  end

  def self.new_hangman()
    "   |   "
  end

  def self.guess_is_valid(guess)
    guess.length == 1 && (('A'..'Z').include?(guess) || ('a'..'z').include?(guess))
  end

  def check_guess(guess)
    return @word.include?(guess)
  end

  def add_letters(letter)
  
    @word.chars.each_index do |idx| 
      if letter == @word.chars.at(idx) 
        @res[idx] = letter
      elsif letter.swapcase == @word.chars.at(idx) # address diff capitalizations
        @res[idx] = letter.swapcase
      end
    end
    
  end

  def add_hangman()
    case @incorrect_guesses
    when 1
      @hangman = "   |   \n   O   "
    when 2
      @hangman = "   |   \n   O   \n   |   "
    when 3
      @hangman = "   |   \n   O   \n  -|   "
    when 4
      @hangman = "   |   \n   O   \n  -|-  "
    when 5
      @hangman += "\n  /"
    when 6
      @hangman += " \\"
    else
      puts 'Error: something went wrong with the hangman'
    end
  end

  def is_gameover()
    @incorrect_guesses == 6
  end

  def is_win()
    @res == @word
  end

  def reveal_word()
    puts "The word is #{@word}"
  end

end

# main

play_again = 'y'
until play_again == 'n' # loop game

  # start a game.
  puts "\t*** HANGMAN ***\n\n\n"

  
  puts 'Type l to load a saved game, or n to begin a new game'
  choice = gets.chomp
  until choice == 'l' || choice == 'n'
    puts 'Invalid choice. Enter l or n'
    choice = gets.chomp
  end
  
  filename = ''
  if choice == 'l'
    puts 'Enter your filename:'
    filename = gets.chomp
    until File.exist?(filename) || filename == 'n'
      puts 'Invalid file. Make sure you entered the correct filename. You may also start a new game by typing [n]'
      filename = gets.chomp
    end
    if filename == 'n'
      choice = 'n'
    end
  end

  if choice == 'l' && File.exist?(filename)
    game = Hangman.from_yaml(File.read(filename))
    puts "Your word has #{game.res.length} letters:\n #{game.res}"
    puts game.hangman
    puts "You have #{6 - game.incorrect_guesses} guesses left."
  elsif choice == 'n' 
    word = Hangman.new_word
    game = Hangman.new(word, Hangman.new_res(word), Hangman.new_hangman, 0)
    puts "Your word has #{game.res.length} letters:\n #{game.res}"
  else
    puts 'Error with load game or new game choice' 
  end


  ### GAME LOOP ###

  until game.is_gameover || game.is_win

    # receive user input, a single-letter guess or 'save'
    guess = '' 
    until Hangman.guess_is_valid(guess) || guess == 'save'
      puts "\n\n\nEnter a single letter as your guess. You may also enter [save] to save the game"
      puts 'Entering an existing save file will overwrite it.'
      guess = gets.chomp
      puts 'Invalid entry.' unless Hangman.guess_is_valid(guess) || guess == 'save'
    end

    if guess == 'save'

      puts 'Enter a name for your save file. Use letters or underscores only. Omit the file extension.'
      save_file = gets.chomp
      while save_file.include?('.') || ('0'..'9').include?(save_file[0])
        puts 'Invalid filename. Do not include a file extension or begin your filename with a number.'
        save_file = gets.chomp
        # doesn't catch all special characters. too long...
      end
      save_file += '.yaml'
      File.open(save_file, 'w'){ |file| file.write(game.to_yaml) }
      puts "File saved at #{save_file}. Please close the session with Ctrl-C."
      while true
        gets.chomp
      end
    
    elsif guess != 'save' && Hangman.guess_is_valid(guess)

      # check guess and display res (current correct letters and hangman)
      if game.check_guess(guess)
        game.add_letters(guess)
        puts "[#{guess}] is in the word!\n #{game.res}"
        puts "nothing gets added to the hangman\n #{game.hangman}"
      else
        game.incorrect_guesses += 1
        game.add_hangman()
        puts "[#{guess}] is not in the word. :( \n #{game.res}"
        puts "...the hangman forms...\n #{game.hangman}"
        puts "You have #{6 - game.incorrect_guesses} guesses left."
      end
    
    else
      puts 'Error with guess input'
    end

  end

  # end message
  if game.is_gameover
    puts 'Game Over.'
    game.reveal_word
    puts 'Play again? y/n'
  elsif game.is_win
    puts 'You win! Play again? y/n'
  else
    puts 'Error with game end status'
  end

  play_again = gets.chomp
  until play_again == 'y' || play_again == 'n'
    puts 'Wrong input. Type y or n'
    play_again = gets.chomp
  end

end