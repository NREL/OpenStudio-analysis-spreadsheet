class BadReportingMeasure < OpenStudio::Ruleset::ReportingUserScript
  def name
    return "BadReportingMeasure"
  end

  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    return args
  end

  def run(runner, user_arguments)
    super(runner, user_arguments)
    
    #make the runner a class variable
    @runner = runner
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    runner.registerInitialCondition("Starting Bad Reporting Measure")

    # get the last model and sql file
    @model = runner.lastOpenStudioModel
    if @model.is_initialized
      @model = @model.get
    else
      runner.registerError("Cannot find last model.")
      return false
    end
    
    @sql = runner.lastEnergyPlusSqlFile
    if @sql.is_initialized
      @sql = @sql.get
    else
      runner.registerError("Cannot find last sql file.")
      return false
    end

    value = 10 / 0

    runner.registerValue("undefined", value)
    fail "I failed"

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
BadReportingMeasure.new.registerWithApplication