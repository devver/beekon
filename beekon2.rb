require 'rubygems'
require 'lighthouse-api'
require 'yaml/store'
require 'main'
require 'ruby-debug'

module Beekon

  class TicketStats
    
    def initialize(project)
      @project = project
    end
    
    def closed_during(start_date,end_date)
      tickets_closed = []
      [start_date...end_date].each do |date|
        tickets_closed << closed_on(date)
      end
      tickets_closed
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
      puts Beekon::TicketStats.new(project).closed_on(Date.today).length
    end
  end
end


