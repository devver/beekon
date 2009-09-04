require 'rubygems'
require 'lighthouse-api'
require 'yaml/store'
require 'main'
require 'ruby-debug'

module Beekon

    def ticket_points(closed_tickets)
      points = 0
      closed_tickets.each do |ticket|
        if (ticket.attributes['tag'] && ticket.attributes['tag'] != '' && ticket.attributes['tag'].match(/[0-9]*pt/))
          points += ticket.attributes['tag'].match(/[0-9]*pt/).to_s.sub('pt','').to_i
        end
      end
      points
    end

    class TicketsMilestone
      include Beekon
    
      def initialize(project)
        @project = project
      end

      def print_points_summary(milestone)
        puts "Milestone current points summary"
        puts " points "
        puts "=" * 35
        total_points = ticket_points(tix_in_milestone(milestone))
        puts "#{total_points} pts"
        puts "=" * 35
      end

      def tix_in_milestone(milestone = 'current')
        @project.tickets(:q => "milestone:#{milestone}")
      end

    end

    class TicketsClosed
      include Beekon

      def initialize(project,start_date,end_date)
        @project = project
        @start_date = start_date
        @end_date = end_date
      end

      def print_summary
        puts "Weekly summary from #{@start_date.inspect} to #{@end_date.inspect}"
        puts " day   :: tickets closed  :: points closed"
        puts "=" * 35
        total = 0
        total_points = 0
        (@start_date..@end_date).each do |date|
          closed_tickets = closed_on(date)
          points = ticket_points(closed_tickets)
          closed = closed_tickets.length
          total += closed
          total_points += points
          puts "#{date.inspect} :: #{closed} :: #{points}pts"
        end
        puts "=" * 35
        puts "Total: #{total}    Total Points: #{total_points}"
      end
    
      def closed_on(date)
        @project.tickets(:q => "state:resolved updated:'#{date.strftime('%m/%d/%Y')}'")
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
      adjust = 0 # -1
      #Beekon::TicketsClosed.new(project,Date.today-6+adjust,Date.today+adjust).print_summary
      #Beekon::TicketsClosed.new(project,Date.parse("8/28/2009"),Date.parse("9/03/2009")).print_summary
      Beekon::TicketsMilestone.new(project).print_points_summary('09/10/09')
    end
  end
end


