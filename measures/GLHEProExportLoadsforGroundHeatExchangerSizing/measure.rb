require 'erb'

# Patch an array sum method into Ruby187
class Array
    def sum
        self.inject{|sum,x| sum + x }
    end
end

#start the measure
class GLHEProExportLoadsforGroundHeatExchangerSizing < OpenStudio::Ruleset::ReportingUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "GLHEProExportLoadsforGroundHeatExchangerSizing"
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

    # Get the model and sql file
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
    
    # Get the weather file (as opposed to design day) run period
    annEnvPd = nil
    sql.availableEnvPeriods.each do |envPd|
      envType = sql.environmentType(envPd)
      if not envType.empty?
        if envType.get == "WeatherRunPeriod".to_EnvironmentType
          annEnvPd = envPd
        end  
      end
    end

    # Find the names of all plant loops in the model that contain both a 
    # district heating and district cooling object
    loop_names = []
    model.getPlantLoops.each do |loop|
      runner.registerInfo("Checking '#{loop.name}' for district heating and district cooling.")
      dist_htg_name = nil
      dist_clg_name = nil
      loop.supplyComponents.each do |sc|
        if sc.to_DistrictHeating.is_initialized
          dist_htg_name = sc.name.get
        elsif sc.to_DistrictCooling.is_initialized
          dist_clg_name = sc.name.get
        end    
      end # Next supply component

      if dist_htg_name and dist_clg_name
        loop_names << [loop.name.get, dist_htg_name, dist_clg_name]     
      end
      
    end # Next loop

    # Report any loops that were found that appear to be
    # GLHE loops
    if loop_names.size == 0
      runner.registerInfo("No loops found with both district heating and district cooling.")
    else
      runner.registerInfo("Loops with district heating and district cooling: #{loop_names.join(',')}.")
    end
      
    # Define the start and end day for each month
    months = {}
    months[1] = [OpenStudio::Date.new(OpenStudio::MonthOfYear.new("January"), 1),
                OpenStudio::Date.new(OpenStudio::MonthOfYear.new("January"), 31)]
                
    months[2] = [OpenStudio::Date.new(OpenStudio::MonthOfYear.new("February"), 1),
                OpenStudio::Date.new(OpenStudio::MonthOfYear.new("February"), 28)]
              
    months[3] = [OpenStudio::Date.new(OpenStudio::MonthOfYear.new("March"), 1),
                OpenStudio::Date.new(OpenStudio::MonthOfYear.new("March"), 31)]
              
    months[4] = [OpenStudio::Date.new(OpenStudio::MonthOfYear.new("April"), 1),
                OpenStudio::Date.new(OpenStudio::MonthOfYear.new("April"), 30)]          

    months[5] = [OpenStudio::Date.new(OpenStudio::MonthOfYear.new("May"), 1),
                OpenStudio::Date.new(OpenStudio::MonthOfYear.new("May"), 31)]            
              
    months[6] = [OpenStudio::Date.new(OpenStudio::MonthOfYear.new("June"), 1),
                OpenStudio::Date.new(OpenStudio::MonthOfYear.new("June"), 30)]            

    months[7] = [OpenStudio::Date.new(OpenStudio::MonthOfYear.new("July"), 1),
                OpenStudio::Date.new(OpenStudio::MonthOfYear.new("July"), 31)]  
              
    months[8] = [OpenStudio::Date.new(OpenStudio::MonthOfYear.new("August"), 1),
                OpenStudio::Date.new(OpenStudio::MonthOfYear.new("August"), 31)]  

    months[9] = [OpenStudio::Date.new(OpenStudio::MonthOfYear.new("September"), 1),
                OpenStudio::Date.new(OpenStudio::MonthOfYear.new("September"), 30)]  

    months[10] = [OpenStudio::Date.new(OpenStudio::MonthOfYear.new("October"), 1),
                OpenStudio::Date.new(OpenStudio::MonthOfYear.new("October"), 31)]  

    months[11] = [OpenStudio::Date.new(OpenStudio::MonthOfYear.new("November"), 1),
                OpenStudio::Date.new(OpenStudio::MonthOfYear.new("November"), 30)]  

    months[12] = [OpenStudio::Date.new(OpenStudio::MonthOfYear.new("December"), 1),
                OpenStudio::Date.new(OpenStudio::MonthOfYear.new("December"), 31)]            

    # Define the start and end time for each day            
    start_time = OpenStudio::Time.new(0, 0, 0, 0)
    end_time = OpenStudio::Time.new(0, 24, 0, 0)

    # Get the heating and cooling loads for each loop
    # in hourly resolution for reporting, monthly resolution for GLHEPro
    annualGraphData = []
    monthlyTableData = []
    loop_names.each do |loop_name, dist_htg_name, dist_clg_name|
      runner.registerInfo("Getting monthly load data for #{loop_name}.")

      # Get the hourly annual heating load in Watts 
      ann_hourly_htg_w = sql.timeSeries(annEnvPd, "Hourly", "District Heating Rate",dist_htg_name.upcase)
      if ann_hourly_htg_w.empty?
        runner.registerWarning("No hourly heating data found for '#{dist_htg_name}' on '#{loop_name}'")
        next
      else
        ann_hourly_htg_w = ann_hourly_htg_w.get
      end
      
      # Get the hourly annual cooling load in Watts
      ann_hourly_clg_w = sql.timeSeries(annEnvPd, "Hourly", "District Cooling Rate",dist_clg_name.upcase)
      if ann_hourly_clg_w.empty?
        runner.registerWarning("No hourly cooling data found for '#{dist_clg_name}' on '#{loop_name}'")
        next
      else
        ann_hourly_clg_w = ann_hourly_clg_w.get
      end

      # Convert time stamp format to be more readable
      js_date_times = []
      ann_hourly_htg_w.dateTimes.each do |date_time|
        js_date_times << to_JSTime(date_time)
      end    
      
      # Convert the hourly heating load from W to Btu/hr
      ann_hourly_htg_btu_per_hr_vals = []
      ann_hourly_htg_w_vals = ann_hourly_htg_w.values
      for i in 0..(ann_hourly_htg_w_vals.size - 1)
        htg_w = ann_hourly_htg_w_vals[i]
        htg_btu_per_hr = OpenStudio::convert(htg_w,"W","kBtu/hr").get
        ann_hourly_htg_btu_per_hr_vals << htg_btu_per_hr
      end
      
      # Convert the hourly cooling load from W to Btu/hr
      ann_hourly_clg_btu_per_hr_vals = []
      ann_hourly_clg_w_vals = ann_hourly_clg_w.values
      for i in 0..(ann_hourly_clg_w_vals.size - 1)
        clg_w = ann_hourly_clg_w_vals[i]
        clg_btu_per_hr = OpenStudio::convert(clg_w,"W","kBtu/hr").get
        ann_hourly_clg_btu_per_hr_vals << clg_btu_per_hr
      end

      # Create an array of arrays [timestamp, htg_btu_per_hr, clg_btu_per_hr]
      hourly_vals = js_date_times.zip(ann_hourly_htg_btu_per_hr_vals, ann_hourly_clg_btu_per_hr_vals)

      # Add the hourly load data to JSON for the report.html
      graph = {}
      graph["title"] = "#{loop_name} - Hourly Heating and Cooling Power"
      graph["xaxislabel"] = "Time"
      graph["yaxislabel"] = "Power (kBtu/hr)"
      graph["labels"] = ["Date", "Heating", "Cooling"]
      graph["colors"] = ["#FF5050", "#0066FF"]      
      graph["timeseries"] = hourly_vals
    
      # This measure requires ruby 2.0.0 to create the JSON for the report graph
      if RUBY_VERSION >= "2.0.0"
        annualGraphData << graph
      end

      # Save out hourly load data to CSV
      File.open("./Annual Hourly Loads for #{loop_name}.csv", 'w') do |file|
        file.puts "Annual Hourly Loads for #{loop_name}"
        file.puts "Date/Time,Heating (kBtu/hr),Cooling (kBtu/hr)"
        hourly_vals.each do |timestamp, htg_btu_per_hr, clg_btu_per_hr|
          file.puts "#{timestamp},#{htg_btu_per_hr},#{clg_btu_per_hr}"
        end
      end
      
      # Find monthly loads for GLHEPro
      mon_htg_cons = []
      mon_clg_cons = []
      mon_htg_dmd = []
      mon_clg_dmd = []
      
      # Loop through months and find total heating and cooling energy
      # and peak heating and cooling rate for each month
      # and store in arrays defined above
      (1..12).each do |i|
        
        # Create the start and end date/time for the month
        start_date = months[i][0]
        end_date = months[i][1]
        start_t = OpenStudio::DateTime.new(start_date, start_time)
        end_t = OpenStudio::DateTime.new(end_date, end_time)
        runner.registerInfo("Month #{i}: #{start_t} to #{end_t}.")
        
        # Determine the monthly heating information
        mon_hourly_htg_w = ann_hourly_htg_w.values(start_t,end_t)
        if mon_hourly_htg_w.size == 0
          runner.registerWarning("No heating data for #{start_t} to #{end_t}, check the run period of your simulation.")
          next
        end
        mon_hourly_htg_w_arr = []
        for i in 0..(mon_hourly_htg_w.size - 1)
          mon_hourly_htg_w_arr << mon_hourly_htg_w[i].to_f
        end
        mon_htg_cons_w_hr = mon_hourly_htg_w_arr.sum
        mon_htg_cons_kBtu = OpenStudio::convert(mon_htg_cons_w_hr,"W*hr","kBtu").get
        mon_htg_peak_dmd_w = mon_hourly_htg_w_arr.max
        mon_htg_peak_dmd_Btu_hr = OpenStudio::convert(mon_htg_peak_dmd_w,"W","Btu/hr").get
        
        # Determine the monthly cooling information
        mon_hourly_clg_w = ann_hourly_clg_w.values(start_t,end_t)
        if mon_hourly_clg_w.size == 0
          runner.registerWarning("No cooling data for #{start_t} to #{end_t}, check the run period of your simulation.")
          next
        end
        mon_hourly_clg_w_arr = []
        for i in 0..(mon_hourly_clg_w.size - 1)
          mon_hourly_clg_w_arr << mon_hourly_clg_w[i].to_f
        end
        mon_clg_cons_w_hr = mon_hourly_clg_w_arr.sum
        mon_clg_cons_kBtu = OpenStudio::convert(mon_clg_cons_w_hr,"W*hr","kBtu").get
        mon_clg_peak_dmd_w = mon_hourly_clg_w_arr.max
        mon_clg_peak_dmd_Btu_hr = OpenStudio::convert(mon_clg_peak_dmd_w,"W","Btu/hr").get

        # Report out the monthly values and add to the array
        runner.registerInfo("htg: #{mon_htg_cons_kBtu} kBtu, clg: #{mon_clg_cons_kBtu} kBtu, htg peak: #{mon_htg_peak_dmd_Btu_hr} Btu/hr, clg peak: #{mon_clg_peak_dmd_Btu_hr} Btu/hr.")
        mon_htg_cons << OpenStudio::toNeatString(mon_htg_cons_kBtu, 0, false).to_i
        mon_clg_cons << OpenStudio::toNeatString(mon_clg_cons_kBtu, 0, false).to_i
        mon_htg_dmd << OpenStudio::toNeatString(mon_htg_peak_dmd_Btu_hr, 0, false).to_i
        mon_clg_dmd << OpenStudio::toNeatString(mon_clg_peak_dmd_Btu_hr, 0, false).to_i
        
      end

      # Log the annual numbers
      ann_htg_cons = mon_htg_cons.sum
      ann_htg_cons = OpenStudio::toNeatString(ann_htg_cons, 0, false).to_i

      ann_clg_cons = mon_clg_cons.sum
      ann_clg_cons = OpenStudio::toNeatString(ann_clg_cons, 0, false).to_i
      
      ann_htg_dmd = mon_htg_dmd.max
      ann_htg_dmd = OpenStudio::toNeatString(ann_htg_dmd, 0, false).to_i
      
      ann_clg_dmd = mon_clg_dmd.max
      ann_clg_dmd = OpenStudio::toNeatString(ann_clg_dmd, 0, false).to_i
      
      runner.registerInfo("Annual energy and peak demand.")
      runner.registerInfo("htg: #{ann_clg_cons} kBtu, clg: #{ann_clg_cons} kBtu, htg peak: #{ann_htg_dmd} Btu/hr, clg peak: #{ann_clg_dmd} Btu/hr.")
      
      # Save the monthly load data for import into GLHEPro (.gt1)
      File.open("./Monthly Loads for #{loop_name}.gt1", 'w') do |file|
        file.puts "Clg/Htg Consumption (kBtu),"\
                  "#{mon_clg_cons.join(',')},"\
                  "#{ann_clg_cons},"\
                  "#{mon_htg_cons.join(',')},"\
                  "#{ann_htg_cons}"
        file.puts "Clg/Htg Demand (Btuh),"\
                  "#{mon_clg_dmd.join(',')},"\
                  "#{ann_clg_dmd},"\
                  "#{mon_htg_dmd.join(',')},"\
                  "#{ann_htg_dmd}"
      end
    
      monthlyTableData = []
      
      
 
    end # Next loop
     
    # Convert the graph data to JSON
    # This measure requires ruby 2.0.0 to create the JSON for the report graph
    if RUBY_VERSION >= "2.0.0"
      require 'json'
      annualGraphData = annualGraphData.to_json
    else
      runner.registerInfo("This Measure needs Ruby 2.0.0 to generate timeseries graphs on the report.  This does not impact the GLHEPro export at all.  You have Ruby #{RUBY_VERSION}.  OpenStudio 1.4.2 and higher user Ruby 2.0.0.")  
    end    
     
    # Read in the HTML report template
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

    # Configure HTML template with variable values
    renderer = ERB.new(html_in)
    html_out = renderer.result(binding)

    # Write out the HTML template
    html_out_path = "./report.html"
    File.open(html_out_path, 'w') do |file|
      file << html_out
      # Make sure HTML file is written to the disk one way or the other
      begin
        file.fsync
      rescue
        file.flush
      end
    end
     
    # Close the sql file
    sql.close

    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
GLHEProExportLoadsforGroundHeatExchangerSizing.new.registerWithApplication