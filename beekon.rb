require 'ruby-debug'
require 'hpricot'
require 'open-uri'
require 'yaml'

# can we just check number of tickets per milestone and how
# that changes daily? The velocity might need to take into
# account that some tickets are moved from milestone to milesont
# instead of closed

@config = YAML::load_file('config.yml')
@activity = {}

def api_token
  @config['API_TOKEN']
end

def activity_file
  @config['ACTIVITY_FILE']
end

def project_url
  "http://devver.lighthouseapp.com/projects/10124-gridtest"
end

def tickets_url
  "#{project_url}/tickets.xml?_token=#{api_token}"
end

def tickets_created_on(date)
  url = tickets_url+"&q=created:'#{date}\'"
  document = Hpricot(open(url))
  tickets(document)
end

def tickets_closed_on(date)
  url = tickets_url+"&q=updated:'#{date}'+state:closed"
  document = Hpricot(open(url))
  tickets(document)
end

def tickets(document)
  (document/"/tickets/ticket").map{|x| {:milestone => Integer(x.at("milestone-id").inner_html), :number => Integer(x.at("number").inner_html)}}
end

def velocity_for(date)
  tickets_closed_on(date).length-tickets_created_on(date).length
end

def activity_for(date)
  {:closed => tickets_closed_on(date),
    :created => tickets_created_on(date) }
end

def load_activity
  if(File.exists?(activity_file))
    @activity = YAML::load_file(activity_file)
  else
    @activity = {}
  end
end

def save_activity
  File.open(activity_file,'w') do |f|
    f << @activity.to_yaml
  end
end

def add_activity_for(date)
  @activity[date] = activity_for(date)
end

load_activity

date = Date.parse("2009-02-01")
end_date = Date.parse("2009-02-17")
while(date < end_date)
  add_activity_for(date.to_s)
  date = date.next
end

save_activity

puts @activity.inspect



