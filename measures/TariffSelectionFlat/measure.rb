# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"

# start the measure
class TariffSelectionFlat < OpenStudio::Ruleset::WorkspaceUserScript

  # human readable name
  def name
    return "Tariff Selection-Flat"
  end

  # human readable description
  def description
    return "This measure sets flat rates for electricity, gas, water, district heating, and district cooling."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Will add the necessary UtilityCost objects into the model."
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

    # adding argument for elec_rate
    elec_rate = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("elec_rate", true)
    elec_rate.setDisplayName("Electric Rate")
    elec_rate.setUnits("$/kWh")
    elec_rate.setDefaultValue(0.12)
    args << elec_rate

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
    disthtg_rate.setUnits("$/therm")
    disthtg_rate.setDefaultValue(0.2)
    args << disthtg_rate

    # adding argument for distclg_rate
    distclg_rate = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("distclg_rate", true)
    distclg_rate.setDisplayName("District Cooling Rate")
    distclg_rate.setUnits("$/therm")
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

    # elec tariff object
    if args['elec_rate'] > 0
      new_object_string = "
      UtilityCost:Tariff,
        Electricity Tariff,                     !- Name
        ElectricityPurchased:Facility,          !- Output Meter Name
        kWh,                                    !- Conversion Factor Choice
        ,                                       !- Energy Conversion Factor
        ,                                       !- Demand Conversion Factor
        ,                                       !- Time of Use Period Schedule Name
        ,                                       !- Season Schedule Name
        ,                                       !- Month Schedule Name
        Day,                                    !- Demand Window Length
        0.0;                                    !- Monthly Charge or Variable Name
        "
      elec_tariff = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get

      # make UtilityCost:Charge:Simple objects for electricity
      new_object_string = "
      UtilityCost:Charge:Simple,
        ElectricityTariffEnergyCharge, !- Name
        Electricity Tariff,                     !- Tariff Name
        totalEnergy,                            !- Source Variable
        Annual,                                 !- Season
        EnergyCharges,                          !- Category Variable Name
        #{args['elec_rate']};          !- Cost per Unit Value or Variable Name
        "
      elec_utility_cost = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get
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
        Therm,                                  !- Conversion Factor Choice
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
      new_object_string = "
      UtilityCost:Charge:Simple,
        DistrictHeatingTariffEnergyCharge, !- Name
        DistrictHeating Tariff,                             !- Tariff Name
        totalEnergy,                            !- Source Variable
        Annual,                                 !- Season
        EnergyCharges,                          !- Category Variable Name
        #{args['disthtg_rate']};          !- Cost per Unit Value or Variable Name
        "
      disthtg_utility_cost = workspace.addObject(OpenStudio::IdfObject::load(new_object_string).get).get
    end

    # distclg tariff object
    if args['distclg_rate'] > 0
      new_object_string = "
      UtilityCost:Tariff,
        DistrictCooling Tariff,                             !- Name
        DistrictCooling:Facility,                           !- Output Meter Name
        Therm,                                  !- Conversion Factor Choice
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
      new_object_string = "
      UtilityCost:Charge:Simple,
        DistrictCoolingTariffEnergyCharge, !- Name
        DistrictCooling Tariff,                             !- Tariff Name
        totalEnergy,                            !- Source Variable
        Annual,                                 !- Season
        EnergyCharges,                          !- Category Variable Name
        #{args['distclg_rate']};          !- Cost per Unit Value or Variable Name
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
TariffSelectionFlat.new.registerWithApplication
