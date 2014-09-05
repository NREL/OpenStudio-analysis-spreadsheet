class XcelEDAReportingandQAQC < OpenStudio::Ruleset::ReportingUserScript

  #have the xcel protocol set the reporting tolerance for deltaF (DOE2 has 0.55C tolerance - Brent suggests 0.55C for E+ too)
  #check the setpoints in the protocol
  #could we do a custom report to show the thermostat schedules? during occupied and unoccupied times

  #checks the number of unmet hours in the model
  def unmet_hrs_check

    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "Unmet Hours Check")
    check_elems << OpenStudio::Attribute.new("category", "General")
    check_elems << OpenStudio::Attribute.new("description", "Check that the heating and cooling systems are meeting their setpoints for the entire simulation period")
   
    #setup the queries
    heating_setpoint_unmet_query = "SELECT Value FROM TabularDataWithStrings WHERE (ReportName='SystemSummary') AND (ReportForString='Entire Facility') AND (TableName='Time Setpoint Not Met') AND (RowName = 'Facility') AND (ColumnName='During Heating')"
    cooling_setpoint_unmet_query = "SELECT Value FROM TabularDataWithStrings WHERE (ReportName='SystemSummary') AND (ReportForString='Entire Facility') AND (TableName='Time Setpoint Not Met') AND (RowName = 'Facility') AND (ColumnName='During Cooling')"
    
    #get the info
    heating_setpoint_unmet = @sql.execAndReturnFirstDouble(heating_setpoint_unmet_query)
    cooling_setpoint_unmet = @sql.execAndReturnFirstDouble(cooling_setpoint_unmet_query)
    
    #make sure all the data are availalbe
    if heating_setpoint_unmet.empty? or cooling_setpoint_unmet.empty?
      check_elems << OpenStudio::Attribute.new("flag", "Hours heating or cooling unmet data unavailable; check not run")
      @runner.registerWarning("Hours heating or cooling unmet data unavailable; check not run")
    end
    
    #aggregate heating and cooling hrs
    heating_or_cooling_setpoint_unmet = heating_setpoint_unmet.get + cooling_setpoint_unmet.get    
    #flag if heating + cooling unmet hours > 300
    if heating_or_cooling_setpoint_unmet > 300
      check_elems << OpenStudio::Attribute.new("flag", "Hours heating or cooling unmet is #{heating_or_cooling_setpoint_unmet}; > the Xcel EDA limit of 300 hrs")
      @runner.registerWarning("Hours heating or cooling unmet is #{heating_or_cooling_setpoint_unmet}; > the Xcel EDA limit of 300 hrs") 
    end

    check_elem = OpenStudio::Attribute.new("check", check_elems)
 
    return check_elem
    
  end

end  