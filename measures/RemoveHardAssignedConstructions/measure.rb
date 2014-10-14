#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class RemoveHardAssignedConstructions < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "RemoveHardAssignedConstructions"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument to skip removal of hard assigned constructions on adiabatic surfaces
    preserve_adiabatic = OpenStudio::Ruleset::OSArgument::makeBoolArgument("preserve_adiabatic",true)
    preserve_adiabatic.setDisplayName("Preserve Hard Assigned Constructions for Adiabatic Surfaces.")
    preserve_adiabatic.setDefaultValue(true)
    args << preserve_adiabatic


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
    preserve_adiabatic = runner.getBoolArgumentValue("preserve_adiabatic",user_arguments)

    # setup counter for initial condition
    numberOfDefaultedSurfaces = 0

    # surfaces to skip if preserve_adiabatic
    adiabaticArray = []
    model.getSurfaces.each do |surface|
      if surface.outsideBoundaryCondition == "Adiabatic"
        adiabaticArray << surface
      end
    end

    # reset all planar surfaces
    planar_surfaces = model.getPlanarSurfaces
    planar_surfaces.each do |planar_surface|
      if planar_surface.isConstructionDefaulted
        numberOfDefaultedSurfaces += 1
      end
      if not (preserve_adiabatic and adiabaticArray.include? planar_surface)
        planar_surface.resetConstruction
      end
    end

    #reporting initial condition of model
    runner.registerInitialCondition("The building has #{planar_surfaces.size} planar surfaces. Initially #{planar_surfaces.size - numberOfDefaultedSurfaces} surfaces have hard assigned constructions.")

    # check how many surfaces are defaulted in final model
    finalNumberOfDefaultedSurfaces = 0
    planar_surfaces.each do |planar_surface|
      if planar_surface.isConstructionDefaulted
        finalNumberOfDefaultedSurfaces += 1
      end
    end

    #reporting final condition of model
    finishing_spaces = model.getSpaces
    runner.registerFinalCondition("The final model has #{planar_surfaces.size - finalNumberOfDefaultedSurfaces} surfaces with hard assigned constructions.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
RemoveHardAssignedConstructions.new.registerWithApplication