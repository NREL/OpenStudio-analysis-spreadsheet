# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

require 'erb'

#start the measure
class HVACPsychrometricChart < OpenStudio::Ruleset::ReportingUserScript

  # human readable name
  def name
    return "HVAC Psychrometric Chart"
  end

  # human readable description
  def description
    return "A psychrometric chart shows the relationship between air temperature and humidity conditions."
  end

  # human readable description of modeling approach
  def modeler_description
    return "WARNING: the report takes a long time to render (can be several minutes!) in the OpenStudio App.  Open it in a web browser if this is too slow for you. Creates a psychrometric chart in SI units that shows the air conditions at each node on the supply side of the selected air loop.  These conditions are obtained by requesting hourly temperature and humidity for these specific nodes.  "
  end

  # define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # make an argument for air loop
    air_loop_name = OpenStudio::Ruleset::OSArgument::makeStringArgument("air_loop_name", true)
    air_loop_name.setDisplayName("Air Loop Name")
    air_loop_name.setDescription("The name of an Air Loop to create a psychrometric chart for.  Case sensitive.")
    args << air_loop_name

    return args
  end 
  
  # helper method
  def node_names(air_loop)
    
    res = {}
    res['supply_inlet']
    res['supply_outlet']
    res['mixed_air']
  
  end
  
  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)
    
    result = OpenStudio::IdfObjectVector.new
    
    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(), user_arguments)
      return result
    end
    
    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      puts "Cannot find last model"
      runner.registerError("Cannot find last model.")
      return result
    end
    model = model.get    
    
    # Get the named air loop
    air_loop = nil
    air_loop_name = runner.getStringArgumentValue("air_loop_name",user_arguments)
    air_loop = model.getAirLoopHVACByName(air_loop_name)
    if air_loop.is_initialized
      air_loop = air_loop.get
    else
      runner.registerError("No air loop called '#{air_loop_name}' was found in the model. It may have been removed by another measure, or you may have typed the name wrong.")
      return result
    end
 
    # Request the dry bulb temperature and humidity ratio for each node
    # on the supply side of the air loop.
    air_loop.supplyComponents.each do |sup_comp|
      next unless sup_comp.to_Node.is_initialized
      node = sup_comp.to_Node.get
      result << OpenStudio::IdfObject.load("Output:Variable,#{node.name.get},System Node Temperature,hourly;").get
      result << OpenStudio::IdfObject.load("Output:Variable,#{node.name.get},System Node Humidity Ratio,hourly;").get
    end
    
    # Request Outdoor air dry bulb and humidity ratio
    result << OpenStudio::IdfObject.load("Output:Variable,*,Site Outdoor Air Drybulb Temperature,Hourly;").get
    result << OpenStudio::IdfObject.load("Output:Variable,*,Site Outdoor Air Humidity Ratio,hourly;").get

    return result
    
  end
  
  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    sql = runner.lastEnergyPlusSqlFile
    if sql.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sql = sql.get
    model.setSqlFile(sql)

    # Get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sql.availableEnvPeriods.each do |env_pd|
      env_type = sql.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          ann_env_pd = env_pd
        end
      end
    end

    if ann_env_pd == false
      runner.registerError("Can't find a weather runperiod, make sure you ran an annual simulation, not just the design days.")
      return false
    end
    
    # Get the named air loop
    air_loop = nil
    air_loop_name = runner.getStringArgumentValue("air_loop_name",user_arguments)
    air_loop = model.getAirLoopHVACByName(air_loop_name)
    if air_loop.is_initialized
      air_loop = air_loop.get
    else
      runner.registerError("No air loop called '#{air_loop_name}' was found in the model. It may have been removed by another measure, or you may have typed the name wrong.")
      return result
    end     
    
    # Method to translate from OpenStudio's time formatting
    # to Javascript time formatting
    # OpenStudio time
    # 2009-May-14 00:10:00   Raw string
    # Javascript time
    # 2009/07/12 12:34:56
    def to_JSTime(os_time)
      js_time = os_time.to_s
      # Replace the '-' with '/'
      js_time = js_time.gsub('-','/')
      # Replace month abbreviations with numbers
      js_time = js_time.gsub('Jan','01')
      js_time = js_time.gsub('Feb','02')
      js_time = js_time.gsub('Mar','03')
      js_time = js_time.gsub('Apr','04')
      js_time = js_time.gsub('May','05')
      js_time = js_time.gsub('Jun','06')
      js_time = js_time.gsub('Jul','07')
      js_time = js_time.gsub('Aug','08')
      js_time = js_time.gsub('Sep','09')
      js_time = js_time.gsub('Oct','10')
      js_time = js_time.gsub('Nov','11')
      js_time = js_time.gsub('Dec','12')
      
      return js_time

    end     
    
    # Create a new series like this
    # for each condition series we want to plot
    # {"name" : "series 1",
    # "color" : "purple",
    # "data" :[{ "tdb": 20, "w": 0.015, "time": "2009/07/12 12:34:56"},
            # { "tdb": 25, "w": 0.008, "time": "2009/07/12 12:34:56"},
            # { "tdb": 30, "w": 0.005, "time": "2009/07/12 12:34:56"}]
    # }
    all_series = []

    # Outdoor Air
    
    # Get the hourly annual dry bulb temp
    tdb_timeseries = sql.timeSeries(ann_env_pd, "Hourly", "Site Outdoor Air Drybulb Temperature","Environment")

    # Get the hourly annual humidity ratio
    w_timeseries = sql.timeSeries(ann_env_pd, "Hourly", "Site Outdoor Air Humidity Ratio","Environment")
 
    # Store the data if it exists
    if tdb_timeseries.is_initialized && w_timeseries.is_initialized
      tdb_vals = tdb_timeseries.get.values
      w_vals = w_timeseries.get.values
      
      # Convert time stamp format to be more readable
      js_date_times = []
      tdb_timeseries.get.dateTimes.each do |date_time|
        js_date_times << to_JSTime(date_time)
      end    
      
      # Store the timeseries data to hash for later
      # export to the HTML file
      series = {}
      series["name"] = "Outdoor Air"
      series["color"] = "blue"
      data = []
      for i in 0..(js_date_times.size - 1)
        point = {}
        point["tdb"] = tdb_vals[i].round(2)
        point["w"] = w_vals[i].round(4)
        point["time"] = js_date_times[i]
        data << point
      end
      series["data"] = data
      all_series << series
    end
  
    # Air Loop Node conditions

    air_loop_name = air_loop.name.get
    j = 0
    colors = ['red','green','orange','purple','cyan','mangenta']
    
    runner.registerInfo("Getting psychrometric data for #{air_loop_name}.")

    # Get the dry bulb temperature and humidity ratio for each node
    # on the supply side of the air loop.
    air_loop.supplyComponents.each do |sup_comp|
      next unless sup_comp.to_Node.is_initialized
      node = sup_comp.to_Node.get
      node_name = node.name.get

      prev_comp_name = node_name
      if node == air_loop.supplyInletNode
        prev_comp_name = "Return Air"
      elsif node == air_loop.supplyOutletNode
        prev_comp_name = "Supply Air"
      elsif node.inletModelObject.is_initialized
        prev_comp = node.inletModelObject.get
        prev_comp_name = "#{prev_comp.name.get} Outlet"
        if air_loop.airLoopHVACOutdoorAirSystem.is_initialized
          if  prev_comp == air_loop.airLoopHVACOutdoorAirSystem.get
            prev_comp_name = "Mixed Air"
          end
        end
      end

      # Get the hourly annual dry bulb temp
      tdb_timeseries = sql.timeSeries(ann_env_pd, "Hourly", "System Node Temperature",node_name.upcase)
      if tdb_timeseries.empty?
        runner.registerWarning("No hourly annual dry bulb temp found for '#{node_name}' on '#{air_loop_name}'")
        next
      else
        tdb_timeseries = tdb_timeseries.get
      end
      tdb_vals = tdb_timeseries.values
      
      # Get the hourly annual humidity ratio
      w_timeseries = sql.timeSeries(ann_env_pd, "Hourly", "System Node Humidity Ratio",node_name.upcase)
      if w_timeseries.empty?
        runner.registerWarning("No hourly annual humidity ratio found for '#{node_name}' on '#{air_loop_name}'")
        next
      else
        w_timeseries = w_timeseries.get
      end 
      w_vals = w_timeseries.values      
      
      # Convert time stamp format to be more readable
      js_date_times = []
      tdb_timeseries.dateTimes.each do |date_time|
        js_date_times << to_JSTime(date_time)
      end    
      
      # Store the timeseries data to hash for later
      # export to the HTML file
      series = {}
      series["name"] = "#{prev_comp_name}"
      series["color"] = colors[j]
      data = []
      for i in 0..(js_date_times.size - 1)
        point = {}
        point["tdb"] = tdb_vals[i].round(2)
        point["w"] = w_vals[i].round(4)
        point["time"] = js_date_times[i]
        data << point
      end
      series["data"] = data
      all_series << series        
        
      # increment color selection
      j += 1  
        
    end
        
    # Convert all_series to JSON.
    # This JSON will be substituted
    # into the HTML file.
    require 'json'
    all_series = all_series.to_json
    
    # read in template
    html_in_path = "#{File.dirname(__FILE__)}/resources/report.html.erb"
    if File.exist?(html_in_path)
        html_in_path = html_in_path
    else
        html_in_path = "#{File.dirname(__FILE__)}/report.html.erb"
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

    # close the sql file
    sql.close()

    return true
 
  end

end

# register the measure to be used by the application
HVACPsychrometricChart.new.registerWithApplication
