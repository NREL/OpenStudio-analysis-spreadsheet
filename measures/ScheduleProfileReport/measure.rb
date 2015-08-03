require 'erb'

#start the measure
class ScheduleProfileReport < OpenStudio::Ruleset::ReportingUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return " Schedule Profile Report"
  end
  
  #define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # get the last model and sql file

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    web_asset_path = OpenStudio::getSharedResourcesPath() / OpenStudio::Path.new("web_assets")

    # pass into html
    graph_hash = {} # graph title, graph data

    temp_counter = 0
    model.getSchedules.sort.each do |schedule|
      next if !schedule.to_ScheduleRuleset.is_initialized
      next if temp_counter > 3 # this is just to test first schedule
      schedule = schedule.to_ScheduleRuleset.get

      # array to hold profiles
      profiles = []

      # get default profile
      profiles << [schedule.defaultDaySchedule,"default profile"]

      # get design days
      summer_design = schedule.summerDesignDaySchedule
      profiles << [summer_design,"summer design day"]
      winter_design = schedule.winterDesignDaySchedule
      profiles << [winter_design,"winter design day"]

      # get rules
      schedule.scheduleRules.each do |rule|

        # add days of week to text
        if rule.applySunday then sun = "Sun" else sun = "" end
        if rule.applyMonday then mon = "Mon" else mon = "" end
        if rule.applyTuesday then tue = "Tue" else tue = "" end
        if rule.applyWednesday then wed = "Wed" else wed = "" end
        if rule.applyThursday then thu = "Thu" else thu = "" end
        if rule.applyFriday then fri = "Fri" else fri = "" end
        if rule.applySaturday then sat = "Sat" else sat = "" end

        # add dates to text
        if rule.startDate.is_initialized
          date = rule.startDate.get
          start = date
        else
          start = ""
        end
        if rule.endDate.is_initialized
          date = rule.endDate.get
          finish = date
        else
          finish = ""
        end

        text = "(#{sun}#{mon}#{tue}#{wed}#{thu}#{fri}#{sat}) #{start}-#{finish}"
        profiles << [rule.daySchedule,text]
      end

      # store data for a single graph
      data = []

      # temp test of profiles
      profile_counter = -2
      profiles.each do |array|

        profile = array[0]
        text = array[1]

        if profile_counter == -2
          name = " #{text} - #{schedule.name}"
        elsif profile_counter < 1
          name = " #{text}"
        else
          name = "Priority #{profile_counter} - #{text}"
        end


        # update counter
        profile_counter += 1

        times = profile.times
        values = profile.values
        (1..times.size).each do |index|
          # add for this index value
          time_double = times[index-1].hours + times[index-1].minutes/60.0
          value = values[index-1]
          #data << "{\"Type\":\"#{name}\",\"Time\":\"#{time_double}\",\"Value\":\"#{value}\"}"
        end

        # get datapoint every 15min (doing this because I could get step to work)
        (1..24).each do |i|

          fractional_hours = i/1.0

          hr = fractional_hours.truncate
          min = ((fractional_hours - fractional_hours.truncate)*60.0).truncate

          time = OpenStudio::Time.new(0,hr,min, 0)
          val = profile.getValue(time)

          data << "{\"Type\":\"#{name}\",\"Time\":\"#{fractional_hours}\",\"Value\":\"#{val}\"}"
        end

      end

      temp_counter =+ 1

      graph_data = data.join(",")
      graph_hash[schedule.name] = data.join(",")

    end

    # read in template
    html_in_path = "#{File.dirname(__FILE__)}/resources/report.html.in"
    if File.exist?(html_in_path)
        html_in_path = html_in_path
    else
        html_in_path = "#{File.dirname(__FILE__)}/report.html.in"
    end
    html_in = ""
    File.open(html_in_path, 'r') do |file|
      html_in = file.read
    end

    # configure template with variable values
    renderer = ERB.new(html_in)
    html_out = renderer.result(binding)

    # write html file
    html_out_path = "./report.html"
    File.open(html_out_path, 'w') do |file|
      file << html_out
      # make sure data is written to the disk one way or the other      
      begin
        file.fsync
      rescue
        file.flush
      end
    end

    #reporting final condition
    runner.registerFinalCondition("Finished generating report.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ScheduleProfileReport.new.registerWithApplication