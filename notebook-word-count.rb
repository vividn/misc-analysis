#!/usr/bin/ruby
require 'date'

# Process all my notebook files to track the amount that I write

save_dir = '/home/fabernj/Data/notebooks/'
data_dir = '/home/fabernj/Notebooks/'

# Where to save the data
save_file = File.new("#{save_dir}word-count.tsv",'w')

# Header line
save_file.write("Notebook\tDate\tWord Count\n")

# Hash to save total word counts (across notebooks)
total_words = {}

# Go through each notebook and extract number of words written per day
Dir.glob("#{data_dir}*.md") do |notebook|
  # Get the name of the notebook without the rest of the filename and .md
  name = notebook.split('/')[-1].chomp('.md')
  print("Processing: #{name}\n")

  #Create a hash. Data format: {date => number of words written}
  wordData = {}
  entryDate = nil

  # Load the notebook file into memory.
  File.open(notebook,'r').each do |line|
    # There are 2 types of lines that change the date and don't count towards word count

    # "## YY-mm-dd, DOW"
    match = line.match(/^## ?(\d{4}-\d{2}-\d{2}),/)
    if match
      entryDate = match[1]
      next
    end

    # "*[HH:MM:SS ~ YYYY-mm-dd]*" May also be "*END OF ENTRY [...]*"
    match = line.match(/^ ?\*(?:END OF ENTRY )?\[(\d{2}:\d{2}:\d{2}) ~ (\d{4}-\d{2}-\d{2})\]\*$/)
    if match
      entryTime = match[1]
      entryDate = match[2]
      next
    end

    # Skip the lines before the first date entry
    next unless entryDate

    # For the rest of lines count the words and add them to the hash
    wordCount = line.split.size

    # Add the wordcount to the current value in the hash
    wordData[entryDate] = (wordData[entryDate] || 0) + wordCount
  end

  sorted_word_data = wordData.sort_by { |date, count| date }

  # Generate a range of dates from the first date to the last date
  first_date = Date.parse(sorted_word_data[0][0])
  last_date = Date.today
  date_range = first_date..last_date

  # Fill in zeroes
  date_range.each do |entry_date|
    date_str = entry_date.strftime('%Y-%m-%d')
    wordData[date_str] = wordData[date_str] || 0
  end

  # Resort
  sorted_word_data = wordData.sort_by { |date, count| date }

  # For each date key, write the data
  sorted_word_data.each do |datum|
    save_file.write("#{name}\t#{datum[0]}\t#{datum[1]}\n")
  end

  # Add results to total hash
  sorted_word_data.each do |datum|
    entry_date = datum[0]
    total_words[entry_date] = (total_words[entry_date] || 0) + datum[1]
  end


  #TODO Extract times, too

end
save_file.close

#### Analysis

# Separate the dates and word counts into different arrays for easier analysis
all_dates, all_words = total_words.sort_by {|entry_date, words| entry_date}.transpose


# Write the totals
File.open("#{save_dir}total_words.tsv",'w') do |file|
  all_dates.each_index {|index| file.write "#{all_dates[index]}\t#{all_words[index]}\n"}
end

# Calculate a 7-day moving window average
sliding_date = all_dates.each_cons(7).to_a
sliding_words = all_words.each_cons(7).to_a

File.open("#{save_dir}seven_day.tsv",'w') do |file|
  sliding_date.each_index do |i|
    end_date = sliding_date[i][-1]
    avg_words = sliding_words[i].reduce(:+).to_f / 7

    file.write "#{end_date}\t#{avg_words}\n"
  end
end

# Calculate a 30-day moving window average
sliding_date = all_dates.each_cons(30).to_a
sliding_words = all_words.each_cons(30).to_a

File.open("#{save_dir}thirty_day.tsv",'w') do |file|
  sliding_date.each_index do |i|
    end_date = sliding_date[i][-1]
    avg_words = sliding_words[i].reduce(:+).to_f / 30

    file.write "#{end_date}\t#{avg_words}\n"
  end
end
