#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SetChillerCOP < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetChillerCOP"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # Determine how many chillers in model
    chiller_handles = OpenStudio::StringVector.new
    chiller_display_names = OpenStudio::StringVector.new

    # Get/show all chiller units from current loaded model.
    chiller_handles << '0'                # 
    chiller_display_names << '*All chillers*' #

    i_chiller = 1
    model.getChillerElectricEIRs.each do |chiller_water|
      if not chiller_water.to_ChillerElectricEIR.empty?
        water_unit = chiller_water.to_ChillerElectricEIR.get
        chiller_handles << i_chiller.to_s
        chiller_display_names << water_unit.name.to_s

        i_chiller = i_chiller + 1
      end
    end

    if i_chiller == 1
      info_widget = OpenStudio::Ruleset::OSArgument::makeBoolArgument("info_widget", true)
      info_widget.setDisplayName("!!!!*** This Measure is not Applicable to loaded Model. Read the description and choose an appropriate baseline model. ***!!!!")
      info_widget.setDefaultValue(true)
      args << info_widget
      return args
    end

    chiller_widget = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("chiller_widget", chiller_handles, chiller_display_names,true)
    chiller_widget.setDisplayName("Apply the measure to ")
    chiller_widget.setDefaultValue(chiller_display_names[0])
    args << chiller_widget

    # Chiller Thermal Efficiency (default of 3)
    chiller_thermal_efficiency = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("chiller_thermal_efficiency")
    chiller_thermal_efficiency.setDisplayName("Chiller rated COP (more than 0)")
    chiller_thermal_efficiency.setDefaultValue(3)
    args << chiller_thermal_efficiency
    return args
  end #end the arguments method


  def changeThermalEfficiency(model, chiller_index, efficiency_value_new, runner)
    i_chiller = 0
    #loop through to find water chiller getBoilerHotWaters, to_BoilerHotWater
    model.getChillerElectricEIRs.each do |chiller_water|
      if not chiller_water.to_ChillerElectricEIR.empty?
        i_chiller = i_chiller + 1
        if chiller_index != 0 and (chiller_index != i_chiller)
          next
        end

        water_unit = chiller_water.to_ChillerElectricEIR.get
        unit_name = water_unit.name

        # thermal_efficiency_old = water_unit.nominalThermalEfficiency()
        thermal_efficiency_old = water_unit.referenceCOP()

        #if thermal_efficiency_old.nil?	
        if not thermal_efficiency_old.is_a? Numeric
          runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was not set.")	
        else
          runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was not set.")
        end
        
        water_unit.setReferenceCOP(efficiency_value_new)
        runner.registerInfo("Final: The Thermal Efficiency for '#{unit_name}' was #{efficiency_value_new}")	
      end
    end
  end


  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Determine if the measure is applicable to the model, if not just return and no changes are made.
    info_widget = runner.getOptionalWorkspaceObjectChoiceValue("info_widget",user_arguments,model)
    if not (info_widget.nil? or info_widget.empty?)
      runner.registerInfo("This measure is not applicable.")
      return true
    end

    #assign the user inputs to variables
    chiller_widget = runner.getOptionalWorkspaceObjectChoiceValue("chiller_widget",user_arguments,model)

    handle = runner.getStringArgumentValue("chiller_widget",user_arguments)
    chiller_index = handle.to_i

    # #assign the user inputs to variables
    chiller_thermal_efficiency = runner.getDoubleArgumentValue("chiller_thermal_efficiency",user_arguments)

    #ruby test to see if efficient is greater than 0
    if chiller_thermal_efficiency < 0 # or chiller_thermal_efficiency > 20 #error on impossible values
      runner.registerError("Chiller COP must be greater than 0. You entered #{chiller_thermal_efficiency}.")
      return false
    end

    changeThermalEfficiency(model, chiller_index, chiller_thermal_efficiency, runner)

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetChillerCOP.new.registerWithApplication
