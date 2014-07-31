#see the URL below for information on how to write OpenStuido measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on mondel objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddDencityMeters < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddDencityMeters"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    meters = model.getMeters
    #reporting initial condition of model
    runner.registerInitialCondition("The model started with #{meters.size} meter objects.")

    #flag to add meter
    OpenStudio::FuelType.getValues.each do |i|
      fuel_type = OpenStudio::FuelType.new(i)
      OpenStudio::EndUseType.getValues.each do |j|
        end_use_type = OpenStudio::EndUseType.new(j)
        add_flag = true
        meter_name = OpenStudio::Model::Meter.getName(OpenStudio::OptionalString.new,
                                                      OpenStudio::OptionalEndUseType.new(end_use_type),
                                                      OpenStudio::OptionalFuelType.new(fuel_type),
                                                      OpenStudio::OptionalInstallLocationType.new('Facility'.to_InstallLocationType),
                                                      OpenStudio::OptionalString.new)

          meters.each do |meter|
          if meter.name == meter_name
            runner.registerWarning("A meter named #{meter_name} already exists. One will not be added to the model.")
            unless meter.reportingFrequency == "hourly"
              meter.setReportingFrequency("hourly")
              runner.registerInfo("Changing reporting frequency of existing meter to hourly.")
            end
            add_flag = false
          end
        end

        if add_flag == true
          meter = OpenStudio::Model::Meter.new(model)
          meter.setName(meter_name)
          meter.setReportingFrequency("hourly")
          runner.registerInfo("Adding meter for #{meter.name} reporting hourly")
        end
      end
    end

    meters = model.getMeters
    #reporting final condition of model
    runner.registerFinalCondition("The model finished with #{meters.size} meter objects.")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddDencityMeters.new.registerWithApplication