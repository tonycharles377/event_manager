require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        legislators = civic_info.representative_info_by_address(
            address: zipcode,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

#Assignment: Clean phone numbers
def clean_phone_number(phone_number)

    cleaned_num = phone_number.gsub(/\D/, '')

    if cleaned_num.length == 11 && cleaned_num[0] == '1'
        cleaned_num[1..10]
    elsif cleaned_num.length != 10
        cleaned_num = ''
    else
        cleaned_num
    end

end

def save_thank_you_letter(id,form_letter)
    #create an output folder
    Dir.mkdir('output') unless Dir.exist?('output')

    #Save each form letter to a file based on the id of the attendee
    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

puts "Event Manager Initialized!"

template_latter = File.read('form_letter.erb')
erb_template = ERB.new template_latter

contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
)

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    phone_number = clean_phone_number(row[:homephone])
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)
    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)

    puts "#{name} can sign up for sms alert for phone number #{phone_number}" if phone_number != ''
end