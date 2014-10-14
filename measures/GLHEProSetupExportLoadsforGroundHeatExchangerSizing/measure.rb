#see the URL below for information on how to write OpenStuido measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on mondel objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class GLHEProSetupExportLoadsforGroundHeatExchangerSizing < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "GLHEProSetupExportLoadsforGroundHeatExchangerSizing"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
   
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # Define the reporting frequency
    reporting_frequency = "hourly"
    
    # Define the variables to report
    variable_names = []
    variable_names << "District Heating Rate"
    variable_names << "District Cooling Rate"
    
    # Request each output variable
    variable_names.each do |variable_name|
      output_variable = OpenStudio::Model::OutputVariable.new(variable_name,model)
      output_variable.setReportingFrequency(reporting_frequency)
      runner.registerInfo("Requested output for '#{output_variable.variableName}' at the #{output_variable.reportingFrequency} timestep.")
    end
    
    # Report the outlet node conditions for each plant loop in the model
    # Rename the outlet node so that it makes sense in the report
    outlet_node_variable_names = []
    outlet_node_variable_names << "System Node Temperature"
    outlet_node_variable_names << "System Node Setpoint Temperature"
    outlet_node_variable_names << "System Node Mass Flow Rate"
    model.getPlantLoops.each do |plant_loop|
      outlet_node = plant_loop.supplyOutletNode
      outlet_node_name = "#{plant_loop.name} Supply Outlet Node"
      outlet_node.setName(outlet_node_name)
      outlet_node_variable_names.each do |outlet_node_variable_name|
        output_variable = OpenStudio::Model::OutputVariable.new(outlet_node_variable_name,model)
        output_variable.setKeyValue(outlet_node_name) 
        output_variable.setReportingFrequency(reporting_frequency)      
      end
    end
    
   
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
GLHEProSetupExportLoadsforGroundHeatExchangerSizing.new.registerWithApplication