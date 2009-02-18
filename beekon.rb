require 'ruby-debug'
require 'hpricot'
require 'open-uri'
require 'yaml'

@config = YAML::load_file('config.yml')

def api_token
  @config['API_TOKEN']
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
  tickets_numbers = (document/"/tickets/ticket/number").map{|x| Integer(x.inner_html)}
end

def tickets_closed_on(date)
  url = tickets_url+"&q=updated:'#{date}'+state:closed"
  document = Hpricot(open(url))
  tickets_numbers = (document/"/tickets/ticket/number").map{|x| Integer(x.inner_html)}
end

def velocity_for(date)
  velocity = tickets_closed_on(date).length-tickets_created_on(date).length
end

puts velocity_for("2/17/2009")
puts "done"



