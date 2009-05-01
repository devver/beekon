require 'rubygems'
require 'lighthouse-api'
require 'yaml/store'
require 'main'
require 'ruby-debug'

module Beekon

  class TicketsClosed
    
    def initialize(project,start_date,end_date)
      @project = project
      @start_date = start_date
      @end_date = end_date
    end

    def print_summary
      puts "Weekly summary from #{@start_date.inspect} to #{@end_date.inspect}"
      puts "  day             || tickets closed "
      puts "============================"
      total = 0
      (@start_date..@end_date).each do |date|
        closed = closed_on(date).length
        total += closed
        puts "#{date.inspect} :: #{closed}"
      end
      puts "============================"
      puts "Total: #{total}"
    end
    
    def closed_on(date)
      @project.tickets(:q => "state:closed updated:'#{date.strftime('%m/%d/%Y')}'")
    end
    
  end
end

Main do
  CONFIG_FILE = 'beekon.cfg'
  
  def with_project
    store = YAML::Store.new(File.join(Dir.pwd,CONFIG_FILE.to_s))
    store.transaction do
      Lighthouse.account = store['account']
      Lighthouse.token = store['api-token']
      project = Lighthouse::Project.find(store['project-id'])
      yield(project)
    end
  end

  def run
    with_project do |project|
      Beekon::TicketsClosed.new(project,Date.today-7,Date.today).print_summary
    end
  end
end


