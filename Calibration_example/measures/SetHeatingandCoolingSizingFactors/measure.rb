#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SetHeatingandCoolingSizingFactors < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetHeatingandCoolingSizingFactors"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument to add heating sizing factor
    htg_sz_factor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("htg_sz_factor",true)
    htg_sz_factor.setDisplayName("Heating Sizing Factor (eg 1.25 = 125% of required heating capacity.")
    htg_sz_factor.setDefaultValue(1.25)
    args << htg_sz_factor
    
    #make an argument to add cooling sizing factor
    clg_sz_factor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("clg_sz_factor",true)
    clg_sz_factor.setDisplayName("Coolinig Sizing Factor (eg 1.15 = 115% of required cooling capacity.")
    clg_sz_factor.setDefaultValue(1.15)
    args << clg_sz_factor    
    
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
    htg_sz_factor = runner.getDoubleArgumentValue("htg_sz_factor",user_arguments)
    clg_sz_factor = runner.getDoubleArgumentValue("clg_sz_factor",user_arguments)
    
    #get the existing sizing parameters or make a new one as required
    siz_params = model.getSimulationControl.sizingParameters
    if siz_params.is_initialized
      siz_params = siz_params.get
    else
      siz_params_idf = OpenStudio::IdfObject.new OpenStudio::Model::SizingParameters::iddObjectType
      model.addObject siz_params_idf
      siz_params = model.getSimulationControl.sizingParameters.get
    end

    #report the initial condition
    orig_htg_sz_factor = siz_params.heatingSizingFactor
    orig_clg_sz_factor = siz_params.coolingSizingFactor
    runner.registerInitialCondition("Model started with htg sizing factor = #{orig_htg_sz_factor} and clg sizing factor = #{orig_clg_sz_factor}")    
    
    #set the sizing factors to the user specified values
    siz_params.setHeatingSizingFactor(htg_sz_factor)
    siz_params.setCoolingSizingFactor(clg_sz_factor)

    #report the final condition
    new_htg_sz_factor = siz_params.heatingSizingFactor
    new_clg_sz_factor = siz_params.coolingSizingFactor
    runner.registerFinalCondition("Model ended with htg sizing factor = #{new_htg_sz_factor} and clg sizing factor = #{new_clg_sz_factor}")  
  
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetHeatingandCoolingSizingFactors.new.registerWithApplication