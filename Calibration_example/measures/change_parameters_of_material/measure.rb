#start the measure
class ChangeParametersOfMaterial < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see
  def name
    return "Change Parameters Of Material"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #populate choice argument for constructions that are applied to surfaces in the model
    construction_handles = OpenStudio::StringVector.new
    construction_display_names = OpenStudio::StringVector.new

    #putting space types and names into hash
    construction_args = model.getConstructions
    construction_args_hash = {}
    construction_args.each do |construction_arg|
      construction_args_hash[construction_arg.name.to_s] = construction_arg
    end

    #looping through sorted hash of constructions
    construction_args_hash.sort.map do |key,value|
      #only include if construction is used on surface
      if value.getNetArea > 0
        construction_handles << value.handle.to_s
        construction_display_names << key
      end
    end

    #make an argument for construction
    construction = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("construction", construction_handles, construction_display_names,true)
    construction.setDisplayName("Choose a Construction to Alter.")
    args << construction

    #make an argument thickness
    thickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("thickness",true)
    thickness.setDisplayName("thickness")
    thickness.setDefaultValue(0.006)
    args << thickness
    
    #make an argument density
    density = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("density",true)
    density.setDisplayName("density")
    density.setDefaultValue(7800)
    args << density
 
    #make an argument thermal_absorptance
    thermal_absorptance = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("thermal_absorptance",true)
    thermal_absorptance.setDisplayName("thermal_absorptance")
    thermal_absorptance.setDefaultValue(0.69)
    args << thermal_absorptance
    
    #make an argument solar_absorptance
    solar_absorptance = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("solar_absorptance",true)
    solar_absorptance.setDisplayName("solar_absorptance.")
    solar_absorptance.setDefaultValue(0.69)
    args << solar_absorptance
    
    #make an argument visible_absorptance
    visible_absorptance = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("visible_absorptance",true)
    visible_absorptance.setDisplayName("visible_absorptance")
    visible_absorptance.setDefaultValue(0.69)
    args << visible_absorptance
    
    #make an argument conductivity
    thermal_conductivity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("thermal_conductivity",true)
    thermal_conductivity.setDisplayName("thermal_conductivity")
    thermal_conductivity.setDefaultValue(45)
    args << thermal_conductivity
    
    #make an argument specific_heat
    specific_heat = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("specific_heat",true)
    specific_heat.setDisplayName("specific_heat")
    specific_heat.setDefaultValue(499)
    args << specific_heat

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
    construction = runner.getOptionalWorkspaceObjectChoiceValue("construction",user_arguments,model) #model is passed in because of argument type
    thermal_absorptance = runner.getDoubleArgumentValue("thermal_absorptance",user_arguments)
    solar_absorptance = runner.getDoubleArgumentValue("solar_absorptance",user_arguments)
    visible_absorptance = runner.getDoubleArgumentValue("visible_absorptance",user_arguments)
    thermal_conductivity = runner.getDoubleArgumentValue("thermal_conductivity",user_arguments)
    specific_heat = runner.getDoubleArgumentValue("specific_heat",user_arguments)
    thickness = runner.getDoubleArgumentValue("thickness",user_arguments)
    density = runner.getDoubleArgumentValue("density",user_arguments)
    
    #check the construction for reasonableness
    if construction.empty?
      handle = runner.getStringArgumentValue("construction",user_arguments)
      if handle.empty?
        runner.registerError("No construction was chosen.")
      else
        runner.registerError("The selected construction with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not construction.get.to_Construction.empty?
        construction = construction.get.to_Construction.get
      else
        runner.registerError("Script Error - argument not showing up as construction.")
        return false
      end
    end  #end of if construction.empty?

    initial_r_value_ip = OpenStudio::convert(1.0/construction.thermalConductance.to_f,"m^2*K/W", "ft^2*h*R/Btu")
    runner.registerInitialCondition("The Initial R-value of #{construction.name} is #{initial_r_value_ip} (ft^2*h*R/Btu).")

    #get layers
    layers = construction.layers

    #steel layer is always first layer
    layer = layers[0].to_StandardOpaqueMaterial.get
    runner.registerInfo("Initial thermal_absorptance: #{layer.thermalAbsorptance}")
    runner.registerInfo("Initial solar_absorptance: #{layer.solarAbsorptance}")
    runner.registerInfo("Initial visible_absorptance: #{layer.visibleAbsorptance}")
    runner.registerInfo("Initial thermal_conductivity: #{layer.thermalConductivity}")
    runner.registerInfo("Initial specific_heat: #{layer.specificHeat}")
    runner.registerInfo("Initial thickness: #{layer.thickness}")
    runner.registerInfo("Initial density: #{layer.density}")
    
    #set layer properties
    layer.setThermalAbsorptance(thermal_absorptance)
    layer.setSolarAbsorptance(solar_absorptance)
    layer.setVisibleAbsorptance(visible_absorptance)
    layer.setThermalConductivity(thermal_conductivity)
    layer.setSpecificHeat(specific_heat)
    layer.setThickness(thickness)
    layer.setDensity(density)
    
    runner.registerInfo("Final thermal_absorptance: #{layer.thermalAbsorptance}")
    runner.registerInfo("Final solar_absorptance: #{layer.solarAbsorptance}")
    runner.registerInfo("Final visible_absorptance: #{layer.visibleAbsorptance}")
    runner.registerInfo("Final thermal_conductivity: #{layer.thermalConductivity}")
    runner.registerInfo("Final specific_heat: #{layer.specificHeat}")
    runner.registerInfo("Final thickness: #{layer.thickness}")
    runner.registerInfo("Final density: #{layer.density}")

    # report initial condition
    final_r_value_ip = OpenStudio::convert(1/construction.thermalConductance.to_f,"m^2*K/W", "ft^2*h*R/Btu")
    runner.registerFinalCondition("The Final R-value of #{construction.name} is #{final_r_value_ip} (ft^2*h*R/Btu).")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
ChangeParametersOfMaterial.new.registerWithApplication
