require "csv"
require "date"
require "erb"
require "google/apis/civicinfo_v2"
require "time"

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: %w[legislatorUpperBody legislatorLowerBody],
    ).officials
  rescue StandardError
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def clean_zipcode(zipcode)
  # if zipcode.nil?
  #   zipcode = "00000"
  # elsif zipcode.length < 5
  #   zipcode = zipcode.rjust(5, "0")
  # elsif zipcode.length > 5
  #   zipcode = zipcode[0..4]
  # end
  zipcode.to_s.rjust(5, "0")[0..4]
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") { |file| file.puts form_letter }
end

def clean_phone_numbers(number)
  number = number.scan(/\d/).join("")
  bad_number = nil

  # assumptions
  output = bad_number if number.length < 10
  output = bad_number if number.length == 11 && number[0] != 1
  output = bad_number if number.length > 11
  output = number if number.length == 10
  output = number[1 - 10] if number.length == 11 && number[0] == 1

  return output
end

def open_csv(csv)
  contents = CSV.open(csv, headers: true, header_converters: :symbol)
  contents
end

def target_time(csv)
  contents = open_csv(csv)
  tracker = Hash.new { 0 }
  day_tracker = Hash.new { 0 }

  # Get each registration date
  contents.each do |row|
    # date_obj = Date._parse(row[:regdate])
    time_obj = Time.strptime(row[:regdate], "%m/%d/%y %H:%M")
    date_obj = Date.strptime(row[:regdate], "%m/%d/%y %H:%M")
    tracker[time_obj.hour] += 1
    day_tracker[date_obj.strftime("%A")] += 1
  end

  best_day = day_tracker.max_by { |k, v| v }
  best_hour = tracker.max_by { |k, v| v }
  return best_day, best_hour
end

def create_form_letter(csv)
  contents = open_csv(csv)
  template_letter = File.read("form_letter.erb")
  erb_template = ERB.new(template_letter)

  contents.each do |row|
    id = row[0]
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)
  end
end

puts "Event Manager Initialized!"

file_name = "event_attendees.csv"
times = target_time(file_name)

create_form_letter(file_name)
puts "Busiest hour for registrations: #{times[1][0]}"
puts "Busiest day of the week for registrations: #{times[0][0]}"
