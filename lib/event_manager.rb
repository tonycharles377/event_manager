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

    cleaned_num = phone_number.gsub(/[^0-9]/, '')

    if cleaned_num.length == 11 && cleaned_num[0] == '1'
        cleaned_num[1..10]
    elsif cleaned_num.length != 10
        cleaned_num = ''
    else
        cleaned_num
    end

end

#Assignment: Time targeting
def time_targeting(reg_date_time_arr)
    hours = []

    reg_date_time_arr.each do |reg_date_time|
        hours << reg_date_time.hour
    end
    
    #create a hash where keys are unique numbers, and values are arrays of occurrences of each number
    frequency_hash = hours.group_by {|num| num}

    most_repeated_num = frequency_hash.max_by {|_, occurrences| occurrences.length} &.first

    puts "Peack registaration hour is #{most_repeated_num}:00hrs"
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
reg_date_time_arr = []

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    phone_number = clean_phone_number(row[:homephone])
    reg_date_time = Time.strptime(row[:regdate], "%m/%d/%y %H:%M")
    reg_date_time_arr << reg_date_time
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)
    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)

    puts "#{name} can sign up for sms alert for phone number #{phone_number}" if phone_number != ''
end

time_targeting(reg_date_time_arr)