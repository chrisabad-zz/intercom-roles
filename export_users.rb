require 'rubygems'
require 'csv'
require 'ruby-progressbar'
require 'intercom'

# Settings for Intercom
Intercom.app_id = 'z7km0wgo'
Intercom.api_key = '637f2fa8f92a67f26b0ccd2c268eaf14b93bdb91'

puts 'Exporting users to CSV.'
progress_bar = ProgressBar.create(
    :format => '%a |%B| %c of %C users exported - %E',
    :title => "Progress",
    :total => Intercom::User.all.count
)

# id_string = ''

CSV.open("users.csv", "wb") do |row|
  # Headers
  row << ["User ID"]
  Intercom::User.all.each do |user|
    row << [user.user_id]
   	# id_string = id_string + "#{user.user_id}, "
    progress_bar.increment
  end
end

# puts id_string

