#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ReplaceAllIncandescentLampswithCFLLamps < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Replace All Incandescent Lamps with CFL Lamps"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make choice argument economizer control type
    incandescent_to_cfl_lamp_replacement = OpenStudio::Ruleset::OSArgument::makeBoolArgument("incandescent_to_cfl_lamp_replacement", true)
    incandescent_to_cfl_lamp_replacement.setDisplayName("Replace Incandescent Lamps with CFL Lamps")
    args << incandescent_to_cfl_lamp_replacement
        
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # Assign the user inputs to variables
    incandescent_to_cfl_lamp_replacement = runner.getBoolArgumentValue("incandescent_to_cfl_lamp_replacement",user_arguments)    
    
    # Note if incandescent_to_cfl_lamp_replacement == false
    # and register as N/A
    if incandescent_to_cfl_lamp_replacement == false
      runner.registerAsNotApplicable("N/A - User requested no change in lighting fixtures.")
      return true
    end  

    #hash of original to new light fixtures
    old_lts_def_new_lts_def = {}
    lamps_replaced_per_fixture = {}
    
    #CFL wattage
    new_lamp_wattage = 13
    
    #first get all of the incandescent light fixture definitions in the model
    model.getLightsDefinitions.each do |original_lights_def|
      #(1) 60W Incandescent
      name = original_lights_def.name.get
      runner.registerInfo("Checking = #{name}")
      
      #get the fixture properties from the fixture name
      next if name.scan(/[\d\.]+W (\w+)/).size == 0
      lamp_type = name.scan(/[\d\.]+W (\w+)/)[0][0]
      runner.registerInfo("lamp_type = #{lamp_type}")
      next unless lamp_type == "Incandescent"
      
      next if name.match(/([\d\.]+)W/).size == 0
      lamp_wattage = name.match(/([\d\.]+)W/)[0].to_f

      runner.registerInfo("lamp_wattage = #{lamp_wattage}")
      next unless lamp_wattage == 60.0 #only looking to replace 40W T12s
      
      next if name.scan(/\((\d+)\)/).size == 0
      num_lamps = name.scan(/\((\d+)\)/)[0][0].to_f
      runner.registerInfo("num_lamps = #{num_lamps}")

      #calculate the wattage of the fixture with lower wattage lamps
      new_total_wattage = num_lamps * new_lamp_wattage 
      
      #rename the fixture with new low wattage lamps, pattern:
      #(1) 13W CFL
      new_name = "(#{num_lamps}) #{new_lamp_wattage}W CFL"

      #make the new lights definition to replace the old one
      new_lights_def = OpenStudio::Model::LightsDefinition.new(model)
      new_lights_def.setName(new_name)
      new_lights_def.setLightingLevel(new_total_wattage)
 
      #register the old and new fixture
      old_lts_def_new_lts_def[original_lights_def] = new_lights_def
      lamps_replaced_per_fixture[original_lights_def] = num_lamps
      
    end
    
    #replace all incandescent fixtures with their clones with 13W CFL Lamps
    number_of_fixtures_replaced = 0
    number_of_lamps_replaced = 0
    model.getLightss.each do |light_fixture|
      if old_lts_def_new_lts_def[light_fixture.lightsDefinition]
        #log the  fixture name
        original_fixture_name = light_fixture.lightsDefinition.name
        #get the replacement light fixture definition
        new_lights_def = old_lts_def_new_lts_def[light_fixture.lightsDefinition]
        lamps_per_fixture = lamps_replaced_per_fixture[light_fixture.lightsDefinition]
        #replace the existing light fixture with the new one and log the replacement
        light_fixture.setLightsDefinition(new_lights_def)
        number_of_fixtures_replaced += light_fixture.multiplier
        number_of_lamps_replaced += light_fixture.multiplier * lamps_per_fixture
        runner.registerInfo("Replaced #{(light_fixture.multiplier * lamps_per_fixture).round} lamps in #{light_fixture.multiplier.round} #{original_fixture_name} fixtures.")
      end
    end
    
    #report if the measure is not applicable (no T12 fixtures)
    if number_of_fixtures_replaced == 0
      runner.registerAsNotApplicable("This measure is not applicable, because this building has no T12 fixtures.")
      return true
    end
     
    #report initial condition
    runner.registerInitialCondition("The building has approximately #{number_of_fixtures_replaced.round} light fixtures with standard 60W incandescent lamps.")

    #report final condition
    runner.registerFinalCondition("Replace #{number_of_lamps_replaced.round} incandescent lamps in #{number_of_fixtures_replaced.round} light fixtures throughout the building with #{new_lamp_wattage}W CFL lamps.")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ReplaceAllIncandescentLampswithCFLLamps.new.registerWithApplication