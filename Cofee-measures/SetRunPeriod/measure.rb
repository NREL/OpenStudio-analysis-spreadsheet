#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SetRunPeriod < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetRunPeriod"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for your name
    begin_month = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("begin_month",true)
    begin_month.setDisplayName("Begin Month")
    args << begin_month

    #make an argument for your name
    begin_day = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("begin_day",true)
    begin_day.setDisplayName("Begin Day")
    args << begin_day

    #make an argument for your name
    end_month = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("end_month",true)
    end_month.setDisplayName("End Month")
    args << end_month

    #make an argument for your name
    end_day = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("end_day",true)
    end_day.setDisplayName("End Day")
    args << end_day

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
    # todo - When I have time validate that the dates is good.
    begin_month = runner.getIntegerArgumentValue("begin_month",user_arguments)
    begin_day = runner.getIntegerArgumentValue("begin_day",user_arguments)
    end_month = runner.getIntegerArgumentValue("end_month",user_arguments)
    end_day = runner.getIntegerArgumentValue("end_day",user_arguments)

    #reporting initial condition of model
    run_period = model.getRunPeriod
    runner.registerInitialCondition("The initial Run Period was from #{run_period.getBeginMonth}/#{run_period.getBeginDayOfMonth} to #{run_period.getEndMonth}/#{run_period.getEndDayOfMonth}.")

    # set run period based on user input
    run_period.setBeginMonth(begin_month)
    run_period.setBeginDayOfMonth(begin_day)
    run_period.setEndMonth(end_month)
    run_period.setEndDayOfMonth(end_day)

    #reporting final condition of model
    runner.registerFinalCondition("The final run period is from #{run_period.getBeginMonth}/#{run_period.getBeginDayOfMonth} to #{run_period.getEndMonth}/#{run_period.getEndDayOfMonth}.")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetRunPeriod.new.registerWithApplication