#!/usr/bin/env ruby
#
# Script to set all "fixed" Lighthouse tickets to deployed
 
require 'ruby-debug'
require 'lighthouse-api'
require 'yaml'
 
CONFIG_FILE = 'finish_milestone.yml'
config = YAML.load_file(CONFIG_FILE)

current_milestone_title = 'Publicity Launch'
new_milestone_title = 'closed beta'

Lighthouse.account = config['account'] # put your account name in here
Lighthouse.token = config['api-token'] # put your API token here

project = Lighthouse::Project.find(config['project-id']) # replace with your project's ID

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

def tickets_to_move(project,milestone)
  # I think it's more efficient to do this like so:
  ## (for some reason, searching for 'open' tickets returns both 'open' and 'new' tickets)
  tickets = project.tickets(:q => "milestone_id:'#{milestone.id}' state:open ")
  # but it seems that lighthouse caches the results for queries like this, so I can't 
  # go through more than 30 tickets
  #tickets = milestone.tickets.select{|ticket| ticket.state=='open' || ticket.state=='new'}
  if(tickets.empty?)
    puts "No more tickets in '#{milestone.title}' to move"
  else
    puts "Moving #{tickets.length} tickets in '#{milestone.title}'"
  end
  tickets
end

tickets = tickets_to_move(project,current_milestone)
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
  tickets = tickets_to_move(project,current_milestone)
end

#ticket = tickets_to_move(current_milestone).first 
#puts ticket.id
#ticket.milestone_id=new_milestone.id
#ticket.save


