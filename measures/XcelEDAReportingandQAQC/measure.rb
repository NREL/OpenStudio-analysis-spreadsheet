#start the measure
class XcelEDAReportingandQAQC < OpenStudio::Ruleset::ReportingUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "XcelEDAReportingandQAQC"
  end
  
  #define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)
    
    #make the runner a class variable
    @runner = runner
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

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

    #require the file that stores results
    require "#{File.dirname(__FILE__)}/CreateResults.rb"
    
    #require the qaqc checks
    require "#{File.dirname(__FILE__)}/EndUseBreakdown"
    require "#{File.dirname(__FILE__)}/EUI"
    require "#{File.dirname(__FILE__)}/FuelSwap"
    require "#{File.dirname(__FILE__)}/PeakHeatCoolMonth"
    require "#{File.dirname(__FILE__)}/UnmetHrs"
    
    #vector to store the results and checks
    report_elems = OpenStudio::AttributeVector.new
    report_elems << create_results
    
    #create an attribute vector to hold the checks
    check_elems = OpenStudio::AttributeVector.new

      #unmet hours check
      check_elems << unmet_hrs_check
         
      #energy use for cooling and heating as percentage of total energy check
      check_elems << enduse_pcts_check

      #peak heating and cooling months check
      check_elems << peak_heat_cool_mo_check

      #EUI check
      check_elems << eui_check
      
    #end checks
    report_elems << OpenStudio::Attribute.new("checks", check_elems)
    
    #create an extra layer of report.  the first level gets thrown away.
    top_level_elems = OpenStudio::AttributeVector.new
    top_level_elems << OpenStudio::Attribute.new("report", report_elems)   
    
    #create the report
    result = OpenStudio::Attribute.new("summary_report", top_level_elems)
    result.saveToXml(OpenStudio::Path.new("report.xml"))
      
    #reporting final condition
    #runner.registerFinalCondition("Goodbye.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
XcelEDAReportingandQAQC.new.registerWithApplication