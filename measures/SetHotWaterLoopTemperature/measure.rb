#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SetHotWaterLoopTemperature < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetHotWaterLoopTemperature"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument to add new space true/false
    hw_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hw_temp_f",true)
    hw_temp_f.setDisplayName("Desired hot water setpoint (F)")
    hw_temp_f.setDefaultValue(140.0)
    args << hw_temp_f
    
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
    hw_temp_f = runner.getDoubleArgumentValue("hw_temp_f",user_arguments)

    #loop through all the plant loops in the mode
    model.getPlantLoops.each do |plant_loop|
      #loop through all the supply components on this plant loop
      hot_water_loop = false
      plant_loop.supplyComponents.each do |supply_component|
        #check if the supply component is a boiler
        if supply_component.to_BoilerHotWater.is_initialized
          hot_water_loop = true
          break
        end
      end
      
      if hot_water_loop == true
        #tell the user that we found a hot water loop
        runner.registerInfo("#{plant_loop.name} is a hot water loop; setpoint changed to #{hw_temp_f}F")
        
        #create a scheduled setpoint manager with this temperature
        hw_temp_c = OpenStudio::convert(hw_temp_f,"F","C").get
        hw_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
        hw_temp_sch.setName("Hot Water Temp - #{hw_temp_f}F")
        hw_temp_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),hw_temp_c)
        hw_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model,hw_temp_sch)
        plant_loop.supplyOutletNode.addSetpointManager(hw_stpt_manager)

        #set the sizing temperatures for the loop
        plant_loop.sizingPlant.setLoopType("Heating")
        plant_loop.sizingPlant.setDesignLoopExitTemperature(hw_temp_c)
        plant_loop.sizingPlant.setLoopDesignTemperatureDifference(6.7) #Default 6.7C = 12F delta-T     
      end
    
    end #next plant loop
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetHotWaterLoopTemperature.new.registerWithApplication