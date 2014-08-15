# AddBuildingType inserts the desired building type string into the model.

# Author: Henry Horsey (github: henryhorsey)
# Creation Date: 7/24/2014

class AddBuildingType < OpenStudio::Ruleset::ReportingUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    'Add Building Type'
  end

  #define the arguments that the user will input
  def arguments
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make choice argument for facade
    building_type = OpenStudio::Ruleset::OSArgument::makeStringArgument('building_type', TRUE)
    building_type.setDisplayName('Building Type')
    building_type.setDefaultValue('Undefined')
    args << output_format

    args
  end #end arguments

  def run
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    building_type = runner.getStringArgumentValue('building_type',user_arguments)

    #get model, building, and set building type
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get

    building = model.getBuilding
    building.setStandardsBuildingTypes(building_type)

    TRUE
  end #end the method
end #end the measure

#this allows the measure to be use by the application
AddBuildingType.new.registerWithApplication