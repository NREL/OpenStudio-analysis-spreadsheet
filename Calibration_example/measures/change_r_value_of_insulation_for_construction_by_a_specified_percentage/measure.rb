#start the measure
class ChangeRValueOfInsulationForConstructionByASpecifiedPercentage < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see
  def name
    return "Change R-value of Insulation for Construction By a Specified Percentage"
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

    #make an argument insulation R-value
    r_value_prct_inc = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("r_value_prct_inc",true)
    r_value_prct_inc.setDisplayName("Percentage Change of R-value for Insulation Layer of Construction.")
    r_value_prct_inc.setDefaultValue(30.0)
    args << r_value_prct_inc

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
    r_value_prct_inc = runner.getDoubleArgumentValue("r_value_prct_inc",user_arguments)

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

    #check the R-value for reasonableness
    if r_value_prct_inc <  -100
      runner.registerError("Percentage change less than -100% is not valid.")
      return false
    end

    #set limit for minimum insulation. This is used to limit input and for inferring insulation layer in construction.
    min_expected_r_value_prct_inc_ip = 1 #ip units

    # report initial condition
    initial_r_value_ip = OpenStudio::convert(1.0/construction.thermalConductance.to_f,"m^2*K/W", "ft^2*h*R/Btu")
    runner.registerInitialCondition("The Initial R-value of #{construction.name} is #{initial_r_value_ip} (ft^2*h*R/Btu).")

    # todo - find and test insulation
    construction_layers = construction.layers
    max_thermal_resistance_material = ""
    max_thermal_resistance_material_index = ""
    counter = 0
    thermal_resistance_values = []

    #loop through construction layers and infer insulation layer/material
    construction_layers.each do |construction_layer|
      construction_layer_r_value = construction_layer.to_OpaqueMaterial.get.thermalResistance
      if not thermal_resistance_values.empty?
        if construction_layer_r_value > thermal_resistance_values.max
          max_thermal_resistance_material = construction_layer
          max_thermal_resistance_material_index = counter
        end
      end
      thermal_resistance_values << construction_layer_r_value
      counter = counter + 1
    end
    if not thermal_resistance_values.max > OpenStudio::convert(min_expected_r_value_prct_inc_ip, "ft^2*h*R/Btu","m^2*K/W").get
      runner.registerNotAppicable("Construction '#{exterior_surface_construction.name.to_s}' does not appear to have an insulation layer and was not altered.")
      return true
    end

    # clone insulation material
    new_material = max_thermal_resistance_material.clone(model)
    new_material = new_material.to_OpaqueMaterial.get
    new_material.setName("#{max_thermal_resistance_material.name.to_s}_R-value #{r_value_prct_inc.round(2)}% change")
    construction.eraseLayer(max_thermal_resistance_material_index)
    construction.insertLayer(max_thermal_resistance_material_index,new_material)
    runner.registerInfo("For construction'#{construction.name.to_s}', '#{max_thermal_resistance_material.name.to_s}' was altered.")

    # edit clone material
    new_material_matt = new_material.to_Material
    if not new_material_matt.empty?
      starting_thickness = new_material_matt.get.thickness
      target_thickness = starting_thickness * (1 + r_value_prct_inc/100)
      final_thickness = new_material_matt.get.setThickness(target_thickness)
    end
    new_material_massless = new_material.to_MasslessOpaqueMaterial
    if not new_material_massless.empty?
      starting_thermal_resistance = new_material_massless.get.thermalResistance
      final_thermal_resistance = new_material_massless.get.setThermalResistance(starting_thermal_resistance * (1 + r_value_prct_inc/100))
    end
    new_material_airgap = new_material.to_AirGap
    if not new_material_airgap.empty?
      starting_thermal_resistance = new_material_airgap.get.thermalResistance
      final_thermal_resistance = new_material_airgap.get.setThermalResistance(starting_thermal_resistance * (1 + r_value_prct_inc/100))
    end

    # report initial condition
    final_r_value_ip = OpenStudio::convert(1/construction.thermalConductance.to_f,"m^2*K/W", "ft^2*h*R/Btu")
    runner.registerFinalCondition("The Final R-value of #{construction.name} is #{final_r_value_ip} (ft^2*h*R/Btu).")
    runner.registerValue("final_r_value_ip",final_r_value_ip.to_f,"")
    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
ChangeRValueOfInsulationForConstructionByASpecifiedPercentage.new.registerWithApplication
