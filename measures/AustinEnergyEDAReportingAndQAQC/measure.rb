require 'erb'
require 'json'
require 'openstudio-standards'

#start the measure
class AustinEnergyEDAReportingAndQAQC < OpenStudio::Ruleset::ReportingUserScript

  # require all .rb files in resources folder
  Dir[File.dirname(__FILE__) + '/resources/*.rb'].each {|file| require file }

  # all QAQC checks should be in OsLib_QAQC module
  include OsLib_QAQC
  include OsLib_CreateResults

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Austin Energy EDA Reporting and QAQC"
  end

  # human readable description
  def description
    return "This measure extracts key simulation results and performs basic model QAQC checks necessary for the Austin Energy EDA Program."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Reads the model and sql file to pull out the necessary information and run the model checks.  The check results show up as warning messages in the measure's output on the PAT run tab."
  end

  #define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end #end the arguments method

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    result = OpenStudio::IdfObjectVector.new

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(), user_arguments)
      return result
    end

    # get the last model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    # Request the terminal reheat coil and
    # terminal cooling rates for every VAV
    # reheat terminal.
    model.getAirTerminalSingleDuctVAVReheats.each do |term|

      # Reheat coil heating rate
      rht_coil = term.reheatCoil
      result << OpenStudio::IdfObject.load("Output:Variable,#{rht_coil.name},Heating Coil Heating Rate,Hourly;").get
      result << OpenStudio::IdfObject.load("Output:Variable,#{rht_coil.name},Heating Coil Air Heating Rate,Hourly;").get

      # Zone Air Terminal Sensible Heating Rate
      result << OpenStudio::IdfObject.load("Output:Variable,ADU #{term.name},Zone Air Terminal Sensible Cooling Rate,Hourly;").get

    end

    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)
    
    # make the runner a class variable
    @runner = runner
    
    # use the built-in error checking
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    runner.registerInitialCondition("Starting QAQC report generation")

    # get sql, model, and web assets
    setup = OsLib_Reporting.setup(runner)
    unless setup
      return false
    end
    @model = setup[:model]
    # workspace = setup[:workspace]
    @sql = setup[:sqlFile]
    web_asset_path = setup[:web_asset_path]

    # vector to store the results and checks
    time_a = Time.new
    report_elems = OpenStudio::AttributeVector.new
    report_elems << create_results #todo - comment this out for quick testing of checks
    time_b = Time.new
    delta_time = time_b.to_f - time_a.to_f
    runner.registerInfo("Gathering results: elapsed time #{delta_time.round(1)} seconds.")

    # utility name to to used by some qaqc checks
    @utility_name = "Austin Energy"
    default_target_standard = '90.1-2013'

    # MidriseApartment checks against Table R402.1.2 and R402.1.4 in ICC IECC 2015 Residential Provisions.
    residential_target_standard = 'ICC IECC 2015'

    # get building type, different standards path if multifamily
    building_type = ''
    if @model.getBuilding.standardsBuildingType.is_initialized
      building_type = @model.getBuilding.standardsBuildingType.get
    end

    # gather options_check_weather_files
    options_check_weather_files = {}
    mabry = {}
    mabry['climate_zone'] = '2A'
    options_check_weather_files['USA_TX_Austin-Camp.Mabry.722544_TMY3.epw'] = mabry
    mabry['summer'] = []
    mabry['summer'] << 'Camp Mabry Ann Clg .4% Condns DB=>MWB'
    mabry['summer'] << 'Camp Mabry Ann Clg .4% Condns DP=>MDB'
    mabry['summer'] << 'Camp Mabry Ann Clg .4% Condns Enth=>MDB'
    mabry['summer'] << 'Camp Mabry Ann Clg .4% Condns WB=>MDB'
    mabry['winter'] = []
    mabry['winter'] << 'Camp Mabry Ann Htg 99.6% Condns DB'
    mabry['winter'] << 'Camp Mabry Ann Htg Wind 99.6% Condns WS=>MCDB'
    mabry['winter'] << 'Camp Mabry Ann Hum_n 99.6% Condns DP=>MCDB'
    muller = {}
    muller['climate_zone'] = '2A'
    options_check_weather_files['USA_TX_Austin-Mueller.Muni.AP.722540_TMY3.epw'] = muller
    muller['summer'] = []
    muller['summer'] << 'Austin Mueller Municipal Ap Ann Clg .4% Condns DB=>MWB'
    muller['summer'] << 'Austin Mueller Municipal Ap Ann Clg .4% Condns DP=>MDB'
    muller['summer'] << 'Austin Mueller Municipal Ap Ann Clg .4% Condns Enth=>MDB'
    muller['summer'] << 'Austin Mueller Municipal Ap Ann Clg .4% Condns Enth=>MDB'
    muller['winter'] = []
    muller['winter'] << 'Austin Mueller Municipal Ap Ann Htg 99.6% Condns DB'
    muller['winter'] << 'Austin Mueller Municipal Ap Ann Htg Wind 99.6% Condns WS=>MCDB'
    muller['winter'] << 'Austin Mueller Municipal Ap Ann Hum_n 99.6% Condns DP=>MCDB'

    # gather inputs for check_mech_sys_capacity. Each option has a target value, min and max fractional tolerance, and units
    # in the future climate zone specific targets may be in standards
    options_check_mech_sys_capacity = {}
    options_check_mech_sys_capacity['chiller_max_flow_rate'] = {'target' => 2.4,'min' => 0.1, 'max' => 0.1,'units' => 'gal/ton*min'}
    options_check_mech_sys_capacity['air_loop_max_flow_rate'] = {'target' => 1.0,'min' => 0.1, 'max' => 0.1,'units' => 'cfm/ft^2'}
    options_check_mech_sys_capacity['air_loop_cooling_capacity'] = {'target' => 0.0033,'min' => 0.1, 'max' => 0.1,'units' => 'tons/ft^2'}
    options_check_mech_sys_capacity['zone_heating_capacity'] = {'target' => 12.5,'min' => 0.20, 'max' => 0.40,'units' => 'Btu/ft^2*h'}

    # create an attribute vector to hold the checks
    check_elems = OpenStudio::AttributeVector.new

    # call individual checks and add to vector
    check_elems << check_eui_reasonableness('General',default_target_standard,0.1,0.1) # two doubles define min and max fraction above or below target eui
    check_elems << check_weather_files('General',options_check_weather_files)
    check_elems << check_simultaneous_heating_and_cooling('General',0.05) # two doubles define max fraction simultaneous heating and coolin
    check_elems << check_eui_by_end_use('General',default_target_standard,0.25,0.25) # two doubles define min and max fraction above or below target eui
    check_elems << check_mech_sys_part_load_eff('General',default_target_standard,0.1,0.1) # two doubles define min and max fraction above or below target
    check_elems << check_mech_sys_capacity('General',options_check_mech_sys_capacity)
    if building_type == "MidriseApartment"
      check_elems << check_internal_loads('Baseline',residential_target_standard,1.0,0.1)
    else
      check_elems << check_internal_loads('Baseline',default_target_standard,0.1,0.1)
    end
    check_elems << check_schedules('Baseline',default_target_standard,0.05,0.05) # two doubles define min and max fraction above or below target
    check_elems << check_mech_sys_efficiency('Baseline',default_target_standard,0.1,0.1) # two doubles define min and max fraction above or below target
    check_elems << check_mech_sys_type('Baseline',default_target_standard)
    if building_type == "MidriseApartment"
      check_elems << check_envelope_conductance('Baseline',residential_target_standard,0.1,0.1) # two doubles define min and max fraction above or below target
    else
      check_elems << check_envelope_conductance('Baseline',default_target_standard,0.1,0.1) # two doubles define min and max fraction above or below target
    end
    if building_type == "MidriseApartment"
      check_elems << check_domestic_hot_water('Baseline',residential_target_standard,0.25,0.25) # two doubles define min and max fraction above or below target
    else
      check_elems << check_domestic_hot_water('Baseline',default_target_standard,0.25,0.25) # two doubles define min and max fraction above or below target
    end

    # ad checks to report_elems
    report_elems << OpenStudio::Attribute.new("checks", check_elems)

    # create an extra layer of report.  the first level gets thrown away.
    top_level_elems = OpenStudio::AttributeVector.new
    top_level_elems << OpenStudio::Attribute.new("report", report_elems)
    
    # create the report
    result = OpenStudio::Attribute.new("summary_report", top_level_elems)
    result.saveToXml(OpenStudio::Path.new("report.xml"))

    # closing the sql file
    @sql.close()

    # reporting final condition
    runner.registerFinalCondition("Finished generating report.xml.")

    # populate sections using attributes
    sections = OsLib_Reporting.sections_from_check_attributes(check_elems,runner)

    # generate html output
    OsLib_Reporting.gen_html("#{File.dirname(__FILE__)}report.html.erb",web_asset_path, sections, name)
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AustinEnergyEDAReportingAndQAQC.new.registerWithApplication