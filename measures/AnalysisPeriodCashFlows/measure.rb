require 'erb'

#start the measure
class AnalysisPeriodCashFlows < OpenStudio::Ruleset::ReportingUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AnalysisPeriodCashFlows"
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
    
    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    # put data into variables, these are available in the local scope binding

    output =  "<br>&nbsp&nbspMeasure Name = " << name << "<br><br>"

    #inflation approach
    inf_appr_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Life-Cycle Cost Parameters' AND RowName='Inflation Approach' AND ColumnName='Value'"
    inf_appr = sqlFile.execAndReturnFirstString(inf_appr_query)
    if inf_appr.is_initialized
      if inf_appr.get == "ConstantDollar"
        inf_appr = "Constant Dollar"
      elsif inf_appr.get == "CurrentDollar"
        inf_appr = "Current Dollar"
      else
        runner.registerError("Inflation approach: #{inf_appr.get} not recognized")
        return false
      end
      runner.registerInfo("Inflation approach = #{inf_appr}")
    else
      runner.registerError("Could not determine inflation approach used")
      return false
    end

    #base year
    base_yr_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Life-Cycle Cost Parameters' AND RowName='Base Date' AND ColumnName='Value'"
    base_yr = sqlFile.execAndReturnFirstString(base_yr_query)
    if base_yr.is_initialized
      if base_yr.get.match(/\d\d\d\d/)
        base_yr = base_yr.get.match(/\d\d\d\d/)[0].to_f
      else
        runner.registerError("Could not determine the analysis start year from #{base_yr.get}")
        return false
      end
    else
      runner.registerError("Could not determine analysis start year")
      return false
    end

    #analysis length
    length_yrs_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Life-Cycle Cost Parameters' AND RowName='Length of Study Period in Years' AND ColumnName='Value'"
    length_yrs = sqlFile.execAndReturnFirstInt(length_yrs_query)
    if length_yrs.is_initialized
      length_yrs = length_yrs.get
      runner.registerInitialCondition("Analysis length = #{length_yrs} yrs")
    else
      runner.registerError("Could not determine analysis length")
      return false
    end

    #cash flows
    cash_flow_elems = OpenStudio::AttributeVector.new

    #setup a vector for each type of cash flow
    cap_cash_flow_elems = OpenStudio::AttributeVector.new
    om_cash_flow_elems = OpenStudio::AttributeVector.new
    energy_cash_flow_elems = OpenStudio::AttributeVector.new
    water_cash_flow_elems = OpenStudio::AttributeVector.new
    tot_cash_flow_elems = OpenStudio::AttributeVector.new

    #add the type to the element
    cap_cash_flow_elems << OpenStudio::Attribute.new("type", "#{inf_appr} Capital Costs")
    om_cash_flow_elems << OpenStudio::Attribute.new("type", "#{inf_appr} Operating Costs")
    energy_cash_flow_elems << OpenStudio::Attribute.new("type", "#{inf_appr} Energy Costs")
    water_cash_flow_elems << OpenStudio::Attribute.new("type", "#{inf_appr} Water Costs")
    tot_cash_flow_elems << OpenStudio::Attribute.new("type", "#{inf_appr} Total Costs")

    #record the cash flow in these hashes
    cap_cash_flow = {}
    om_cash_flow = {}
    energy_cash_flow = {}
    water_cash_flow = {}
    tot_cash_flow = {}

    data_cashFlow = []
    data_running_total = []
    running_total = 0

    #loop through each year and record the cash flow
    for i in 0..(length_yrs - 1) do
      new_yr = base_yr + i
      yr = "January           #{new_yr.round}"
      ann_cap_cash = 0.0
      ann_om_cash = 0.0
      ann_energy_cash = 0.0
      ann_water_cash = 0.0
      ann_tot_cash = 0.0

      #capital cash flow
      cap_cash_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Capital Cash Flow by Category (Without Escalation)' AND RowName='#{yr}' AND ColumnName='Total'"
      cap_cash = sqlFile.execAndReturnFirstDouble(cap_cash_query)
      if cap_cash.is_initialized
        ann_cap_cash += cap_cash.get
        ann_tot_cash += cap_cash.get
      end

      #o&m cash flow (excluding utility costs)
      om_types = ["Maintenance", "Repair","Operation", "Replacement", "MinorOverhaul", "MajorOverhaul", "OtherOperational"]
      om_types.each do |om_type|
        om_cash_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Operating Cash Flow by Category (Without Escalation)' AND RowName='#{yr}' AND ColumnName='#{om_type}'"
        om_cash = sqlFile.execAndReturnFirstDouble(om_cash_query)
        if om_cash.is_initialized
          ann_om_cash += om_cash.get
          ann_tot_cash += om_cash.get
        end
      end

      #energy cash flow
      energy_cash_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Operating Cash Flow by Category (Without Escalation)' AND RowName='#{yr}' AND ColumnName='Energy'"
      energy_cash = sqlFile.execAndReturnFirstDouble(energy_cash_query)
      if energy_cash.is_initialized
        ann_energy_cash += energy_cash.get
        ann_tot_cash += energy_cash.get
      end

      #water cash flow
      water_cash_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Operating Cash Flow by Category (Without Escalation)' AND RowName='#{yr}' AND ColumnName='Water'"
      water_cash = sqlFile.execAndReturnFirstDouble(water_cash_query)
      if water_cash.is_initialized
        ann_water_cash += water_cash.get
        ann_tot_cash += water_cash.get
      end

      #log the values for this year
      cap_cash_flow[yr] = ann_cap_cash
      om_cash_flow[yr] = ann_om_cash
      energy_cash_flow[yr] = ann_energy_cash
      water_cash_flow[yr] = ann_water_cash
      tot_cash_flow[yr] = ann_tot_cash

      # push annual values to output
      data_cashFlow << "{\"Type\":\"Building\",\"Year\":\"#{yr}\",\"Cash Flow\":#{ann_cap_cash+ann_om_cash}}" # combined Capital and O&M cost

      #data_cashFlow << "{\"Type\":\"Capital\",\"Year\":\"#{yr}\",\"Cash Flow\":#{ann_cap_cash}}"
      #data_cashFlow << "{\"Type\":\"O&M\",\"Year\":\"#{yr}\",\"Cash Flow\":#{ann_om_cash}}"
      data_cashFlow << "{\"Type\":\"Energy\",\"Year\":\"#{yr}\",\"Cash Flow\":#{ann_energy_cash}}"
      data_cashFlow << "{\"Type\":\"Water\",\"Year\":\"#{yr}\",\"Cash Flow\":#{ann_water_cash}}"

      # gather running total data for line plot
      running_total += ann_tot_cash
      data_running_total << "{\"Year\":\"#{yr}\",\"Cash Flow\":#{running_total}}"

      cap_cash_flow_elems << OpenStudio::Attribute.new("year", ann_cap_cash, "dollars")
      om_cash_flow_elems << OpenStudio::Attribute.new("year", ann_om_cash, "dollars")
      energy_cash_flow_elems << OpenStudio::Attribute.new("year", ann_energy_cash, "dollars")
      water_cash_flow_elems << OpenStudio::Attribute.new("year", ann_water_cash, "dollars")
      tot_cash_flow_elems << OpenStudio::Attribute.new("year", ann_tot_cash, "dollars")

    end #next year

    #data for report_html.in
    data_cashFlow_merge = data_cashFlow.join(",")
    data_running_total_merge = data_running_total.join(",")

    #end cash flows
    cash_flow_elems << OpenStudio::Attribute.new("cash_flow", cap_cash_flow_elems)
    cash_flow_elems << OpenStudio::Attribute.new("cash_flow", om_cash_flow_elems)
    cash_flow_elems << OpenStudio::Attribute.new("cash_flow", energy_cash_flow_elems)
    cash_flow_elems << OpenStudio::Attribute.new("cash_flow", water_cash_flow_elems)
    cash_flow_elems << OpenStudio::Attribute.new("cash_flow", tot_cash_flow_elems)

    result_elems = []
    result_elems << OpenStudio::Attribute.new("cash_flows", cash_flow_elems)
    
    web_asset_path = OpenStudio::getSharedResourcesPath() / OpenStudio::Path.new("web_assets")

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

    #closing the sql file
    sqlFile.close()

    #reporting final condition
    runner.registerFinalCondition("Finished generating report.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AnalysisPeriodCashFlows.new.registerWithApplication