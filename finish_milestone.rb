#!/usr/bin/env ruby

require 'ruby-debug'
require 'lighthouse-api'
require 'yaml'

CONFIG_FILE = 'finish_milestone.yml'
config = YAML.load_file(CONFIG_FILE)

current_milestone_title = 'Publicity Launch'
new_milestone_title = 'closed beta'

Lighthouse.account = config['account'] 
Lighthouse.token = config['api-token'] 

project = Lighthouse::Project.find(config['project-id']) 

milestones = project.milestones
current_milestone = milestones.select {|milestone| milestone.title==current_milestone_title}.first
new_milestone = milestones.select {|milestone| milestone.title==new_milestone_title}.first

if(current_milestone==nil)
  puts "There is no milestone titled '#{current_milestone_title}'. Quitting."
  exit 1
end
if(new_milestone==nil)
  puts "There is no milestone titled '#{new_milestone_title}'. Quitting."
  exit 1
end

def tickets_to_move(project,milestone,page=1)
  # for some reason, searching for 'open' tickets returns both 'open' and 'new' tickets
  tickets = project.tickets(:q => "milestone_id:'#{milestone.id}' state:open", :page => page)
  if(tickets.empty?)
    puts "No more tickets in '#{milestone.title}' to move"
  else
    puts "Moving #{tickets.length} tickets in '#{milestone.title}'"
  end
  tickets
end

page = 1
tickets = tickets_to_move(project,current_milestone,page)
# You get a hard limit of 30 tickets on each query, so we have to do this repeatedly until nothing is returned
while(tickets!=[]) do
  tickets.each do |ticket|
    print "Moving #{ticket.number} to milestone '#{new_milestone.title}' ... "
    if ticket.closed
      raise "Error: We should not be moving closed tickets. Something is wrong with the ticket query."
    end
    ticket.milestone_id = new_milestone.id
    ticket.save
    puts "done."
  end
  page += 1
  tickets = tickets_to_move(project,current_milestone,page)
end



