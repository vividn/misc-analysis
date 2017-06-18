#!/usr/bin/ruby
require 'date'

# Process all my notebook files to track the amount that I write

data_dir = '/home/fabernj/Notebooks/'
save_file = '/home/fabernj/Data/datum/words.tsv'

# Save the datum data in an array first to allow for sorting before writing
output = []

# Go through each notebook and extract number of words written per day
Dir.glob("#{data_dir}*.md") do |notebook|
  # Get the name of the notebook without the rest of the filename and .md
  name = notebook.split('/')[-1].chomp('.md')
  print("Processing: #{name}\n")

  # Initialize date, time, and word variables
  entryDate,newEntryDate = nil
  entryTime,newEntryTime = nil
  entryWordCount = 0;

  # Load the notebook file into memory.
  File.open(notebook,'r').each do |line|

    # If a new entry has been started, write the last entry's data to the output
    if newEntryDate != entryDate || newEntryTime != entryTime
      # Only write if wordcount is > 0
      if entryWordCount > 0
        output << sprintf("%s\t%s\t%d\t%s",entryDate,entryTime,entryWordCount,name)
      end

      entryDate = newEntryDate
      entryTime = newEntryTime
      entryWordCount = 0
    end


    # There are 2 types of lines that change the date and don't count towards word count

    # "## YY-mm-dd, DOW"
    match = line.match(/^## ?(\d{4}-\d{2}-\d{2}),/)
    next if match

    # "*[HH:MM:SS ~ YYYY-mm-dd]*" May also be "*END OF ENTRY [...]*"
    match = line.match(/^ ?\*(END OF ENTRY )?\[(\d{2}:\d{2}:\d{2}) ~ (\d{4}-\d{2}-\d{2})\]\*$/)
    if match

      # If this is an END OF ENTRY marking don't record or change anything, just move on
      next if match[1]

      # Otherwise change the entryTime and entryDate
      newEntryTime = match[2] + '.000'
      newEntryDate = match[3]
      next
    end

    # Skip the lines before the first date entry
    next unless entryDate

    # For the rest of lines count the words and add them to the hash
    wordCount = line.split.size

    # Add the wordcount to the current entry 
    entryWordCount += wordCount
  end

  # Write the last entry to the output array
  output << sprintf("%s\t%s\t%d\t%s",entryDate,entryTime,entryWordCount,name)

end


# Sort the output to interlace the entries across all the notebooks
output.sort!

# Write all the data to the datum file
File.open(save_file,'w') do |f|

  # Header line
  f.puts("Date\tTime\tWords\tNotebook")

  # Data
  output.each { |line| f.puts(line) }
end
