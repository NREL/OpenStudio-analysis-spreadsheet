#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class TimeSeriesEndUses < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "TimeSeriesEndUses"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for the meter type
    meter_type_chs = OpenStudio::StringVector.new
    meter_type_chs << "Facility"
    meter_type_chs << "Building"
    meter_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("meter_type",meter_type_chs, true)
    meter_type.setDisplayName("Meter Type")
    meter_type.setDefaultValue("Facility")
    args << meter_type
    
    #make an argument for the electric tariff
    reporting_frequency_chs = OpenStudio::StringVector.new
    reporting_frequency_chs << "detailed"
    reporting_frequency_chs << "timestep"
    reporting_frequency_chs << "hourly"
    reporting_frequency_chs << "daily"
    reporting_frequency_chs << "monthly"
    reporting_frequency = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('reporting_frequency', reporting_frequency_chs, true)
    reporting_frequency.setDisplayName("Reporting Frequency")
    reporting_frequency.setDefaultValue("hourly")
    args << reporting_frequency

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    meter_type = runner.getStringArgumentValue("meter_type",user_arguments)
    meter_names = []
    meter_names << "Electricity:#{meter_type}"
    meter_names << "Gas:#{meter_type}"
    meter_names << "DistrictCooling:#{meter_type}"
    meter_names << "DistrictHeating:#{meter_type}"
    meter_names << "Water:#{meter_type}"
    meter_names << "Steam:#{meter_type}"
    meter_names << "Gasoline:#{meter_type}"
    meter_names << "Diesel:#{meter_type}"
    meter_names << "Coal:#{meter_type}"
    meter_names << "Propane:#{meter_type}"
    meter_names << "OtherFuel1:#{meter_type}"
    meter_names << "OtherFuel2:#{meter_type}"
#    meter_names << "FuelOil#1:#{meter_type}"
#    meter_names << "FuelOil#2:#{meter_type}"
    
    #assign the user inputs to variables
    reporting_frequency = runner.getStringArgumentValue("reporting_frequency",user_arguments)

    meters = model.getMeters
    #reporting initial condition of model
    runner.registerInitialCondition("The model started with #{meters.size} meter objects.")

    meter_names.each do |meter_name|
      #flag to add meter
      add_flag = true

      # OpenStudio doesn't seem to like two meters of the same name, even if they have different reporting frequencies.
      meters.each do |meter|
        if meter.name == meter_name
        runner.registerWarning("A meter named #{meter_name} already exists. One will not be added to the model.")
        if not meter.reportingFrequency == reporting_frequency
          meter.setReportingFrequency(reporting_frequency)
          runner.registerInfo("Changing reporting frequency of existing meter to #{reporting_frequency}.")
        end
        add_flag = false
        end
      end

      if add_flag
        meter = OpenStudio::Model::Meter.new(model)
        meter.setName(meter_name)
        meter.setReportingFrequency(reporting_frequency)
        runner.registerInfo("Adding meter for #{meter.name} reporting #{reporting_frequency}")
      end

    end

    meters = model.getMeters
    #reporting final condition of model
    runner.registerFinalCondition("The model finished with #{meters.size} meter objects.")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
TimeSeriesEndUses.new.registerWithApplication