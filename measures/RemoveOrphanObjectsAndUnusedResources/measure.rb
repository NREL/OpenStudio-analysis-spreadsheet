# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# start the measure
class RemoveOrphanObjectsAndUnusedResources < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Remove Orphan Objects and Unused Resources"
  end

  # human readable description
  def description
    return "This is the start of a measure that will have expanded functionality over time. It will have two distinct functions. One will be to remove orphan objects. This will typically include things that should never have been left alone and often are not visible in the GUI. This would include load instances without a space or space type, and surfaces without a space.

A second functionality is to remove unused resources. This will include things like space types, schedules, constructions, and materials. There will be a series of checkboxes to enable/disable this purge. There won't be an option for the orphan objects. They will always be removed."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Purging objects like space types, schedules, and constructions requires a specific sequence to be most effective. This measure will first remove unused space types, then load defs, schedules sets, schedules,  construction sets, constructions, and then materials. A space type having a construction set assign, will show that construction set as used even if no spaces are assigned to that space type. That is why order is important."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # bool to remove unused remove_unused_space_types
    remove_unused_space_types = OpenStudio::Ruleset::OSArgument::makeBoolArgument("remove_unused_space_types",true)
    remove_unused_space_types.setDisplayName("Remove Unused Space Types")
    remove_unused_space_types.setDefaultValue(false)
    args << remove_unused_space_types

    # bool to remove unused remove_unused_load_defs
    remove_unused_load_defs = OpenStudio::Ruleset::OSArgument::makeBoolArgument("remove_unused_load_defs",true)
    remove_unused_load_defs.setDisplayName("Remove Unused Load Definitions")
    remove_unused_load_defs.setDefaultValue(false)
    args << remove_unused_load_defs

    # bool to remove unused remove_unused_schedules
    remove_unused_schedules = OpenStudio::Ruleset::OSArgument::makeBoolArgument("remove_unused_schedules",true)
    remove_unused_schedules.setDisplayName("Remove Unused Schedules Sets and Schedules")
    remove_unused_schedules.setDefaultValue(false)
    args << remove_unused_schedules

    # bool to remove unused constructions
    remove_unused_constructions = OpenStudio::Ruleset::OSArgument::makeBoolArgument("remove_unused_constructions",true)
    remove_unused_constructions.setDisplayName("Remove Unused Construction Sets, Constructions, and Materials")
    remove_unused_constructions.setDefaultValue(false)
    args << remove_unused_constructions

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    remove_unused_space_types = runner.getBoolArgumentValue("remove_unused_space_types",user_arguments)
    remove_unused_load_defs = runner.getBoolArgumentValue("remove_unused_load_defs",user_arguments)
    remove_unused_schedules = runner.getBoolArgumentValue("remove_unused_schedules",user_arguments)
    remove_unused_constructions = runner.getBoolArgumentValue("remove_unused_constructions",user_arguments)

    # report initial condition of model
    runner.registerInitialCondition("The model started with #{model.numObjects.to_s} objects.")

    # remove orphan space infiltration objects
    orphan_flag = false
    model.getSpaceInfiltrationDesignFlowRates.sort.each do |instance|
      if instance.spaceType.is_initialized == false and instance.space.is_initialized == false
        runner.registerInfo("Removing orphan space infiltration object named #{instance.name}")
        instance.remove
        orphan_flag = true
      end
    end
    if not orphan_flag
      runner.registerInfo("No orphan space infiltration objects were found")
    end

    # todo - add section to remove orphan effective leakage

    # remove orphan design spec oa objects
    orphan_flag = false
    model.getDesignSpecificationOutdoorAirs.sort.each do |instance|
      if instance.directUseCount == 0
        runner.registerInfo("Removing orphan design specification outdoor air object named #{instance.name}")
        instance.remove
        orphan_flag = true
      end
    end
    if not orphan_flag
      runner.registerInfo("No orphan design specification outdoor air objects were found")
    end

    # remove orphan load instances
    orphan_flag = false
    model.getSpaceLoadInstances.sort.each do |instance|
      if instance.spaceType.is_initialized == false and instance.space.is_initialized == false

        # extra check for water use equipment. They may or may not have space. But they should have a water use connection
        if instance.to_WaterUseEquipment.is_initialized and instance.to_WaterUseEquipment.get.waterUseConnections.is_initialized
          next
        end

        runner.registerInfo("Removing orphan load instance object named #{instance.name}")
        instance.remove
        orphan_flag = true
      end
    end
    if not orphan_flag
      runner.registerInfo("No orphan load instance objects were found")
    end

    # remove orphan surfaces
    orphan_flag = false
    model.getSurfaces.sort.each do |surface|
      if not surface.space.is_initialized
        runner.registerInfo("Removing orphan base surface named #{surface.name}")
        surface.remove
        orphan_flag = true
      end
    end
    if not orphan_flag
      runner.registerInfo("No orphan base surfaces were found")
    end

    # remove orphan subsurfaces
    orphan_flag = false
    model.getSubSurfaces.sort.each do |subsurface|
      if not subsurface.surface.is_initialized
        runner.registerInfo("Removing orphan sub surface named #{subsurface.name}")
        subsurface.remove
        orphan_flag = true
      end
    end
    if not orphan_flag
      runner.registerInfo("No orphan sub surfaces were found")
    end

    # remove orphan shading surfaces
    orphan_flag = false
    model.getShadingSurfaces.sort.each do |surface|
      if not surface.shadingSurfaceGroup.is_initialized
        runner.registerInfo("Removing orphan shading surface named #{surface.name}")
        surface.remove
        orphan_flag = true
      end
    end
    if not orphan_flag
      runner.registerInfo("No orphan shading surfaces were found")
    end

    # remove orphan interior partition surfaces
    orphan_flag = false
    model.getInteriorPartitionSurfaces.sort.each do |surface|
      if not surface.interiorPartitionSurfaceGroup.is_initialized
        runner.registerInfo("Removing orphan interior partition surface named #{surface.name}")
        surface.remove
        orphan_flag = true
      end
    end
    if not orphan_flag
      runner.registerInfo("No orphan interior partition surfaces were found")
    end

    # find and remove orphan LifeCycleCost objects
    lcc_objects = model.getObjectsByType("OS:LifeCycleCost".to_IddObjectType)
    #make an array to store the names of the orphan LifeCycleCost objects
    orphaned_lcc_objects = Array.new
    #loop through all LifeCycleCost objects, checking for missing Item Name
    lcc_objects.each do |lcc_object|
      if lcc_object.isEmpty(4)
        orphaned_lcc_objects << lcc_object.handle
        puts "**(removing object)#{lcc_object.name} is not connected to any model object"
        runner.registerInfo("Removing orphan lifecycle cost named #{lcc_object.name}")
        lcc_object.remove
      end
    end
    #summarize the results
    if not orphaned_lcc_objects.length > 0
      runner.registerInfo("no orphaned LifeCycleCost objects were found")
    end

    # todo - remove surfaces that would trigger error in E+ (less than 3 vertices or too small.)


    # todo - remove empty shading and interior partition groups. Don't think we would want to do this to spaces, since they may contain space types or loads


    # remove unused space types
    if remove_unused_space_types
      unused_flag_counter = 0
      model.getSpaceTypes.sort.each do |resource|
        if resource.spaces.size == 0
          unused_flag_counter += 1
          resource.remove
        end
      end
      runner.registerInfo("Removed #{unused_flag_counter} unused space types")
    end

    # remove unused load defs
    if remove_unused_load_defs
      unused_flag_counter = 0
      model.getSpaceLoadDefinitions.sort.each do |resource|
        if resource.directUseCount == 0
          unused_flag_counter += 1
          resource.remove
        end
      end
      runner.registerInfo("Removed #{unused_flag_counter} unused load definitions")
    end

    # remove unused default schedule sets
    if remove_unused_schedules
      unused_flag_counter = 0
      model.getDefaultScheduleSets.sort.each do |resource|
        if resource.directUseCount == 0
          unused_flag_counter += 1
          resource.remove
        end
      end
      runner.registerInfo("Removed #{unused_flag_counter} unused default schedules sets")
    end

    # remove unused default schedules
    if remove_unused_schedules
      unused_flag_counter = 0
      model.getSchedules.sort.each do |resource|
        if resource.directUseCount == 0
          unused_flag_counter += 1
          resource.remove
        end
      end
      runner.registerInfo("Removed #{unused_flag_counter} unused schedules")
    end

    # remove unused default schedule sets
    if remove_unused_constructions

      unused_flag_counter = 0
      model.getDefaultConstructionSets.sort.each do |resource|
        if resource.directUseCount == 0
          unused_flag_counter += 1
          resource.remove
        end
      end
      runner.registerInfo("Removed #{unused_flag_counter} unused default construction sets")

      # remove default surface and sub surface constructions, but dont' report
      # these are typically hidden from users and reporting it may be more confusing that helpful
      unused_flag_counter = 0
      model.getDefaultSurfaceConstructionss.sort.each do |resource|
        if resource.directUseCount == 0
          unused_flag_counter += 1
          resource.remove
        end
      end
      #runner.registerInfo("Removed #{unused_flag_counter} unused default surface constructions")

      unused_flag_counter = 0
      model.getDefaultSubSurfaceConstructionss.sort.each do |resource|
        if resource.directUseCount == 0
          unused_flag_counter += 1
          resource.remove
        end
      end
      #runner.registerInfo("Removed #{unused_flag_counter} unused default sub surface constructions")

      # remove default constructions
      unused_flag_counter = 0
      model.getConstructions.sort.each do |resource|
        if resource.directUseCount == 1 # still don't understand why this is 1 not 0
          unused_flag_counter += 1
          resource.remove
        else # this was just put in for testing ot understand why directUseCount isn't 0
          #puts ""
          #puts "Name #{resource.name}"
          #puts "directUseCount = #{resource.nonResourceObjectUseCount}"
          #puts "nonResourceObjectUseCount = #{resource.nonResourceObjectUseCount}"
          #puts "targets.size = #{resource.targets.size}"
          #puts "sources.size = #{resource.sources.size}"

        end
      end
      runner.registerInfo("Removed #{unused_flag_counter} unused constructions")

      # remove unused materials
      unused_flag_counter = 0
      model.getMaterials.sort.each do |resource|
        if resource.directUseCount == 0
          unused_flag_counter += 1
          resource.remove
        end
      end
      runner.registerInfo("Removed #{unused_flag_counter} unused materials")

    end

    # report final condition of model
    runner.registerFinalCondition("The model finished with #{model.numObjects.to_s} objects.")

    return true

  end
  
end

# register the measure to be used by the application
RemoveOrphanObjectsAndUnusedResources.new.registerWithApplication
