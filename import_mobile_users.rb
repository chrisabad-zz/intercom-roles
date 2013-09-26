require 'rubygems'
require 'csv'
require 'ruby-progressbar'
require 'intercom'

# Settings for Intercom
Intercom.app_id = 'z7km0wgo'
Intercom.api_key = '637f2fa8f92a67f26b0ccd2c268eaf14b93bdb91'

# Settings for CSV
csv_filename = 'mobile.csv'
csv_options = {
    headers:        :first_row,
    converters:     [ :numeric ] 
}

def update_user(user)
	begin
		intercom_user = Intercom::User.find_by_user_id(user['User ID'].to_s)
		intercom_user.company = { :id => user['Company ID'], 'Mobile User' => true }
		intercom_user.save
		$progress_bar.increment
	rescue
		$progress_bar_total = $progress_bar_total-1
		$progress_bar.total = $progress_bar_total
	end
end

# Get a list of all the sites from the CSV
puts 'Importing the list of users.'

users = []
raw_data = CSV.read(csv_filename, csv_options)
raw_data.values_at('Email', 'Account id').each do |row|
	users << {
		'User ID' => row[0],
		'Company ID' => row[1]
	}
end

puts "#{users.size} users found in the list."

# Update each user with the appropriate role.
puts 'Updating mobile users.'

# Store threads here
threads = []

$progress_bar_total = users.size
$progress_bar = ProgressBar.create(
    :format => '%a |%B| %c of %C users updated - %E',
    :title => "Progress",
    :total => $progress_bar_total
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

