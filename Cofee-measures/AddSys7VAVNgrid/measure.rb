#see the URL below for information on how to write OpenStudio measures
# http:#openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http:#openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http:#openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddSys7VAVNgrid < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add Sys 7 - VAV Ngrid"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # Heating efficiency
    heating_efficiency = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("heating_efficiency",true)
    heating_efficiency.setDisplayName("Heating Efficiency")
    heating_efficiency.setDefaultValue(0.8)
    args << heating_efficiency

    # Cooling cop
    cooling_cop = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cooling_cop",true)
    cooling_cop.setDisplayName("Cooling COP")
    cooling_cop.setDefaultValue(3.0)
    args << cooling_cop

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    heating_efficiency = runner.getDoubleArgumentValue('heating_efficiency',user_arguments)
    cooling_cop = runner.getDoubleArgumentValue('cooling_cop',user_arguments)

    # System Type 7: VAV
    # This measure creates:
    # a variable volume packaged rooftop A/C unit with hot water coil and hot water reheat 
    # for each story in the building
    
    # Make a VAV for each story
    model.getBuildingStorys.each do |story|
      
      air_loop = OpenStudio::Model::addSystemType7(model).to_AirLoopHVAC.get
      air_loop.setName("#{story.name} VAV")
      
      set_cop = false
      set_heating_eff = false
      air_loop.supplyComponents.each do |component|
        if not component.to_WaterToAirComponent.empty?
          plant_loop = component.to_WaterToAirComponent.get.plantLoop
          if not plant_loop.empty?
            plant_loop.get.supplyComponents.each do |component2|
              if not component2.to_BoilerHotWater.empty?
                component2 = component2.to_BoilerHotWater.get
                component2.setNominalThermalEfficiency(heating_efficiency)
                set_heating_eff = true
              elsif not component2.to_ChillerElectricEIR.empty?
                component2 = component2.to_ChillerElectricEIR.get
                component2.setReferenceCOP(cooling_cop)
                set_cop = true
              end
            end
          end
        end
      end
      
      if not set_cop
        runner.registerWarning("Failed to set COP for air loop #{air_loop.name}")
      end
      
      if not set_heating_eff
        runner.registerWarning("Failed to set Heating Efficiency for air loop #{air_loop.name}")
      end
      
      thermal_zones_done = Hash.new
      story.spaces.each do |space|
        thermal_zone = space.thermalZone
        if not thermal_zone.empty?
          if not thermal_zones_done[thermal_zone.get.handle.to_s]
            air_loop.addBranchForZone(thermal_zone.get)
            thermal_zones_done[thermal_zone.get.handle.to_s] = true
          end
        end
      end
    end  
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddSys7VAVNgrid.new.registerWithApplication