require "csv"
require "google/apis/civicinfo_v2"
require "erb"

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

puts "Event Manager Initialized!"

contents =
  CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new(template_letter)

contents.each do |row|
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  puts form_letter
end
