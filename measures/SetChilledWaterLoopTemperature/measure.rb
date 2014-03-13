#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SetChilledWaterLoopTemperature < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetChilledWaterLoopTemperature"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument to add new space true/false
    cw_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cw_temp_f",true)
    cw_temp_f.setDisplayName("Desired chilled water setpoint (F)")
    cw_temp_f.setDefaultValue(45.0)
    args << cw_temp_f
    
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
    cw_temp_f = runner.getDoubleArgumentValue("cw_temp_f",user_arguments)

    #loop through all the plant loops in the mode
    model.getPlantLoops.each do |plant_loop|
      #loop through all the supply components on this plant loop
      chilled_water_loop = false
      plant_loop.supplyComponents.each do |supply_component|
        #check if the supply component is a chiller
        if supply_component.to_ChillerElectricEIR.is_initialized
          chilled_water_loop = true
          break
        end
      end
      
      if chilled_water_loop == true
        #tell the user that we found a chilled water loop
        runner.registerInfo("#{plant_loop.name} is a chilled water loop; setpoint changed to #{cw_temp_f}F")
        
        #create a scheduled setpoint manager with this temperature
        cw_temp_c = OpenStudio::convert(cw_temp_f,"F","C").get
        cw_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
        cw_temp_sch.setName("Chilled Water Temp - #{cw_temp_f}F")
        cw_temp_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),cw_temp_c)
        cw_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model,cw_temp_sch)
        plant_loop.supplyOutletNode.addSetpointManager(cw_stpt_manager)

        #set the sizing temperatures for the loop
        plant_loop.sizingPlant.setLoopType("Cooling")
        plant_loop.sizingPlant.setDesignLoopExitTemperature(cw_temp_c)
        plant_loop.sizingPlant.setLoopDesignTemperatureDifference(6.7) #Default 6.7C = 12F delta-T     
      end
    
    end #next plant loop
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetChilledWaterLoopTemperature.new.registerWithApplication