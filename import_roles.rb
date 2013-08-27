require 'rubygems'
require 'csv'
require 'ruby-progressbar'
require 'intercom'

# Settings for Intercom
Intercom.app_id = 'z7km0wgo'
Intercom.api_key = '637f2fa8f92a67f26b0ccd2c268eaf14b93bdb91'

# Settings for CSV
csv_filename = 'user_roles.csv'
csv_options = {
    headers:        :first_row,
    converters:     [ :numeric ] 
}

def update_user(user)
	begin
		intercom_user = Intercom::User.find_by_user_id(user['User ID'].to_s)
		intercom_user.custom_data['Role'] = user['Role']
		# intercom_user.company = { :id => user['Site ID'], 'Status' => user['Status'] }
		intercom_user.custom_data['Status'] = user['Status']
		intercom_user.save
	rescue
		$progress_bar.log "Couldn't find User ID #{user['User ID']}."
		# Let's just fail silently, shall we?
	end
	$progress_bar.increment
end

# Get a list of all the sites from the CSV
puts 'Importing the list of users.'

users = []
raw_data = CSV.read(csv_filename, csv_options)
raw_data.values_at('User ID', 'Role', 'Status').each do |row|
	users << {
		'User ID' => row[0],
		'Role' => row[1],
		'Status' => row[2]
	}
end

puts "#{users.size} users found in the list."

# Update each user with the appropriate role.
puts 'Updating user roles.'

# Store threads here
threads = []

$progress_bar = ProgressBar.create(
    :format => '%a |%B| %c of %C users updated - %E',
    :title => "Progress",
    :total => users.size
)

users.each do |user|
	# Only open 20 threads at a time
  if(Thread.list.count % 20 != 0) 
      update_thread = Thread.new do
          update_user(user)
      end
      threads << update_thread
  else
	  # Wait for open threads to finish executing 
	  # before starting new one
	  threads.each do |thread|
	    thread.join
	  end
	  # Start importing again
	  update_thread = Thread.new do
	    update_user(user)
	  end
	 end
  threads << update_thread
end

# Wait for threads to finish executing before exiting the program
threads.each do |thread|
  thread.join
end

