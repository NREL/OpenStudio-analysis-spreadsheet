module OsLib_QAQC

  # include any general notes about QAQC method here

  #checks the number of unmet hours in the model
  def check_eui_by_end_use(category,target_standard,min_pass,max_pass)

    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "End Use by Category")
    check_elems << OpenStudio::Attribute.new("category", category)
    check_elems << OpenStudio::Attribute.new("description", "Check end use by category against #{target_standard} DOE prototype buildings.")

    begin

      # total building area
      query = 'SELECT Value FROM tabulardatawithstrings WHERE '
      query << "ReportName='AnnualBuildingUtilityPerformanceSummary' and "
      query << "ReportForString='Entire Facility' and "
      query << "TableName='Building Area' and "
      query << "RowName='Total Building Area' and "
      query << "ColumnName='Area' and "
      query << "Units='m2';"
      query_results = @sql.execAndReturnFirstDouble(query)
      if query_results.empty?
        check_elems << OpenStudio::Attribute.new("flag", "Can't calculate EUI, SQL query for building area failed.")
        return OpenStudio::Attribute.new("check", check_elems)
      else
        energy_plus_area = query_results.get
      end

      # temp code to check OS vs. E+ area
      open_studio_area = @model.getBuilding.floorArea
      if not (energy_plus_area - open_studio_area).abs < 0.1
        check_elems << OpenStudio::Attribute.new("flag", "EnergyPlus reported area is #{energy_plus_area} (m^2). OpenStudio reported area is #{@model.getBuilding.floorArea} (m^2).")
      end

      # loop through end uses and gather consumption, normalized by floor area
      actual_eui_by_end_use = {}
      OpenStudio::EndUseCategoryType.getValues.each do |end_use|
        # get end uses
        end_use = OpenStudio::EndUseCategoryType.new(end_use).valueDescription
        query_elec = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' and TableName='End Uses' and RowName= '#{end_use}' and ColumnName= 'Electricity'"
        query_gas = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' and TableName='End Uses' and RowName= '#{end_use}' and ColumnName= 'Natural Gas'"
        query_add = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' and TableName='End Uses' and RowName= '#{end_use}' and ColumnName= 'Additional Fuel'"
        query_dc = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' and TableName='End Uses' and RowName= '#{end_use}' and ColumnName= 'District Cooling'"
        query_dh = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' and TableName='End Uses' and RowName= '#{end_use}' and ColumnName= 'District Heating'"
        results_elec = @sql.execAndReturnFirstDouble(query_elec).get
        results_gas = @sql.execAndReturnFirstDouble(query_gas).get
        results_add = @sql.execAndReturnFirstDouble(query_add).get
        results_dc = @sql.execAndReturnFirstDouble(query_dc).get
        results_dh = @sql.execAndReturnFirstDouble(query_dh).get
        total_end_use = results_elec + results_gas + results_add + results_dc + results_dh

        # populate hash for actual end use normalized by area
        actual_eui_by_end_use[end_use] = total_end_use/energy_plus_area
      end

      # gather target end uses for given standard as hash
      target_eui_by_end_use = @model.find_target_eui_by_end_use(target_standard)

      # units for flag display text and unit conversion
      source_units = 'GJ/m^2'
      target_units = 'kBtu/ft^2'

      # check acutal vs. target against tolerance
      if not target_eui_by_end_use.nil?
        actual_eui_by_end_use.each do |end_use,value|

          # this should have value of 0 in model. This page change in the future. It doesn't exist in target lookup
          next if end_use == 'Exterior Equipment'

          # perform check and issue flags as needed
          target_value = target_eui_by_end_use[end_use]
          eui_ip_neat = OpenStudio.toNeatString(OpenStudio.convert(value, source_units, target_units).get, 5, true)
          target_eui_ip_neat = OpenStudio.toNeatString(OpenStudio.convert(target_value, source_units, target_units).get, 1, true)

          # add in use case specific logic to skip checks when near 0 actual and target
          skip = false
          if end_use == "Heat Recovery" and value < 0.05 and target_value < 0.05 then skip = true end
          if end_use == "Pumps" and value < 0.05 and target_value < 0.05 then skip = true end

          if value < target_value*(1.0 - min_pass) and not skip
            check_elems << OpenStudio::Attribute.new("flag", "#{end_use} EUI of #{eui_ip_neat} (#{target_units}) is less than #{min_pass*100} % below the expected #{end_use} EUI of #{target_eui_ip_neat} (#{target_units}) for #{target_standard}.")
          elsif value > target_value*(1.0 + max_pass) and not skip
            check_elems << OpenStudio::Attribute.new("flag", "#{end_use} EUI of #{eui_ip_neat} (#{target_units}) is more than #{max_pass*100} % above the expected #{end_use} EUI of #{target_eui_ip_neat} (#{target_units}) for #{target_standard}.")
          end
        end
      else
        check_elems << OpenStudio::Attribute.new("flag", "Can't calculate target end use EUIs. Make sure model has expected climate zone and building type.")
      end

    rescue => e
      # brief description of ruby error
      check_elems << OpenStudio::Attribute.new("flag", "Error prevented QAQC check from running (#{e}).")

      # backtrace of ruby error for diagnostic use
      #check_elems << OpenStudio::Attribute.new("flag", "#{e.backtrace.join("\n")}")
    end

    # add check_elms to new attribute
    check_elem = OpenStudio::Attribute.new("check", check_elems)

    return check_elem
    # note: registerWarning and registerValue will be added for checks downstream using os_lib_reporting_qaqc.rb

  end

end  