#see the URL below for information on how to write OpenStuido measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on mondel objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddMeter < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddMeter"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for the meter name
    meter_name = OpenStudio::Ruleset::OSArgument::makeStringArgument("meter_name",true)
    meter_name.setDisplayName("Enter Meter Name.")
    meter_name.setDefaultValue("Electricity:Facility")
    args << meter_name

    #make an argument for the electric tariff
    reporting_frequency_chs = OpenStudio::StringVector.new
    reporting_frequency_chs << "detailed"
    reporting_frequency_chs << "timestep"
    reporting_frequency_chs << "hourly"
    reporting_frequency_chs << "daily"
    reporting_frequency_chs << "monthly"
    reporting_frequency = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('reporting_frequency', reporting_frequency_chs, true)
    reporting_frequency.setDisplayName("Reporting Frequency.")
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

    #assign the user inputs to variables
    meter_name = runner.getStringArgumentValue("meter_name",user_arguments)
    reporting_frequency = runner.getStringArgumentValue("reporting_frequency",user_arguments)

    #check the user_name for reasonableness
    if meter_name == ""
      runner.registerError("No meter name was entered.")
      return false
    end

    meters = model.getMeters
    #reporting initial condition of model
    runner.registerInitialCondition("The model started with #{meters.size} meter objects.")

    #flag to add meter
    add_flag = true

    # OpenStudio doesn't seemt to like two meters of the same name, even if they have different reporting frequencies.
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

    meters = model.getMeters
    #reporting final condition of model
    runner.registerFinalCondition("The model finished with #{meters.size} meter objects.")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddMeter.new.registerWithApplication