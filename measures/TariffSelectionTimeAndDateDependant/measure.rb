# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"

# start the measure
class TariffSelectionTimeAndDateDependant < OpenStudio::Ruleset::WorkspaceUserScript

  # human readable name
  def name
    return "Tariff Selection-Time and Date Dependant"
  end

  # human readable description
  def description
    return "This measure sets flat rates for gas, water, district heating, and district cooling but has on seasonal and off peak rates for electricity. It exposes inputs for the time of day and day of year where peak rates should be applied."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Will add the necessary UtilityCost objects and associated schedule into the model."
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make choice argument for facade
    choices = OpenStudio::StringVector.new
    choices << "QuarterHour"
    choices << "HalfHour"
    choices << "FullHour"
    # don't want to offer Day or Week even though valid E+ options
    # choices << "Day"
    # choices << "Week"
    demand_window_length = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("demand_window_length", choices,true)
    demand_window_length.setDisplayName("Demand Window Length.")
    demand_window_length.setDefaultValue("QuarterHour")
    args << demand_window_length

    # adding argument for summer_start_month
    summer_start_month = OpenStudio::Ruleset::OSArgument.makeIntegerArgument("summer_start_month", true)
    summer_start_month.setDisplayName("Month Summer Begins")
    summer_start_month.setDescription("1-12")
    summer_start_month.setDefaultValue(5)
    args << summer_start_month

    # adding argument for summer_start_day
    summer_start_day = OpenStudio::Ruleset::OSArgument.makeIntegerArgument("summer_start_day", true)
    summer_start_day.setDisplayName("Day Summer Begins")
    summer_start_day.setDescription("1-31")
    summer_start_day.setDefaultValue(1)
    args << summer_start_day

    # adding argument for summer_end_month
    summer_end_month = OpenStudio::Ruleset::OSArgument.makeIntegerArgument("summer_end_month", true)
    summer_end_month.setDisplayName("Month Summer Ends")
    summer_end_month.setDescription("1-12")
    summer_end_month.setDefaultValue(9)
    args << summer_end_month

    # adding argument for summer_end_day
    summer_end_day = OpenStudio::Ruleset::OSArgument.makeIntegerArgument("summer_end_day", true)
    summer_end_day.setDisplayName("Day Summer Ends")
    summer_end_day.setDescription("1-31")
    summer_end_day.setDefaultValue(1)
    args << summer_end_day

    # adding argument for peak_start_hour
    peak_start_hour = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("peak_start_hour", true)
    peak_start_hour.setDisplayName("Hour Peak Begins")
    peak_start_hour.setDescription("1-24")
    peak_start_hour.setDefaultValue(12)
    args << peak_start_hour

    # adding argument for peak_end_hour
    peak_end_hour = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("peak_end_hour", true)
    peak_end_hour.setDisplayName("Hour Peak Ends")
    peak_end_hour.setDescription("1-24")
    peak_end_hour.setDefaultValue(18)
    args << peak_end_hour

    # adding argument for elec_rate_sum_peak
    elec_rate_sum_peak = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("elec_rate_sum_peak", true)
    elec_rate_sum_peak.setDisplayName("Electric Rate Summer On-Peak")
    elec_rate_sum_peak.setUnits("$/kWh")
    elec_rate_sum_peak.setDefaultValue(0.06)
    args << elec_rate_sum_peak

    # adding argument for elec_rate_sum_nonpeak
    elec_rate_sum_nonpeak = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("elec_rate_sum_nonpeak", true)
    elec_rate_sum_nonpeak.setDisplayName("Electric Rate Summer Off-Peak")
    elec_rate_sum_nonpeak.setUnits("$/kWh")
    elec_rate_sum_nonpeak.setDefaultValue(0.04)
    args << elec_rate_sum_nonpeak

    # adding argument for elec_rate_nonsum_peak
    elec_rate_nonsum_peak = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("elec_rate_nonsum_peak", true)
    elec_rate_nonsum_peak.setDisplayName("Electric Rate Not Summer On-Peak")
    elec_rate_nonsum_peak.setUnits("$/kWh")
    elec_rate_nonsum_peak.setDefaultValue(0.05)
    args << elec_rate_nonsum_peak

    # adding argument for elec_rate_nonsum_nonpeak
    elec_rate_nonsum_nonpeak = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("elec_rate_nonsum_nonpeak", true)
    elec_rate_nonsum_nonpeak.setDisplayName("Electric Rate Not Summer Off-Peak")
    elec_rate_nonsum_nonpeak.setUnits("$/kWh")
    elec_rate_nonsum_nonpeak.setDefaultValue(0.03)
    args << elec_rate_nonsum_nonpeak

    # adding argument for elec_demand_sum
    elec_demand_sum = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("elec_demand_sum", true)
    elec_demand_sum.setDisplayName("Electric Peak Demand Charge Summer")
    elec_demand_sum.setUnits("$/kW")
    elec_demand_sum.setDefaultValue(15.0)
    args << elec_demand_sum

    # adding argument for elec_demand_nonsum
    elec_demand_nonsum = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("elec_demand_nonsum", true)
    elec_demand_nonsum.setDisplayName("Electric Peak Demand Charge Not Summer")
    elec_demand_nonsum.setUnits("$/kW")
    elec_demand_nonsum.setDefaultValue(10.0)
    args << elec_demand_nonsum

    # adding argument for gas_rate
    gas_rate = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("gas_rate", true)
    gas_rate.setDisplayName("Gas Rate")
    gas_rate.setUnits("$/therm")
    gas_rate.setDefaultValue(0.5)
    args << gas_rate

    # adding argument for water_rate
    water_rate = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("water_rate", true)
    water_rate.setDisplayName("Water Rate")
    water_rate.setUnits("$/gal")
    water_rate.setDefaultValue(0.005)
    args << water_rate

    # adding argument for disthtg_rate
    disthtg_rate = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("disthtg_rate", true)
    disthtg_rate.setDisplayName("District Heating Rate")
    disthtg_rate.setUnits("$/kBtu")
    disthtg_rate.setDefaultValue(0.2)
    args << disthtg_rate

    # adding argument for distclg_rate
    distclg_rate = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("distclg_rate", true)
    distclg_rate.setDisplayName("District Cooling Rate")
    distclg_rate.setUnits("$/kBtu")
    distclg_rate.setDefaultValue(0.2)
    args << distclg_rate

    return args
  end 

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # assign the user inputs to variables
    args  = OsLib_HelperMethods.createRunVariables(runner, workspace,user_arguments, arguments(workspace))
    if !args then return false end

    # check expected values of double arguments
    zero_24 = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments,{"min"=>0.0,"max"=>24.0,"min_eq_bool"=>true,"max_eq_bool"=>true,"arg_array" =>["peak_start_hour","peak_end_hour"]})
    one_31 = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments,{"min"=>1.0,"max"=>31.0,"min_eq_bool"=>true,"max_eq_bool"=>true,"arg_array" =>["summer_start_day","summer_end_day"]})
    one_12 = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments,{"min"=>1.0,"max"=>12.0,"min_eq_bool"=>true,"max_eq_bool"=>true,"arg_array" =>["summer_start_month","summer_end_month"]})

    # return false if any errors fail
    if !zero_24 then return false end
    if !one_31 then return false end
    if !one_12 then return false end

    # reporting initial condition of model
    starting_tariffs = workspace.getObjectsByType("UtilityCost:Tariff".to_IddObjectType)
    runner.registerInitialCondition("The model started with #{starting_tariffs.size} tariff objects.")

    # map demand window length to integer
    demand_window_per_hour = nil
    if args['demand_window_length'] == "QuarterHour"
      demand_window_per_hour = 4
    elsif args['demand_window_length'] == "HalfHour"
      demand_window_per_hour = 2
    elsif args['demand_window_length'] == "FullHour"
      demand_window_per_hour = 1
    else
      # shouldn't get here from current choice list options
    end

    # make sure demand window length is is divisible by timestep
    if not workspace.getObjectsByType("Timestep".to_IddObjectType).empty?
      initial_timestep = workspace.getObjectsByType("Timestep".to_IddObjectType)[0].getString(0).get

      if initial_timestep.to_f / demand_window_per_hour.to_f == (initial_timestep.to_f / demand_window_per_hour.to_f).truncate # checks if remainder of divided numbers is > 0
        runner.registerInfo("The demand window length of a #{args['demand_window_length']} is compatible with the current setting of #{initial_timestep} timesteps per hour.")
      else
        workspace.getObjectsByType("Timestep".to_IddObjectType)[0].setString(0,demand_window_per_hour.to_s)
        runner.registerInfo("Updating the timesteps per hour in the model from #{initial_timestep} to #{demand_window_per_hour.to_s} to be compatible with the demand window length of a #{args['demand_window_length']}")
      end
    else

      # add a timestep object to the workspace
      new_object_string = "
      Timestep,
        4;                                      !- Number of Timesteps per Hour
        "
      idfObject = OpenStudio::IdfObject::load(new_object_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_object = wsObject.get
      runner.registerInfo("No timestep object found. Added a new timestep object set to 4 timesteps per hour")
    end

    #get variables for time of day and year
    ms = args['summer_start_month']
    ds = args['summer_start_day']
    mf = args['summer_end_month']
    df = args['summer_end_day']
    ps = args['peak_start_hour']
    pf = args['peak_end_hour']
    psh = ps.truncate
    pfh = pf.truncate
    psm = ((ps-ps.truncate)*60).truncate
    pfm = ((pf-pf.truncate)*60).truncate

    if args['elec_rate_sum_peak'].abs + args['elec_rate_sum_nonpeak'].abs + args['elec_rate_nonsum_peak'].abs + args['elec_rate_nonsum_nonpeak'].abs + args['elec_demand_sum'].abs + args['elec_demand_nonsum'].abs > 0

      # make type limits object
      new_object_string = "
      ScheduleTypeLimits,
        number, !- Name
        0,                                      !- Lower Limit Value {BasedOnField A3}
        4,                                      !- Upper Limit Value {BasedOnField A3}
        DISCRETE;                               !- Numeric Type
        "
      type_limits = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      # make two season schedule
      if ms + ds/100.0 < mf + ds/100.0
        new_object_string = "
      Schedule:Compact,
        TwoSeasonSchedule,                      !- Name
        number,                                 !- Schedule Type Limits Name
        Through: #{ms}/#{ds},                   !- Field 1
        For: AllDays,                           !- Field 2
        Until: 24:00,                           !- Field 3
        1,                                      !- Field 4
        Through: #{mf}/#{df},                   !- Field 5
        For: AllDays,                           !- Field 6
        Until: 24:00,                           !- Field 7
        3,                                      !- Field 8
        Through: 12/31,                         !- Field 9
        For: AllDays,                           !- Field 10
        Until: 24:00,                           !- Field 11
        1;
        "
      else
        new_object_string = "
      Schedule:Compact,
        TwoSeasonSchedule,                      !- Name
        number,                                 !- Schedule Type Limits Name
        Through: #{mf}/#{df},                   !- Field 1
        For: AllDays,                           !- Field 2
        Until: 24:00,                           !- Field 3
        3,                                      !- Field 4
        Through: #{ms}/#{ds},                   !- Field 5
        For: AllDays,                           !- Field 6
        Until: 24:00,                           !- Field 7
        1,                                      !- Field 8
        Through: 12/31,                         !- Field 9
        For: AllDays,                           !- Field 10
        Until: 24:00,                           !- Field 11
        3;
        "
      end
      two_season_schedule = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      # make time of day schedule
      if psh + psm/100.0 < pfh + pfm/100.0
        new_object_string = "
        Schedule:Compact,
          TimeOfDaySchedule,                      !- Name
          number,                                 !- Schedule Type Limits Name
          Through: 12/31,                         !- Field 1
          For: AllDays,                           !- Field 2
          Until: #{psh}:#{psm},                   !- Field 3
          3,                                      !- Field 4
          Until: #{pfh}:#{pfm},                   !- Field 5
          1,                                      !- Field 6
          Until: 24:00,                           !- Field 7
          3;                                      !- Field 8
        "
      else
        new_object_string = "
        Schedule:Compact,
          TimeOfDaySchedule,                      !- Name
          number,                                 !- Schedule Type Limits Name
          Through: 12/31,                         !- Field 1
          For: AllDays,                           !- Field 2
          Until: #{pfh}:#{pfm},                   !- Field 3
          1,                                      !- Field 4
          Until: #{psh}:#{psm},                   !- Field 5
          3,                                      !- Field 6
          Until: 24:00,                           !- Field 7
          1;                                      !- Field 8
        "
      end
      time_of_day_schedule = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      # electric tariff object
      new_object_string = "
      UtilityCost:Tariff,
        Electricity Tariff,                     !- Name
        ElectricityPurchased:Facility,          !- Output Meter Name
        kWh,                                    !- Conversion Factor Choice
        ,                                       !- Energy Conversion Factor
        ,                                       !- Demand Conversion Factor
        #{time_of_day_schedule.getString(0)},   !- Time of Use Period Schedule Name
        #{two_season_schedule.getString(0)},    !- Season Schedule Name
        ,                                       !- Month Schedule Name
        #{args['demand_window_length']},        !- Demand Window Length
        0.0;                                    !- Monthly Charge or Variable Name
        "
      electric_tariff = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      # make UtilityCost:Charge:Simple objects for electricity
      new_object_string = "
      UtilityCost:Charge:Simple,
        ElectricityTariffSummerOnPeakEnergyCharge, !- Name
        Electricity Tariff,                      !- Tariff Name
        peakEnergy,                             !- Source Variable
        summer,                                 !- Season
        EnergyCharges,                          !- Category Variable Name
        #{args['elec_rate_sum_peak']};          !- Cost per Unit Value or Variable Name
        "
      elec_utility_cost_sum_peak = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      new_object_string = "
      UtilityCost:Charge:Simple,
        ElectricityTariffSummerOffPeakEnergyCharge, !- Name
        Electricity Tariff,                      !- Tariff Name
        offPeakEnergy,                          !- Source Variable
        summer,                                 !- Season
        EnergyCharges,                          !- Category Variable Name
        #{args['elec_rate_sum_nonpeak']};          !- Cost per Unit Value or Variable Name
        "
      elec_utility_cost_sum_nonpeak = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      new_object_string = "
      UtilityCost:Charge:Simple,
        ElectricityTariffWinterOnPeakEnergyCharge, !- Name
        Electricity Tariff,                      !- Tariff Name
        peakEnergy,                             !- Source Variable
        winter,                                 !- Season
        EnergyCharges,                          !- Category Variable Name
        #{args['elec_rate_nonsum_peak']};          !- Cost per Unit Value or Variable Name
        "
      elec_utility_cost_nonsum_peak = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      new_object_string = "
      UtilityCost:Charge:Simple,
        ElectricityTariffWinterOffPeakEnergyCharge, !- Name
        Electricity Tariff,                      !- Tariff Name
        offPeakEnergy,                          !- Source Variable
        winter,                                 !- Season
        EnergyCharges,                          !- Category Variable Name
        #{args['elec_rate_nonsum_nonpeak']};          !- Cost per Unit Value or Variable Name
        "
      elec_utility_cost_nonsum_nonpeak = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      new_object_string = "
      UtilityCost:Charge:Simple,
        ElectricityTariffSummerDemandCharge, !- Name
        Electricity Tariff,                      !- Tariff Name
        totalDemand,                            !- Source Variable
        summer,                                 !- Season
        DemandCharges,                          !- Category Variable Name
        #{args['elec_demand_sum']};          !- Cost per Unit Value or Variable Name
        "
      elec_utility_cost_sum_demand = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      new_object_string = "
      UtilityCost:Charge:Simple,
        ElectricityTariffWinterDemandCharge, !- Name
        Electricity Tariff,                      !- Tariff Name
        totalDemand,                            !- Source Variable
        summer,                                 !- Season
        DemandCharges,                          !- Category Variable Name
        #{args['elec_demand_nonsum']};          !- Cost per Unit Value or Variable Name
        "
      elec_utility_cost_nonsum_demand = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get
    end

    # gas tariff object
    if args['gas_rate'] > 0
      new_object_string = "
      UtilityCost:Tariff,
        Gas Tariff,                             !- Name
        Gas:Facility,                           !- Output Meter Name
        Therm,                                  !- Conversion Factor Choice
        ,                                       !- Energy Conversion Factor
        ,                                       !- Demand Conversion Factor
        ,                                       !- Time of Use Period Schedule Name
        ,                                       !- Season Schedule Name
        ,                                       !- Month Schedule Name
        Day,                                    !- Demand Window Length
        0.0;                                    !- Monthly Charge or Variable Name
        "
      gas_tariff = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      # make UtilityCost:Charge:Simple objects for gas
      new_object_string = "
      UtilityCost:Charge:Simple,
        GasTariffEnergyCharge, !- Name
        Gas Tariff,                             !- Tariff Name
        totalEnergy,                            !- Source Variable
        Annual,                                 !- Season
        EnergyCharges,                          !- Category Variable Name
        #{args['gas_rate']};          !- Cost per Unit Value or Variable Name
        "
      gas_utility_cost = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get
    end

    # conversion for water tariff rate
    dollars_per_gallon = args['water_rate']
    dollars_per_meter_cubed = OpenStudio.convert(dollars_per_gallon,"1/gal","1/m^3").get

    # water tariff object
    if args['water_rate'] > 0
      new_object_string = "
      UtilityCost:Tariff,
        Water Tariff,                             !- Name
        Water:Facility,             !- Output Meter Name
        UserDefined,                            !- Conversion Factor Choice
        1,                                       !- Energy Conversion Factor
        ,                                       !- Demand Conversion Factor
        ,                                       !- Time of Use Period Schedule Name
        ,                                       !- Season Schedule Name
        ,                                       !- Month Schedule Name
        ,                                       !- Demand Window Length
        0.0;                                    !- Monthly Charge or Variable Name
        "
      water_tariff = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      # make UtilityCost:Charge:Simple objects for water
      new_object_string = "
      UtilityCost:Charge:Simple,
        WaterTariffEnergyCharge, !- Name
        Water Tariff,                             !- Tariff Name
        totalEnergy,                             !- Source Variable
        Annual,                                 !- Season
        EnergyCharges,                          !- Category Variable Name
        #{dollars_per_meter_cubed};          !- Cost per Unit Value or Variable Name
        "
      water_utility_cost = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get
    end

    # disthtg tariff object
    if args['disthtg_rate'] > 0
      new_object_string = "
      UtilityCost:Tariff,
        DistrictHeating Tariff,                             !- Name
        DistrictHeating:Facility,                           !- Output Meter Name
        KBtu,                                  !- Conversion Factor Choice
        ,                                       !- Energy Conversion Factor
        ,                                       !- Demand Conversion Factor
        ,                                       !- Time of Use Period Schedule Name
        ,                                       !- Season Schedule Name
        ,                                       !- Month Schedule Name
        Day,                                    !- Demand Window Length
        0.0;                                    !- Monthly Charge or Variable Name
        "
      disthtg_tariff = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      # make UtilityCost:Charge:Simple objects for disthtg
      #value = OpenStudio::convert(args['gas_rate'],"1/therms","1/Kbtu").get # todo - get conversion working
      value = args['disthtg_rate']/99.98 # $/therm to $/Kbtu
      new_object_string = "
      UtilityCost:Charge:Simple,
        DistrictHeatingTariffEnergyCharge, !- Name
        DistrictHeating Tariff,                             !- Tariff Name
        totalEnergy,                            !- Source Variable
        Annual,                                 !- Season
        EnergyCharges,                          !- Category Variable Name
        #{value};          !- Cost per Unit Value or Variable Name
        "
      disthtg_utility_cost = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get
    end

    # distclg tariff object
    if args['distclg_rate'] > 0
      new_object_string = "
      UtilityCost:Tariff,
        DistrictCooling Tariff,                             !- Name
        DistrictCooling:Facility,                           !- Output Meter Name
        KBtu,                                  !- Conversion Factor Choice
        ,                                       !- Energy Conversion Factor
        ,                                       !- Demand Conversion Factor
        ,                                       !- Time of Use Period Schedule Name
        ,                                       !- Season Schedule Name
        ,                                       !- Month Schedule Name
        Day,                                    !- Demand Window Length
        0.0;                                    !- Monthly Charge or Variable Name
        "
      distclg_tariff = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      # make UtilityCost:Charge:Simple objects for distclg
      #value = OpenStudio::convert(args['gas_rate'],"1/therms","1/Kbtu").get # todo - get conversion working
      value = args['distclg_rate']/99.98 # $/therm to $/Kbtu
      new_object_string = "
      UtilityCost:Charge:Simple,
        DistrictCoolingTariffEnergyCharge, !- Name
        DistrictCooling Tariff,                             !- Tariff Name
        totalEnergy,                            !- Source Variable
        Annual,                                 !- Season
        EnergyCharges,                          !- Category Variable Name
        #{value};          !- Cost per Unit Value or Variable Name
      "
      distclg_utility_cost = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get
    end
    
    # report final condition of model
    finishing_tariffs = workspace.getObjectsByType("UtilityCost:Tariff".to_IddObjectType)
    runner.registerFinalCondition("The model finished with #{finishing_tariffs.size} tariff objects.")

    return true
 
  end

end 

# register the measure to be used by the application
TariffSelectionTimeAndDateDependant.new.registerWithApplication
