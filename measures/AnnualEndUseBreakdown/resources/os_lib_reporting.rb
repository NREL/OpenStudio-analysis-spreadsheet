module OsLib_Reporting

  # setup - get model, sql, and setup web assets path
  def OsLib_Reporting.setup(runner)

    results = {}

    # get the last model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    # get the last sql file
    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    # populate hash to pass to measure
    results[:model] = model
    results[:sqlFile] = sqlFile
    results[:web_asset_path] = OpenStudio::getSharedResourcesPath() / OpenStudio::Path.new("web_assets")

    return results

  end

  def OsLib_Reporting.create_xls()

    require 'rubyXL'
    book = ::RubyXL::Workbook.new

    # delete initial worksheet

    return book
  end

  def OsLib_Reporting.save_xls(book)

    file = book.write 'excel-file.xlsx'

    return file
  end

  # write an Excel file from table data
  def OsLib_Reporting.write_xls(table_data,book)

    worksheet = book.add_worksheet table_data[:title]

    row_cnt = 0
    # write the header row
    header = table_data[:header]
    header.each_with_index do |h,i|
      worksheet.add_cell(row_cnt, i, h)
    end
    worksheet.change_row_fill(row_cnt, '0ba53d')

    # loop over data rows
    data = table_data[:data]
    data.each do |d|
      row_cnt += 1
      d.each_with_index do |c,i|
        worksheet.add_cell(row_cnt, i,c)
      end
    end

    return book

  end

  # cleanup - prep html and close sql
  def OsLib_Reporting.cleanup(html_in_path)

    # todo - would like to move code here, but couldn't get it working. May look at it again later on.

    return html_out_path

  end

  # create table with general building information
  def OsLib_Reporting.general_building_information_table(model,sqlFile,runner)

    # general building information type data output
    @general_building_information = {}
    @general_building_information[:title] = 'General Building Information'
    @general_building_information[:header] = ['Information','Value','Units']
    @general_building_information[:data] = []

    # structure ID / building name
    display = "Building Name"
    target_units = "building_name"
    value = model.getBuilding.name.to_s
    @general_building_information[:data] << [display,value,target_units]
    runner.registerValue(display,value,target_units)

    # net site energy
    display = "Net Site Energy"
    source_units = "GJ"
    target_units = "kBtu"
    value = OpenStudio::convert(sqlFile.netSiteEnergy.get,source_units,target_units).get
    value_neat = OpenStudio::toNeatString(value,0,true)
    @general_building_information[:data] << [display,value_neat,target_units]
    runner.registerValue(display,value,target_units)

    # total building area
    query = "SELECT Value FROM tabulardatawithstrings WHERE "
    query << "ReportName='AnnualBuildingUtilityPerformanceSummary' and " # Notice no space in SystemSummary
    query << "ReportForString='Entire Facility' and "
    query << "TableName='Building Area' and "
    query << "RowName='Total Building Area' and "
    query << "ColumnName='Area' and "
    query << "Units='m2';"
    query_results = sqlFile.execAndReturnFirstDouble(query)
    if query_results.empty?
      runner.registerError("Did not find value for total building area.")
      return false
    else
      display = "Total Building Area"
      source_units = "m^2"
      target_units = "ft^2"
      value = OpenStudio::convert(query_results.get,source_units,target_units).get
      value_neat = OpenStudio::toNeatString(value,0,true)
      @general_building_information[:data] << [display,value_neat,target_units]
      runner.registerValue(display,value,target_units)
    end

    #EUI
    eui =  sqlFile.netSiteEnergy.get / query_results.get
    display = "EUI"
    source_units = "GJ/m^2"
    target_units = "kBtu/ft^2"
    value = OpenStudio::convert(eui,source_units,target_units).get
    value_neat = OpenStudio::toNeatString(value,2,true)
    @general_building_information[:data] << [display,value_neat,target_units]
    runner.registerValue(display,value,target_units)

    return @general_building_information

  end

  # create table of space type breakdown
  def OsLib_Reporting.output_data_space_type_breakdown_table(model,sqlFile,runner)

    # space type data output
    @output_data_space_type_breakdown = {}
    @output_data_space_type_breakdown[:title] = 'Space Type Breakdown'
    @output_data_space_type_breakdown[:header] = ['Space Type Name','Floor Area','Units']
    @output_data_space_type_breakdown[:data] = []

    # create array for space type graph data
    data_spaceType = []

    space_types = model.getSpaceTypes

    space_types.sort.each do |spaceType|

      next if spaceType.floorArea == 0

      # get color
      color = spaceType.renderingColor
      if not color.empty?
        color = color.get
        red = color.renderingRedValue
        green = color.renderingGreenValue
        blue = color.renderingBlueValue
        color = "rgb(#{red},#{green},#{blue})"
      else
        # todo - this should set red green and blue as separate values
        color = "rgb(20,20,20)" #maybe do random or let d3 pick color instead of this?
      end

      # data for space type breakdown
      display = spaceType.name.get
      floor_area_si = spaceType.floorArea
      value = OpenStudio::convert(floor_area_si,"m^2","ft^2").get
      num_people = nil
      value_neat = OpenStudio::toNeatString(value,0,true)
      units = "ft^2"
      @output_data_space_type_breakdown[:data] << [display,value_neat,units]
      runner.registerValue("Space Type - #{display}",value,units)

      # data for graph
      temp_array = ['{"label":"',display,'", "value":',value,', "color":"',color,'"}']
      data_spaceType << temp_array.join
    end

    spaces = model.getSpaces

    #count area of spaces that have no space type
    no_space_type_area_counter = 0

    spaces.each do |space|
      if space.spaceType.empty?
        no_space_type_area_counter = no_space_type_area_counter + space.floorArea
      end
    end

    if no_space_type_area_counter > 0
      display = "No Space Type"
      value = OpenStudio::convert(no_space_type_area_counter,"m^2","ft^2").get
      value_neat = OpenStudio::toNeatString(value,0,true)
      units = "ft^2"
      @output_data_space_type_breakdown[:data] << [display,value_neat,units]
      runner.registerValue("Space Type - #{display}",value,units)

      # data for graph
      color = "rgb(20,20,20)" #maybe do random or let d3 pick color instead of this?
      temp_array = ['{"label":"','No SpaceType Assigned','", "value":',OpenStudio::convert(no_space_type_area_counter,"m^2","ft^2"),',"color":"',color,'"}']
      data_spaceType << temp_array.join
    end

    # final graph data for space type breakdown
    @output_data_space_type_breakdown[:chart] = data_spaceType.join(",")

    return @output_data_space_type_breakdown
  end

  # create table and pie chart with end use data
  def OsLib_Reporting.output_data_end_use_table_pie_data(model,sqlFile,runner)

    # end use data output
    @output_data_end_use = {}
    @output_data_end_use[:title] = 'LEED Summary - EAp2-18. End Use Percentage'
    @output_data_end_use[:header] = ['End Use','Percentage','Units']
    @output_data_end_use[:data] = []

    # create array for end use graph data
    data_endUse = []

    # list of lead end uses
    end_use_leed_cats = []
    end_use_leed_cats << "Interior Lighting"
    end_use_leed_cats << "Space Heating"
    end_use_leed_cats << "Space Cooling"
    end_use_leed_cats << "Fans-Interior"
    end_use_leed_cats << "Service Water Heating"
    end_use_leed_cats << "Receptacle Equipment"
    end_use_leed_cats << "Miscellaneous"

    #list of colors per end uses matching standard report
    end_use_leed_cat_colors = []
    end_use_leed_cat_colors << "#F7DF10" # interior lighting
    end_use_leed_cat_colors << "#EF1C21" # heating
    end_use_leed_cat_colors << "#0071BD" # cooling
    end_use_leed_cat_colors << "#FF79AD" # fans
    end_use_leed_cat_colors << "#FFB239" # water systems
    end_use_leed_cat_colors << "#4A4D4A" # interior equipment
    end_use_leed_cat_colors << "#669933" # misc - not from standard report

    # loop through end uses from LEED end use percentage table
    end_use_leed_cats.length.times do |i|
      # Retrieve end use percentages from LEED table
      query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='LEEDsummary' and RowName= '#{end_use_leed_cats[i]}' and ColumnName='Percent' and Units='%';"
      end_use_leed_value = sqlFile.execAndReturnFirstDouble(query)
      if end_use_leed_value.empty?
        runner.registerError("Did not find value for #{end_use_leed_cats[i]}.")
        return false
      else
        display = end_use_leed_cats[i]
        source_units = "%"
        target_units = "%"
        value = end_use_leed_value.get
        value_neat = OpenStudio::toNeatString(value,2,true)
        @output_data_end_use[:data] << [display,value_neat,target_units]
        runner.registerValue("End Use - #{display}",value,target_units)

        # populate data for graph if non-zero
        if end_use_leed_value.get > 0
          temp_array = ['{"label":"',end_use_leed_cats[i],'", "value":',end_use_leed_value.get,', "color":"',end_use_leed_cat_colors[i],'"}']
          data_endUse << temp_array.join
        end
      end
    end # end_use_leed_cats.each do

    # final graph data
    @output_data_end_use[:chart] = data_endUse.join(",")

    return @output_data_end_use

  end

  # create table and pie chart with electricity end use data
  def OsLib_Reporting.output_data_end_use_electricity_table_pie_data(model,sqlFile,runner)

    # end use data output
    @output_data_end_use_electricity = {}
    @output_data_end_use_electricity[:title] = 'LEED Summary - EAp2-17a. Energy Use Intensity - Electricity'
    @output_data_end_use_electricity[:header] = ['End Use','Consumption','Units']
    @output_data_end_use_electricity[:data] = []

    # create array for end use graph data
    data_endUse = []

    # list of lead end uses
    end_use_leed_cats = []
    end_use_leed_cats << "Interior Lighting"
    end_use_leed_cats << "Space Heating"
    end_use_leed_cats << "Space Cooling"
    end_use_leed_cats << "Fans-Interior"
    end_use_leed_cats << "Service Water Heating"
    end_use_leed_cats << "Receptacle Equipment"
    end_use_leed_cats << "Miscellaneous"

    #list of colors per end uses matching standard report
    end_use_leed_cat_colors = []
    end_use_leed_cat_colors << "#F7DF10" # interior lighting
    end_use_leed_cat_colors << "#EF1C21" # heating
    end_use_leed_cat_colors << "#0071BD" # cooling
    end_use_leed_cat_colors << "#FF79AD" # fans
    end_use_leed_cat_colors << "#FFB239" # water systems
    end_use_leed_cat_colors << "#4A4D4A" # interior equipment
    end_use_leed_cat_colors << "#669933" # misc - not from standard report

    # loop through end uses from LEED end use percentage table
    end_use_leed_cats.length.times do |i|
      # Retrieve end use percentages from LEED table
      query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='LEEDsummary' and RowName= '#{end_use_leed_cats[i]}' and ColumnName='Electricty' and Units='MJ/m2';"
      end_use_leed_value = sqlFile.execAndReturnFirstDouble(query)
      if end_use_leed_value.empty?
        runner.registerError("Did not find value for #{end_use_leed_cats[i]}.")
        return false
      else
        display = end_use_leed_cats[i]
        source_units = "MJ/m^2"
        target_units = "kWh/ft^2"
        value = end_use_leed_value.get * 0.2778 / OpenStudio::convert(1.0,"m^2","ft^2").get # value * energy conversion / area conversion
        value_neat = OpenStudio::toNeatString(value,2,true)
        @output_data_end_use_electricity[:data] << [display,value_neat,target_units]
        runner.registerValue("End Use Electricity - #{display}",value,target_units)

        # populate data for graph if non-zero
        if end_use_leed_value.get > 0
          temp_array = ['{"label":"',end_use_leed_cats[i],'", "value":',end_use_leed_value.get,', "color":"',end_use_leed_cat_colors[i],'"}']
          data_endUse << temp_array.join
        end
      end
    end # end_use_leed_cats.each do

    # final graph data
    @output_data_end_use_electricity[:chart] = data_endUse.join(",")

    return @output_data_end_use_electricity

  end

  # create table and pie chart with natural gas end use data
  def OsLib_Reporting.output_data_end_use_gas_table_pie_data(model,sqlFile,runner)

    # end use data output
    @output_data_end_use_gas = {}
    @output_data_end_use_gas[:title] = 'LEED Summary - EAp2-17b. Energy Use Intensity - Natural Gas'
    @output_data_end_use_gas[:header] = ['End Use','Consumption','Units']
    @output_data_end_use_gas[:data] = []

    # create array for end use graph data
    data_endUse = []

    # list of lead end uses
    end_use_leed_cats = []
    end_use_leed_cats << "Space Heating"
    end_use_leed_cats << "Service Water Heating"
    end_use_leed_cats << "Miscellaneous"

    #list of colors per end uses matching standard report
    end_use_leed_cat_colors = []
    end_use_leed_cat_colors << "#EF1C21" # heating
    end_use_leed_cat_colors << "#FFB239" # water systems
    end_use_leed_cat_colors << "#669933" # misc - not from standard report

    # loop through end uses from LEED end use percentage table
    end_use_leed_cats.length.times do |i|
      # Retrieve end use percentages from LEED table
      query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='LEEDsummary' and RowName= '#{end_use_leed_cats[i]}' and ColumnName='Natural Gas' and Units='MJ/m2';"
      end_use_leed_value = sqlFile.execAndReturnFirstDouble(query)
      if end_use_leed_value.empty?
        runner.registerError("Did not find value for #{end_use_leed_cats[i]}.")
        return false
      else
        display = end_use_leed_cats[i]
        source_units = "MJ/m^2"
        target_units = "therms/ft^2"
        value = (end_use_leed_value.get * 0.009478) / OpenStudio::convert(1.0,"m^2","ft^2").get # value * energy conversion / area conversion
        value_neat = OpenStudio::toNeatString(value,2,true)
        @output_data_end_use_gas[:data] << [display,value_neat,target_units]
        runner.registerValue("End Use Natural Gas - #{display}",value,target_units)

        # populate data for graph if non-zero
        if end_use_leed_value.get > 0
          temp_array = ['{"label":"',end_use_leed_cats[i],'", "value":',end_use_leed_value.get,', "color":"',end_use_leed_cat_colors[i],'"}']
          data_endUse << temp_array.join
        end
      end
    end # end_use_leed_cats.each do

    # final graph data
    @output_data_end_use_gas[:chart] = data_endUse.join(",")

    return @output_data_end_use_gas

  end

  # create table and pie chart with energy use data
  def OsLib_Reporting.output_data_energy_use_table_pie_data(model,sqlFile,runner)

    # energy use data output
    @output_data_energy_use = {}
    @output_data_energy_use[:title] = 'LEED Summary - EAp2-6. Energy Use Summary'
    @output_data_energy_use[:header] = ['Fuel','Value','Units']
    @output_data_energy_use[:data] = []

    # create array for end use graph data
    data_energyUse = []

    # list of lead end uses
    energy_use_leed_cats = []
    energy_use_leed_cats << "Electricity"
    energy_use_leed_cats << "Natural Gas"
    energy_use_leed_cats << "Additional"
    #energy_use_leed_cats << "Total"

    #list of colors per end uses matching standard report
    color = []
    color << "#1f77b4" # electricity
    color << "#aec7e8" # natural gas
    color << "#ff7f0e" # additional

    # loop through end uses from LEED end use percentage table
    counter = 0
    energy_use_leed_cats.each do |energyUseLeedCat|
      # Retrieve end use percentages from LEED table
      query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='LEEDsummary' and RowName= '#{energyUseLeedCat}' and ColumnName='Total Energy Use' and Units='GJ';"
      energy_use_leed_value = sqlFile.execAndReturnFirstDouble(query)
      if energy_use_leed_value.empty?
        runner.registerError("Did not find value for #{energyUseLeedCat}.")
        return false
      else
        display = energyUseLeedCat
        source_units = "GJ"

        # target units will be different for each fuel type
        if energyUseLeedCat == "Electricity"
          target_units = "kWh"
          value = energy_use_leed_value.get * 0.2778 # value * energy conversion
        elsif energyUseLeedCat == "Natural Gas"
          target_units = "therms"
          value = energy_use_leed_value.get * 9.478 # value * energy conversion
        else
          target_units = "kBtu"
          value = OpenStudio::convert(energy_use_leed_value.get,"GJ","kBtu").get
        end

        value_neat = OpenStudio::toNeatString(value,2,true)
        @output_data_energy_use[:data] << [display,value_neat,target_units]
        runner.registerValue("Fuel - #{display}",value,target_units)
        if energy_use_leed_value.get > 0
          temp_array = ['{"label":"',energyUseLeedCat,'", "value":',energy_use_leed_value.get,', "color":"',color[counter],'"}']
          data_energyUse << temp_array.join
        end
        counter =+ 1
      end
    end # energy_use_leed_cats.each do

    # final graph data
    @output_data_energy_use[:chart] = data_energyUse.join(",")

    return @output_data_energy_use

  end

  # create table for advisory messages
  def OsLib_Reporting.advisory_messages_table(model,sqlFile,runner)

    # unmet hours data output
    @advisory_messages = {}
    @advisory_messages[:title] = 'LEED Summary - EAp2-2. Advisory Messages'
    @advisory_messages[:header] = ['Message','Value','Units']
    @advisory_messages[:data] = []

    # create strign for LEED advisories
    advisories_leed = []
    advisories_leed << "Number of hours heating loads not met"
    advisories_leed << "Number of hours cooling loads not met"
    advisories_leed << "Number of hours not met"

    # loop through advisory messages
    advisories_leed.each do |advisoryLeed|
      # Retrieve end use percentages from LEED table
      query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='LEEDsummary' and RowName= '#{advisoryLeed}' and ColumnName='Data';"
      advisories_leed_value = sqlFile.execAndReturnFirstDouble(query)
      if advisories_leed_value.empty?
        runner.registerError("Did not find value for #{advisoryLeed}.")
        return false
      else
        # net site energy
        display = advisoryLeed
        source_units = "hr"
        target_units = "hr"
        value = advisories_leed_value.get
        value_neat = value #OpenStudio::toNeatString(value,0,true)
        @advisory_messages[:data] << [display,value_neat,target_units]
        runner.registerValue("Unmet Hours - #{display}",value,target_units)

      end
    end # advisories_leed.each do

    return @advisory_messages

  end

  # summary of what to show for each type of air loop component
  def OsLib_Reporting.air_loop_component_summary_logic(component,model)

    if component.to_AirLoopHVACOutdoorAirSystem.is_initialized
      component = component.to_AirLoopHVACOutdoorAirSystem.get
      #get ControllerOutdoorAir
      controller_oa = component.getControllerOutdoorAir

      sizing_source_units = "m^3/s"
      sizing_target_units = "cfm"
      if controller_oa.maximumOutdoorAirFlowRate.is_initialized
        sizing_ip = OpenStudio.convert(controller_oa.maximumOutdoorAirFlowRate.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = "m^3/s"
      value_target_units = "cfm"
      if controller_oa.minimumOutdoorAirFlowRate.is_initialized
        value_ip = OpenStudio.convert(controller_oa.minimumOutdoorAirFlowRate.get,value_source_units,value_target_units).get
        value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
      else
        value_ip_neat = "Autosized"
      end
      @output_data_air_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,"Minimum Outdoor Air Flow Rate",value_ip_neat,value_target_units,""]

    elsif component.to_CoilCoolingDXSingleSpeed.is_initialized
      component = component.to_CoilCoolingDXSingleSpeed.get
      sizing_source_units = "W"
      sizing_target_units = "Btu/h"
      if component.ratedTotalCoolingCapacity.is_initialized
        sizing_ip = OpenStudio.convert(component.ratedTotalCoolingCapacity.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = "COP"
      value_target_units = "COP"
      value_ip = component.ratedCOP.get
      value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
      description = "Rated COP"
      @output_data_air_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,description,value_ip_neat,value_target_units,""]

    elsif component.to_CoilCoolingDXTwoSpeed.is_initialized
      component = component.to_CoilCoolingDXTwoSpeed.get

      # high speed
      sizing_source_units = "W"
      sizing_target_units = "Btu/h"
      if component.ratedHighSpeedTotalCoolingCapacity.is_initialized
        sizing_ip = OpenStudio.convert(component.ratedHighSpeedTotalCoolingCapacity.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = "COP"
      value_target_units = "COP"
      value_ip = component.ratedHighSpeedCOP.get
      value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
      description = "Rated COP"
      @output_data_air_loops[:data] <<  ["#{component.iddObject.name} - HighSpeed",sizing_ip_neat,sizing_target_units,description,value_ip_neat,value_target_units,""]

      # low speed
      sizing_source_units = "W"
      sizing_target_units = "Btu/h"
      if component.ratedLowSpeedTotalCoolingCapacity.is_initialized
        sizing_ip = OpenStudio.convert(component.ratedLowSpeedTotalCoolingCapacity.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = "COP"
      value_target_units = "COP"
      value_ip = component.ratedLowSpeedCOP.get
      value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
      description = "Rated COP"
      @output_data_air_loops[:data] <<  ["#{component.iddObject.name} (cont) - LowSpeed",sizing_ip_neat,sizing_target_units,description,value_ip_neat,value_target_units,""]

    elsif component.iddObject.name == "OS:Coil:Cooling:Water"
      component = component.to_CoilCoolingWater.get
      sizing_source_units = "m^3/s"
      sizing_target_units = "gal/min"
      if component.designWaterFlowRate.is_initialized
        sizing_ip = OpenStudio.convert(component.designWaterFlowRate.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value = component.plantLoop.get.name
      description = "Plant Loop"
      @output_data_air_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,description,value,"",""]

    elsif component.to_CoilHeatingGas.is_initialized
      component = component.to_CoilHeatingGas.get
      sizing_source_units = "W"
      sizing_target_units = "Btu/h"
      if component.nominalCapacity.is_initialized
        sizing_ip = OpenStudio.convert(component.nominalCapacity.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = ""
      value_target_units = ""
      value_ip = component.gasBurnerEfficiency
      value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
      description = "Gas Burner Efficiency"
      @output_data_air_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,description,value_ip_neat,value_target_units,""]

    elsif component.to_CoilHeatingElectric.is_initialized
      component = component.to_CoilHeatingElectric.get
      sizing_source_units = "W"
      sizing_target_units = "Btu/h"
      if component.nominalCapacity.is_initialized
        sizing_ip = OpenStudio.convert(component.nominalCapacity.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = ""
      value_target_units = ""
      value_ip = component.efficiency
      value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
      description = "Efficiency"
      @output_data_air_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,description,value_ip_neat,value_target_units,""]

    elsif component.to_CoilHeatingDXSingleSpeed.is_initialized
      component = component.to_CoilHeatingDXSingleSpeed.get
      sizing_source_units = "W"
      sizing_target_units = "Btu/h"
      if component.ratedTotalHeatingCapacity.is_initialized
        sizing_ip = OpenStudio.convert(component.ratedTotalHeatingCapacity.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = "COP"
      value_target_units = "COP"
      value_ip = component.ratedCOP # is optional for CoilCoolingDXSingleSpeed but is just a double for CoilHeatingDXSingleSpeed
      value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
      description = "Rated COP"
      @output_data_air_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,description,value_ip_neat,value_target_units,""]

    elsif component.to_CoilHeatingWater.is_initialized
      component = component.to_CoilHeatingWater.get
      sizing_source_units = "m^3/s"
      sizing_target_units = "gal/min"
      if component.maximumWaterFlowRate.is_initialized
        sizing_ip = OpenStudio.convert(component.maximumWaterFlowRate.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value = component.plantLoop.get.name
      description = "Plant Loop"
      @output_data_air_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,description,value,"",""]

    elsif component.to_FanConstantVolume.is_initialized
      component = component.to_FanConstantVolume.get
      sizing_source_units = "m^3/s"
      sizing_target_units = "cfm"
      if component.maximumFlowRate.is_initialized
        sizing_ip = OpenStudio.convert(component.maximumFlowRate.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = "Pa"
      value_target_units = "inH_{2}O"
      value_ip = OpenStudio.convert(component.pressureRise,value_source_units,value_target_units).get
      value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
      @output_data_air_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,"Pressure Rise",value_ip_neat,value_target_units,""]

    elsif component.to_FanVariableVolume.is_initialized
      component = component.to_FanVariableVolume.get
      sizing_source_units = "m^3/s"
      sizing_target_units = "cfm"
      if component.maximumFlowRate.is_initialized
        sizing_ip = OpenStudio.convert(component.maximumFlowRate.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = "Pa"
      value_target_units = "inH_{2}O"
      value_ip = OpenStudio.convert(component.pressureRise,value_source_units,value_target_units).get
      value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
      @output_data_air_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,"Pressure Rise",value_ip_neat,value_target_units,""]

    elsif component.iddObject.name == "OS:SetpointManager:Scheduled"
      setpoint = component.to_SetpointManagerScheduled.get
      supply_air_temp_schedule = setpoint.schedule
      schedule_values = OsLib_Schedules.getMinMaxAnnualProfileValue(model, supply_air_temp_schedule)
      if schedule_values.nil?
        schedule_values_pretty = "can't inspect schedule"
        target_units = ""
      else
        if setpoint.controlVariable.to_s == "Temperature"
          source_units = "C"
          target_units = "F"
          schedule_values_pretty = "#{OpenStudio.convert(schedule_values["min"],source_units,target_units).get.round(1)} to #{OpenStudio.convert(schedule_values["max"],source_units,target_units).get.round(1)}"
        else # todo - add support for other control variables
          schedule_values_pretty = "#{schedule_values["min"]} to #{schedule_values["max"]}"
          target_units = "raw si values"
        end
      end
      @output_data_air_loops[:data] <<  [setpoint.iddObject.name,"","","Control Variable - #{setpoint.controlVariable}",schedule_values_pretty,target_units,""]

    elsif component.iddObject.name == "OS:SetpointManager:SingleZone:Reheat"
      setpoint = component.to_SetpointManagerSingleZoneReheat.get
      control_zone = setpoint.controlZone
      if control_zone.is_initialized
        control_zone_name = control_zone.get.name
      else
        control_zone_name = ""
      end
      @output_data_air_loops[:data] <<  [setpoint.iddObject.name,"","","Control Zone",control_zone_name,"",""]

    else
      @output_data_air_loops[:data] <<  [component.iddObject.name,"","","","","",""]
    end

    # todo - add support for more types of objects

    # thermal zones and terminals are handled directly in the air loop helper
    # since they operate over a collection of objects vs. a single component

    # nothing to return

  end

  # create table air loop summary
  def OsLib_Reporting.output_data_air_loops_table(model,sqlFile,runner)

    # air loop data output
    @output_data_air_loops = {}
    @output_data_air_loops[:title] = 'Air Loop Summary'
    @output_data_air_loops[:header] = ['Object','Sizing', 'Sizing Units','Description','Value', 'Value Units', 'Count']
    @output_data_air_loops[:data] = []
    model.getAirLoopHVACs.sort.each do |air_loop|
      @output_data_air_loops[:data] << ["<b><i><font color = Blue >#{air_loop.name}</font></i></b>","","","","","",""]
      @output_data_air_loops[:data] << ["<i><font color = Blue >(supply)</font></i>","","","","","",""]

      # hold values for later use
      dcv_setting = "na" # should hit this if there isn't an outdoor air object on the loop
      economizer_setting = "na" # should hit this if there isn't an outdoor air object on the loop

      # loop through components
      air_loop.supplyComponents.each do |component|

        #skip some object types, but look for node with setpoint manager
        if component.to_Node.is_initialized
          setpoint_managers = component.to_Node.get.setpointManagers
          if setpoint_managers.size > 0
            # setpoint type
            setpoint = setpoint_managers[0] # todo - could have more than one in some situations
            OsLib_Reporting.air_loop_component_summary_logic(setpoint,model)
          end
        else
          # populate table for everything but setpoint managers, which are added above.
          OsLib_Reporting.air_loop_component_summary_logic(component,model)
        end

        # gather controls information to use later
        if component.to_AirLoopHVACOutdoorAirSystem.is_initialized
          hVACComponent = component.to_AirLoopHVACOutdoorAirSystem.get

          #get ControllerOutdoorAir
          controller_oa = hVACComponent.getControllerOutdoorAir
          #get ControllerMechanicalVentilation
          controller_mv = controller_oa.controllerMechanicalVentilation
          # get dcv value
          dcv_setting = controller_mv.demandControlledVentilation
          # get economizer setting
          economizer_setting =  controller_oa.getEconomizerControlType
        end

      end

      @output_data_air_loops[:data] << ["<i><font color = Blue >(demand)</font></i>","","","","","",""]
      # demand side summary, list of terminal types used, and number of zones
      thermal_zones = []
      terminals = []
      cooling_temp_ranges = []
      heating_temps_ranges = []
      air_loop.demandComponents.each do |component|
        # gather array of thermal zones and terminals
        if component.to_ThermalZone.is_initialized
          thermal_zone = component.to_ThermalZone.get
          thermal_zones << thermal_zone
          thermal_zone.equipment.each do |zone_equip|
            next if zone_equip.to_ZoneHVACComponent.is_initialized # should only find terminals
            terminals << zone_equip.iddObject.name
          end

          # populate thermostat ranges
          if thermal_zone.thermostatSetpointDualSetpoint.is_initialized
            thermostat = thermal_zone.thermostatSetpointDualSetpoint.get
            if thermostat.coolingSetpointTemperatureSchedule.is_initialized
              schedule_values = OsLib_Schedules.getMinMaxAnnualProfileValue(model, thermostat.coolingSetpointTemperatureSchedule.get)
              if !schedule_values["min"].nil? then cooling_temp_ranges << schedule_values["min"] end
              if !schedule_values["max"].nil? then cooling_temp_ranges << schedule_values["max"] end
            end
            if thermostat.heatingSetpointTemperatureSchedule.is_initialized
              schedule_values = OsLib_Schedules.getMinMaxAnnualProfileValue(model, thermostat.heatingSetpointTemperatureSchedule.get)
              if !schedule_values["min"].nil? then heating_temps_ranges << schedule_values["min"] end
              if !schedule_values["max"].nil? then heating_temps_ranges << schedule_values["max"] end
            end
          end

        end
      end

      # get floor area of thermal zones
      total_loop_floor_area =  0
      thermal_zones.each do |zone|
        total_loop_floor_area += zone.floorArea
      end
      total_loop_floor_area_ip = OpenStudio::convert(total_loop_floor_area,"m^2","ft^2").get
      total_loop_floor_area_ip_neat = OpenStudio::toNeatString(total_loop_floor_area_ip,0,true)

      # output zone and terminal data
      @output_data_air_loops[:data] << ['Thermal Zones',"","","Total Floor Area",total_loop_floor_area_ip_neat,"ft^2",thermal_zones.size]
      if cooling_temp_ranges.size == 0
        cooling_temp_ranges_pretty = "can't inspect schedules"
      else
        cooling_temp_ranges_pretty = "#{OpenStudio.convert(cooling_temp_ranges.min,"C","F").get.round(1)} to #{OpenStudio.convert(cooling_temp_ranges.max,"C","F").get.round(1)}"
      end
      if heating_temps_ranges.size == 0
        heating_temps_ranges_pretty = "can't inspect schedules"
      else
        heating_temps_ranges_pretty = "#{OpenStudio.convert(heating_temps_ranges.min,"C","F").get.round(1)} to #{OpenStudio.convert(heating_temps_ranges.max,"C","F").get.round(1)}"
      end
      @output_data_air_loops[:data] << ['Thermal Zones',"","","thermostat ranges for heating",cooling_temp_ranges_pretty,"F",""]
      @output_data_air_loops[:data] << ['Thermal Zones',"","","thermostat ranges for cooling",heating_temps_ranges_pretty,"F",""]
      @output_data_air_loops[:data] << ['Terminal Types Used',"","",terminals.uniq.sort.join(", "),"","",terminals.size]

      # controls summary
      @output_data_air_loops[:data] << ["<i><font color = Blue >(controls)</font></i>","","","","","",""]

      @output_data_air_loops[:data] << ['HVAC Operation Schedule',"","","",air_loop.availabilitySchedule.name,"",""] # I think this is a bool
      @output_data_air_loops[:data] << ['Night Cycle Setting',"","","",air_loop.nightCycleControlType,"Choice",""]
      @output_data_air_loops[:data] << ['Economizer Setting',"","","",economizer_setting,"Choice",""]
      @output_data_air_loops[:data] << ['Demand Controlled Ventilation Status',"","","",dcv_setting,"Bool",""]

      # blank row at the end of each loop
      @output_data_air_loops[:data] << ["","","","","","",""]

    end

    return @output_data_air_loops

  end

  # summary of what to show for each type of plant loop component
  def OsLib_Reporting.plant_loop_component_summary_logic(component,model)

    if component.to_PumpConstantSpeed.is_initialized
      component = component.to_PumpConstantSpeed.get
      sizing_source_units = "m^3/s"
      sizing_target_units = "gal/min"
      if component.ratedFlowRate.is_initialized
        sizing_ip = OpenStudio.convert(component.ratedFlowRate.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = "Pa"
      value_target_units = "W"
      if component.ratedFlowRate.is_initialized
        value_ip = OpenStudio.convert(component.ratedFlowRate.get,sizing_source_units,sizing_target_units).get
        value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
      else
        value_ip_neat = "Autosized"
      end
      description = "Rated Power Consumption"
      @output_data_plant_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,description,value_ip_neat,value_target_units,""]

    elsif component.to_PumpVariableSpeed.is_initialized
      component = component.to_PumpVariableSpeed.get
      sizing_source_units = "m^3/s"
      sizing_target_units = "gal/min"
      if component.ratedFlowRate.is_initialized
        sizing_ip = OpenStudio.convert(component.ratedFlowRate.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = "Pa"
      value_target_units = "W"
      if component.ratedFlowRate.is_initialized
        value_ip = OpenStudio.convert(component.ratedFlowRate.get,sizing_source_units,sizing_target_units).get
        value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
      else
        value_ip_neat = "Autosized"
      end
      description = "Rated Power Consumption"
      @output_data_plant_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,description,value_ip_neat,value_target_units,""]

    elsif component.to_BoilerHotWater.is_initialized
      component = component.to_BoilerHotWater.get
      sizing_source_units = "W"
      sizing_target_units = "Btu/h"
      if component.nominalCapacity.is_initialized
        sizing_ip = OpenStudio.convert(component.nominalCapacity.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = "fraction"
      value_target_units = "fraction"
      value = component.nominalThermalEfficiency
      value_neat = OpenStudio.toNeatString(value,2,true)
      description = "Nominal Thermal Efficiency"
      @output_data_plant_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,description,value_neat,value_target_units,""]

    elsif component.to_WaterHeaterMixed.is_initialized
      component = component.to_WaterHeaterMixed.get
      sizing_source_units = "m^3"
      sizing_target_units = "gal"
      if component.tankVolume.is_initialized
        sizing_ip = OpenStudio.convert(component.tankVolume.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,0,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = "fraction"
      value_target_units = "fraction"
      value = component.heaterThermalEfficiency
      if value.is_initialized
        value_neat = OpenStudio.toNeatString(value.get,2,true)
      else
        value_neat = "" # not sure what that would default to if it wasn't there
      end
      description = "Heater Thermal Efficiency"
      @output_data_plant_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,description,value_neat,value_target_units,""]

    elsif component.to_ChillerElectricEIR.is_initialized
      component = component.to_ChillerElectricEIR.get
      sizing_source_units = "W"
      sizing_target_units = "Btu/h"
      if component.referenceCapacity.is_initialized
        sizing_ip = OpenStudio.convert(component.referenceCapacity.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value = component.referenceCOP
      value_neat = OpenStudio.toNeatString(value,2,true)
      description = "Reference COP"
      @output_data_plant_loops[:data] <<  [component.iddObject.name,sizing_ip_neat,sizing_target_units,description,value_neat,"",""]

      # second line to indicate if water or air cooled
      if component.secondaryPlantLoop.is_initialized
        @output_data_plant_loops[:data] <<  ["#{component.iddObject.name} (cont)","","","Chiller Source",component.secondaryPlantLoop.get.name,"",""]
      else
        @output_data_plant_loops[:data] <<  ["#{component.iddObject.name} (cont)","","","Chiller Source","Air Cooled","",""]
      end


    elsif component.to_CoolingTowerSingleSpeed.is_initialized

      # data for water
      component = component.to_CoolingTowerSingleSpeed.get
      sizing_source_units = "m^3/s"
      sizing_target_units = "gal/min"
      if component.designWaterFlowRate.is_initialized
        sizing_ip = OpenStudio.convert(component.designWaterFlowRate.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      @output_data_plant_loops[:data] <<  ["#{component.iddObject.name} - Air",sizing_ip_neat,sizing_target_units,"","","",""]

      # data for air
      component = component.to_CoolingTowerSingleSpeed.get
      sizing_source_units = "m^3/s"
      sizing_target_units = "cfm"
      if component.designAirFlowRate.is_initialized
        sizing_ip = OpenStudio.convert(component.designAirFlowRate.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = "W"
      value_target_units = "W"
      if component.fanPoweratDesignAirFlowRate.is_initialized
        value_ip = OpenStudio.convert(component.fanPoweratDesignAirFlowRate.get,sizing_source_units,sizing_target_units).get
        value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
      else
        value_ip_neat = "Autosized"
      end
      description = "Fan Power at Design Air Flow Rate"
      @output_data_plant_loops[:data] <<  ["#{component.iddObject.name} (cont) - Water",sizing_ip_neat,sizing_target_units,description,value_ip_neat,value_target_units,""]

    elsif component.to_SetpointManagerScheduled.is_initialized
      setpoint = component.to_SetpointManagerScheduled.get
      supply_air_temp_schedule = setpoint.schedule
      schedule_values = OsLib_Schedules.getMinMaxAnnualProfileValue(model, supply_air_temp_schedule)
      if schedule_values.nil?
        schedule_values_pretty = "can't inspect schedule"
        target_units = ""
      else
        if setpoint.controlVariable.to_s == "Temperature"
          source_units = "C"
          target_units = "F"
          schedule_values_pretty = "#{OpenStudio.convert(schedule_values["min"],source_units,target_units).get.round(1)} to #{OpenStudio.convert(schedule_values["max"],source_units,target_units).get.round(1)}"
        else # todo - add support for other control variables
          schedule_values_pretty = "#{schedule_values["min"]} to #{schedule_values["max"]}"
          target_units = "raw si values"
        end
      end
      @output_data_plant_loops[:data] <<  [setpoint.iddObject.name,"","","Control Variable - #{setpoint.controlVariable}",schedule_values_pretty,target_units,""]

    elsif component.to_SetpointManagerFollowOutdoorAirTemperature.is_initialized
      setpoint = component.to_SetpointManagerFollowOutdoorAirTemperature.get
      ref_temp_type = setpoint.referenceTemperatureType
      @output_data_plant_loops[:data] <<  [setpoint.iddObject.name,"","","Reference Temperature Type",ref_temp_type,"Choice",""]

    else
      @output_data_plant_loops[:data] <<  [component.iddObject.name,"","","","","",""]
    end

    # nothing to return

  end

  # create table plant loop summary
  def OsLib_Reporting.output_data_plant_loops_table(model,sqlFile,runner)

    # plant loop data output
    @output_data_plant_loops = {}
    @output_data_plant_loops[:title] = 'Plant Loop Summary'
    @output_data_plant_loops[:header] = ['Object','Sizing', 'Sizing Units','Description', 'Value', 'Value Units', 'Count']
    @output_data_plant_loops[:data] = []
    model.getPlantLoops.sort.each do |plant_loop|
      @output_data_plant_loops[:data] << ["<b><i><font color = Blue >#{plant_loop.name}</font></i></b>","","","","","",""]
      @output_data_plant_loops[:data] << ["<i><font color = Blue >(supply)</font></i>","","","","","",""]

      plant_loop.supplyComponents.each do |component|
        if component.to_ThermalZone.is_initialized
        end
        #skip some object types
        next if component.to_PipeAdiabatic.is_initialized
        next if component.to_Splitter.is_initialized
        next if component.to_Mixer.is_initialized
        if component.to_Node.is_initialized
          setpoint_managers = component.to_Node.get.setpointManagers
          if setpoint_managers.size > 0
            # setpoint type
            setpoint = setpoint_managers[0] # todo - could have more than one in some situations
            OsLib_Reporting.plant_loop_component_summary_logic(setpoint,model)
          end
        else
          # populate table for everything but setpoint managers, which are added above.
          OsLib_Reporting.plant_loop_component_summary_logic(component,model)
        end

      end

      # loop through demand components
      @output_data_plant_loops[:data] << ["<i><font color = Blue >(demand)</font></i>","","","","","",""]

      # keep track of terminal count to report later
      terminal_connections = [] # Not sure how I want to list in display

      # loop through plant demand components
      plant_loop.demandComponents.each do |component|

        # flag for terminal connecxtions
        terminal_connection = false

        #skip some object types
        next if component.to_PipeAdiabatic.is_initialized
        next if component.to_Splitter.is_initialized
        next if component.to_Mixer.is_initialized
        next if component.to_Node.is_initialized

        # determine if water to air
        if component.to_WaterToAirComponent.is_initialized
          component = component.to_WaterToAirComponent.get
          if component.airLoopHVAC.is_initialized
            description = "Air Loop"
            value = component.airLoopHVAC.get.name
          else
            # this is a terminal connection
            terminal_connection = true
            terminal_connections << component
          end
        elsif component.to_WaterToWaterComponent.is_initialized
          description = "Plant Loop"
          component = component.to_WaterToWaterComponent.get
          ww_loop = component.plantLoop
          if ww_loop.is_initialized
            value = ww_loop.get.name
          else
            value = ""
          end
        else # water use connections would go here
          description = component.name
          value = ""
        end

        # don't report here if this component is connected to a terminal
        next if terminal_connection == true

        @output_data_plant_loops[:data] << [component.iddObject.name,"","",description,value,"",""]
      end

      # report terminal connections
      if terminal_connections.size > 0
        @output_data_plant_loops[:data] << ["Air Terminal Connections","","","","","",terminal_connections.size]
      end

      @output_data_plant_loops[:data] << ["<i><font color = Blue >(controls)</font></i>","","","","","",""]

      # loop flow rates
      sizing_source_units = "m^3/s"
      sizing_target_units = "gal/min"
      if plant_loop.maximumLoopFlowRate.is_initialized
        sizing_ip = OpenStudio.convert(plant_loop.maximumLoopFlowRate.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value_source_units = "m^3/s"
      value_target_units = "gal/min"
      if plant_loop.maximumLoopFlowRate.is_initialized
        value_ip = OpenStudio.convert(plant_loop.minimumLoopFlowRate.get,value_source_units,value_target_units).get
        value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
      else
        value_ip_neat = 0.0
      end
      @output_data_plant_loops[:data] <<  ["Loop Flow Rate Range",sizing_ip_neat,sizing_target_units,"Minimum Loop Flow Rate",value_ip_neat,value_target_units,""]

      # loop temperatures
      source_units = "C"
      target_units = "F"
      min_temp = plant_loop.minimumLoopTemperature
      max_temp = plant_loop.maximumLoopTemperature
      value_neat = "#{OpenStudio.convert(min_temp,source_units,target_units).get.round(1)} to #{OpenStudio.convert(max_temp,source_units,target_units).get.round(1)}"
      @output_data_plant_loops[:data] <<  ["Loop Temperature Range","","","",value_neat,target_units,""]

      # get values out of sizing plant
      sizing_plant = plant_loop.sizingPlant
      source_units = "C"
      target_units = "F"
      loop_exit_temp = sizing_plant.designLoopExitTemperature
      value_neat = OpenStudio.toNeatString(OpenStudio.convert(loop_exit_temp,source_units,target_units).get,2,true)

      @output_data_plant_loops[:data] << ['Design Loop Exit Temperature',"","","",value_neat,target_units,""]
      source_units = "K"
      target_units = "R"
      loop_design_temp_diff = sizing_plant.loopDesignTemperatureDifference
      value_neat = OpenStudio.toNeatString(OpenStudio.convert(loop_design_temp_diff,source_units,target_units).get,2,true)
      @output_data_plant_loops[:data] << ['Loop Design Temperature Difference',"","","",value_neat,target_units,""]

      # blank row at the end of each loop
      @output_data_plant_loops[:data] << ["","","","","","",""]

    end

    return @output_data_plant_loops

  end

  # summary of what to show for each type of zone equipment component
  def OsLib_Reporting.zone_equipment_component_summary_logic(component,model)

    if component.to_FanZoneExhaust.is_initialized
      component = component.to_FanZoneExhaust.get

      sizing_source_units = "m^3/s"
      sizing_target_units = "cfm"
      if component.maximumFlowRate.is_initialized
        sizing_ip = OpenStudio.convert(component.maximumFlowRate.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = 0.0 # is that the proper default
      end
      value_source_units = "fraction"
      value_target_units = "fraction"
      value_ = component.fanEfficiency
      value_neat = OpenStudio.toNeatString(value_,2,true)

      description = "Fan Efficiency"
      @output_data_zone_equipment[:data] << [component.iddObject.name,sizing_ip_neat,sizing_target_units,description,value_neat,value_target_units,""]

    elsif component.to_ZoneHVACPackagedTerminalHeatPump.is_initialized
      component = component.to_ZoneHVACPackagedTerminalHeatPump.get

      # report outdoor air when not heating or cooling
      sizing_source_units = "m^3/s"
      sizing_target_units = "cfm"
      if component.outdoorAirFlowRateWhenNoCoolingorHeatingisNeeded.is_initialized
        sizing_ip = OpenStudio.convert(component.outdoorAirFlowRateWhenNoCoolingorHeatingisNeeded.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value = component.availabilitySchedule.name
      description = "Availability Schedule"
      @output_data_zone_equipment[:data] << ["#{component.iddObject.name} - Outdoor Air When No Clg. or Htg",sizing_ip_neat,sizing_target_units,description,value,"",""]

      # get cooling coil
      if component.coolingCoil.to_CoilCoolingDXSingleSpeed.is_initialized
        cooling_coil = component.coolingCoil.to_CoilCoolingDXSingleSpeed.get
        sizing_source_units = "W"
        sizing_target_units = "Btu/h"
        if cooling_coil.ratedTotalCoolingCapacity.is_initialized
          sizing_ip = OpenStudio.convert(cooling_coil.ratedTotalCoolingCapacity.get,sizing_source_units,sizing_target_units).get
          sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
        else
          sizing_ip_neat = "Autosized"
        end
        value_source_units = "COP"
        value_target_units = "COP"
        value_ip = cooling_coil.ratedCOP.get
        value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
        description = "Rated COP"
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{cooling_coil.iddObject.name}",sizing_ip_neat,sizing_target_units,description,value_ip_neat,value_target_units,""]
      else
        cooling_coil = component.coolingCoil
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{cooling_coil.iddObject.name}","","","","","",""]
      end

      # get heating coil
      if component.coolingCoil.to_CoilHeatingDXSingleSpeed.is_initialized
        heating_coil = component.heatingCoil.to_CoilHeatingDXSingleSpeed.get
        sizing_source_units = "W"
        sizing_target_units = "Btu/h"
        if heating_coil.ratedTotalHeatingCapacity.is_initialized
          sizing_ip = OpenStudio.convert(heating_coil.ratedTotalHeatingCapacity.get,sizing_source_units,sizing_target_units).get
          sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
        else
          sizing_ip_neat = "Autosized"
        end
        value_source_units = "COP"
        value_target_units = "COP"
        value_ip = heating_coil.ratedCOP # is optional for CoilCoolingDXSingleSpeed but is just a double for CoilHeatingDXSingleSpeed
        value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
        description = "Rated COP"
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{heating_coil.iddObject.name}",sizing_ip_neat,sizing_target_units,description,value_ip_neat,value_target_units,""]
      else
        heating_coil = component.heatingCoil
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{heating_coil.iddObject.name}","","","","","",""]
      end

      # get fan
      if component.supplyAirFan.to_FanConstantVolume.is_initialized
        fan = component.supplyAirFan.to_FanConstantVolume.get
        sizing_source_units = "m^3/s"
        sizing_target_units = "cfm"
        if fan.maximumFlowRate.is_initialized
          sizing_ip = OpenStudio.convert(fan.maximumFlowRate.get,sizing_source_units,sizing_target_units).get
          sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
        else
          sizing_ip_neat = "Autosized"
        end
        value_source_units = "Pa"
        value_target_units = "inH_{2}O"
        value_ip = OpenStudio.convert(fan.pressureRise,value_source_units,value_target_units).get
        value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{fan.iddObject.name}",sizing_ip_neat,sizing_target_units,"Pressure Rise",value_ip_neat,value_target_units,""]
      else
        fan = component.supplyAirFan
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{fan.iddObject.name}","","","","","",""]
      end

      # get supplemental heat
      if component.supplementalHeatingCoil.to_CoilHeatingElectric.is_initialized
        supplemental_heating_coil = component.supplementalHeatingCoil.to_CoilHeatingElectric.get
        sizing_source_units = "W"
        sizing_target_units = "Btu/h"
        if supplemental_heating_coil.nominalCapacity.is_initialized
          sizing_ip = OpenStudio.convert(supplemental_heating_coil.nominalCapacity.get,sizing_source_units,sizing_target_units).get
          sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
        else
          sizing_ip_neat = "Autosized"
        end
        value_source_units = ""
        value_target_units = ""
        value_ip = supplemental_heating_coil.efficiency
        value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
        description = "Efficiency"
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{supplemental_heating_coil.iddObject.name}",sizing_ip_neat,sizing_target_units,description,value_ip_neat,value_target_units,""]
      else
        supplemental_heating_coil = component.supplyAirFan
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{supplemental_heating_coil.iddObject.name}","","","","","",""]
      end

    elsif component.to_ZoneHVACPackagedTerminalAirConditioner.is_initialized
      component = component.to_ZoneHVACPackagedTerminalAirConditioner.get

      # report outdoor air when not heating or cooling
      sizing_source_units = "m^3/s"
      sizing_target_units = "cfm"
      if component.outdoorAirFlowRateWhenNoCoolingorHeatingisNeeded.is_initialized
        sizing_ip = OpenStudio.convert(component.outdoorAirFlowRateWhenNoCoolingorHeatingisNeeded.get,sizing_source_units,sizing_target_units).get
        sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
      else
        sizing_ip_neat = "Autosized"
      end
      value = component.availabilitySchedule.name
      description = "Availability Schedule"
      @output_data_zone_equipment[:data] << ["#{component.iddObject.name} - Outdoor Air When No Clg. or Htg",sizing_ip_neat,sizing_target_units,description,value,"",""]

      # get cooling coil
      if component.coolingCoil.to_CoilCoolingDXSingleSpeed.is_initialized
        cooling_coil = component.coolingCoil.to_CoilCoolingDXSingleSpeed.get
        sizing_source_units = "W"
        sizing_target_units = "Btu/h"
        if cooling_coil.ratedTotalCoolingCapacity.is_initialized
          sizing_ip = OpenStudio.convert(cooling_coil.ratedTotalCoolingCapacity.get,sizing_source_units,sizing_target_units).get
          sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
        else
          sizing_ip_neat = "Autosized"
        end
        value_source_units = "COP"
        value_target_units = "COP"
        value_ip = cooling_coil.ratedCOP.get
        value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
        description = "Rated COP"
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{cooling_coil.iddObject.name}",sizing_ip_neat,sizing_target_units,description,value_ip_neat,value_target_units,""]
      else
        cooling_coil = component.coolingCoil
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{cooling_coil.iddObject.name}","","","","","",""]
      end

      # get heating coil
      if component.heatingCoil.to_CoilHeatingWater.is_initialized
        heating_coil = component.heatingCoil.to_CoilHeatingWater.get
        sizing_source_units = "m^3/s"
        sizing_target_units = "gal/min"
        if heating_coil.maximumWaterFlowRate.is_initialized
          sizing_ip = OpenStudio.convert(heating_coil.maximumWaterFlowRate.get,sizing_source_units,sizing_target_units).get
          sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
        else
          sizing_ip_neat = "Autosized"
        end
        value = heating_coil.plantLoop.get.name
        description = "Plant Loop"
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{heating_coil.iddObject.name}",sizing_ip_neat,sizing_target_units,description,value,"",""]
      else
        heating_coil = component.heatingCoil
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{heating_coil.iddObject.name}","","","","","",""]
      end

      # get fan
      if component.supplyAirFan.to_FanConstantVolume.is_initialized
        fan = component.supplyAirFan.to_FanConstantVolume.get
        sizing_source_units = "m^3/s"
        sizing_target_units = "cfm"
        if fan.maximumFlowRate.is_initialized
          sizing_ip = OpenStudio.convert(fan.maximumFlowRate.get,sizing_source_units,sizing_target_units).get
          sizing_ip_neat = OpenStudio.toNeatString(sizing_ip,2,true)
        else
          sizing_ip_neat = "Autosized"
        end
        value_source_units = "Pa"
        value_target_units = "inH_{2}O"
        value_ip = OpenStudio.convert(fan.pressureRise,value_source_units,value_target_units).get
        value_ip_neat = OpenStudio.toNeatString(value_ip,2,true)
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{fan.iddObject.name}",sizing_ip_neat,sizing_target_units,"Pressure Rise",value_ip_neat,value_target_units,""]
      else
        fan = component.supplyAirFan
        @output_data_zone_equipment[:data] <<  ["#{component.iddObject.name} - #{fan.iddObject.name}","","","","","",""]
      end

    else
      @output_data_zone_equipment[:data] << [component.iddObject.name,"","","","","",""]
    end

    # nothing to return

  end

  # create table plant loop summary
  def OsLib_Reporting.output_data_zone_equipment_table(model,sqlFile,runner)

    # plant loop data output
    @output_data_zone_equipment = {}
    @output_data_zone_equipment[:title] = 'Zone Equipment Summary'
    @output_data_zone_equipment[:header] = ['Object','Sizing', 'Sizing Units','Description','Value', 'Value Units', 'Count']
    @output_data_zone_equipment[:data] = []
    model.getThermalZones.sort.each do |zone|
      space_type_names = []
      zone.spaces.each do |space|
        if space.spaceType.is_initialized
          space_type_names << space.spaceType.get.name
        end
      end
      zone_listed = false
      zone.equipment.sort.each do |zone_equip|
        next if !zone_equip.to_ZoneHVACComponent.is_initialized # skip any terminals
        if !zone_listed
          @output_data_zone_equipment[:data] << ["<b><i><font color = Blue >#{zone.name}</font></i></b>","","","","","",""] # only trigger this once per zone
          #@output_data_zone_equipment[:data] << ["Space Types in Zone",space_type_names.uniq.sort.join(", "),"","","","",""]
          zone_listed = true
        end
        OsLib_Reporting.zone_equipment_component_summary_logic(zone_equip,model)
      end

      # blank row at the end of each zone
      if zone_listed
        @output_data_zone_equipment[:data] << ["","","","","","",""]
      end

    end

    return @output_data_zone_equipment

  end

  # create table for wwr and skylight ratio
  def OsLib_Reporting.fenestration_data_table(model,sqlFile,runner)

    # Conditioned Window-Wall Ratio and Skylight-Roof Ratio
    @fenestration_data = {}
    @fenestration_data[:title] = 'Conditioned Window-Wall Ratio and Skylight-Roof Ratio'
    @fenestration_data[:header] = ['Description','Total','North','East','South','West','units']
    @fenestration_data[:data] = []

    # create string for rows
    fenestrations = []
    fenestrations << "Gross Window-Wall Ratio" # [%]

    # loop rows
    fenestrations.each do |fenestration|
      query0 = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='InputVerificationandResultsSummary' and TableName='Conditioned Window-Wall Ratio' and RowName='#{fenestration}' and ColumnName='Total'"
      query1 = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='InputVerificationandResultsSummary' and TableName='Conditioned Window-Wall Ratio' and RowName='#{fenestration}' and ColumnName='North (315 to 45 deg)'"
      query2 = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='InputVerificationandResultsSummary' and TableName='Conditioned Window-Wall Ratio' and RowName='#{fenestration}' and ColumnName='East (45 to 135 deg)'"
      query3 = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='InputVerificationandResultsSummary' and TableName='Conditioned Window-Wall Ratio' and RowName='#{fenestration}' and ColumnName='South (135 to 225 deg)'"
      query4 = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='InputVerificationandResultsSummary' and TableName='Conditioned Window-Wall Ratio' and RowName='#{fenestration}' and ColumnName='West (225 to 315 deg)'"
      query5 = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='InputVerificationandResultsSummary' and TableName='Skylight-Roof Ratio'  and RowName='Skylight-Roof Ratio'"

      total = sqlFile.execAndReturnFirstDouble(query0)
      north = sqlFile.execAndReturnFirstDouble(query1)
      east = sqlFile.execAndReturnFirstDouble(query2)
      south = sqlFile.execAndReturnFirstDouble(query3)
      west = sqlFile.execAndReturnFirstDouble(query4)
      skylight = sqlFile.execAndReturnFirstDouble(query5)
      if total.empty? or north.empty? or east.empty? or south.empty? or west.empty?
        runner.registerError("Did not find value for Window or Skylight Ratio")
        return false
      else
        # add data
        display = fenestration
        target_units = "" # fraction
        @fenestration_data[:data] << [display,total.get,north.get,east.get,south.get,west.get,target_units]
        runner.registerValue("#{display}",total.get,target_units)

        # skylight
        # skylight seems to provide back percentage vs. fraction. Changing to fraction to match vertical fenestration.
        @fenestration_data[:data] << ["Skylight-Roof Ratio",skylight.get/100.0,"","","","",target_units]
        runner.registerValue("Skylight-Roof Ratio",skylight.get,target_units)

      end
    end

    return @fenestration_data

  end

  # create table for exterior surface constructions
  def OsLib_Reporting.surface_data_table(model,sqlFile,runner)

    # summary of exterior constructions used in the model for base surfaces
    @surface_data = {}
    @surface_data[:title] = 'Construction Summary for Base Surfaces'
    @surface_data[:header] = ['Construction','Net Area',"Area Units",'Surface Count','R Value','R Value Units']
    @surface_data[:data] = []
    ext_const_base = {}
    model.getSurfaces.each do |surface|
      next if surface.outsideBoundaryCondition != "Outdoors"
      if ext_const_base.include? surface.construction.get
        ext_const_base[surface.construction.get] += 1
      else
        ext_const_base[surface.construction.get] = 1
      end
    end
    ext_const_base.sort.each do |construction,count|
      net_area = construction.getNetArea
      net_area_ip = OpenStudio::convert(net_area,"m^2","ft^2").get
      net_area_ip_neat = OpenStudio::toNeatString(net_area_ip,0,true)
      area_units = "ft^2"
      surface_count = count
      thermal_conductance = construction.thermalConductance.get
      source_units = "m^2*K/W"
      target_units = "ft^2*h*R/Btu"
      r_value_ip = OpenStudio::convert(1/thermal_conductance,source_units,target_units).get
      r_value_ip_neat = OpenStudio::toNeatString(r_value_ip,2,true)
      @surface_data[:data] << [construction.name,net_area_ip_neat,area_units,surface_count,r_value_ip_neat,target_units]
      runner.registerValue(construction.name.to_s,net_area_ip,area_units)
    end

    return @surface_data

  end

  # create table for exterior surface constructions
  def OsLib_Reporting.sub_surface_data_table(model,sqlFile,runner)

    # summary of exterior constructions used in the model for sub surfaces
    @sub_surface_data = {}
    @sub_surface_data[:title] = 'Construction Summary for Fenestration'
    @sub_surface_data[:header] = ['Construction','Area',"Area Units",'Surface Count','U-Factor','Units']
    @sub_surface_data[:data] = []
    ext_const_sub = {}
    model.getSubSurfaces.each do |sub_surface|
      next if sub_surface.outsideBoundaryCondition != "Outdoors"
      if ext_const_sub.include? sub_surface.construction.get
        ext_const_sub[sub_surface.construction.get] += 1
      else
        ext_const_sub[sub_surface.construction.get] = 1
      end
    end
    ext_const_sub.sort.each do |construction,count|
      net_area = construction.getNetArea
      net_area_ip = OpenStudio::convert(net_area,"m^2","ft^2").get
      net_area_ip_neat = OpenStudio::toNeatString(net_area_ip,0,true)
      area_units = "ft^2"
      surface_count = count
      source_units = "m^2*K/W"
      target_units = "ft^2*h*R/Btu"
      u_factor_units = "Btu/ft^2*h*R"
      if construction.uFactor.is_initialized
        u_factor = construction.uFactor.get
        u_factor_ip = 1/OpenStudio::convert(1/u_factor,source_units,target_units).get
        u_factor_ip_neat = OpenStudio::toNeatString(u_factor_ip,4,true)
      else
        u_factor_ip_neat = ""
      end
      @sub_surface_data[:data] << [construction.name,net_area_ip_neat,area_units,surface_count,u_factor_ip_neat,u_factor_units]
      runner.registerValue(construction.name.to_s,net_area_ip,area_units)
    end

    return @sub_surface_data

  end

  # create table for service water heating
  def OsLib_Reporting.water_use_data_table(model,sqlFile,runner)

    # water use equipment from model
    @water_use_data = {}
    @water_use_data[:title] = 'Water Use Equipment Summary'
    @water_use_data[:header] = ['Instance','Connection','Definition','Thermal Zone','Peak Flow Rate','Units']
    @water_use_data[:data] = []
    water_use_equipment = model.getWaterUseEquipments
    water_use_equipment.sort.each do |instance|
      water_use_equipment_def = instance.waterUseEquipmentDefinition
      water_use_equipment_connection = instance.waterUseConnections.get # should normally check this first
      # water_use_equipment_zone = "TBD" # todo - I need to loop through spaces to get this, but I don't think I have any hooked up in current logic.
      peak_flow_rate = water_use_equipment_def.peakFlowRate
      source_units = "m^3/s"
      target_units = "gal/h"
      peak_flow_rate_ip = OpenStudio::convert(peak_flow_rate,source_units,target_units).get
      peak_flow_rate_ip_neat = OpenStudio::toNeatString(peak_flow_rate_ip,0,true)
      @water_use_data[:data] << [instance.name,water_use_equipment_connection.name,water_use_equipment_def.name,"",peak_flow_rate_ip_neat,target_units]
      runner.registerValue(instance.name.to_s,peak_flow_rate_ip,target_units)
    end

    return @water_use_data

  end

  # create table for exterior lights
  def OsLib_Reporting.exterior_light_data_table(model,sqlFile,runner)

    # Exterior Lighting from output
    @ext_light_data = {}
    @ext_light_data[:title] = 'Exterior Lighting Summary'
    @ext_light_data[:header] = ['Description','Total Power',"Power Units",'Consumption','Consumption Units']
    @ext_light_data[:data] = []

    query0 = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='LightingSummary' and TableName='Exterior Lighting'  and RowName='Exterior Lighting Total' and ColumnName='Total Watts'"
    query1 = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='LightingSummary' and TableName='Exterior Lighting'  and RowName='Exterior Lighting Total' and ColumnName='Consumption'"
    total_watts = sqlFile.execAndReturnFirstDouble(query0)
    consumption = sqlFile.execAndReturnFirstDouble(query1)
    if total_watts.empty? or consumption.empty?
      runner.registerError("Did not find value for Exterior Lighting Total.")
      return false
    else
      # add data
      total_watts_ip = total_watts.get
      consumption_ip = consumption.get * 0.2778 # value * energy conversion
      total_watts_ip_neat = OpenStudio::toNeatString(total_watts_ip,2,true)
      consumption_ip_neat = OpenStudio::toNeatString(consumption_ip,2,true)
      power_units = "W"
      consumption_units = "kWh"
      @ext_light_data[:data] << ["Exterior Lighting Total",total_watts_ip_neat,power_units,consumption_ip_neat,consumption_units]
      runner.registerValue("Exterior Lighting Total - Power ",total_watts_ip,power_units)
      runner.registerValue("Exterior Lighting Total - Consumption ",consumption_ip,consumption_units)
    end

    return @ext_light_data

  end

  # create table for elevators
  # todo - update this to be custom load with user supplied string (or strings)
  def OsLib_Reporting.elevator_data_table(model,sqlFile,runner)

    # elevators from model
    @elevator_data = {}
    @elevator_data[:title] = 'Elevator Summary'
    @elevator_data[:header] = ['Instance','Definition','Thermal Zone','Power Per Elevator','Units','Count']
    @elevator_data[:data] = []
    elec_equip_instances = model.getElectricEquipments
    elec_equip_instances.sort.each do |instance|

      elec_equip_def = instance.electricEquipmentDefinition

      # see if it is expected and valid object
      next if elec_equip_def.name.to_s != "ElevatorElecEquipDef"
      if !instance.space.is_initialized
        runner.registerWarning("#{instance.name} doesn't have a space.")
        next
      end

      # get other data
      elev_space = instance.space.get
      elev_zone = elev_space.thermalZone.get # should check this
      elev_power = elec_equip_def.designLevel.get # should check this
      elev_power_neat = OpenStudio::toNeatString(elev_power,0,true)
      units = "W"
      count = instance.multiplier

      @elevator_data[:data] << [instance.name.to_s,elec_equip_def.name,elev_zone.name.get,elev_power_neat,units,OpenStudio::toNeatString(count,2,true)]
      runner.registerValue(instance.name.to_s,elev_power,units)
    end

    return @elevator_data

  end

  # create table of space type details
  def OsLib_Reporting.output_data_space_type_details_table(model,sqlFile,runner)

    # space type details data output
    @output_data_space_type_details = {}
    @output_data_space_type_details[:title] = 'Space Type Details'
    @output_data_space_type_details[:header] = ['Description',"Definition Value","Value Unit",'Multiplier']
    @output_data_space_type_details[:data] = []

    space_types = model.getSpaceTypes

    space_types.sort.each do |spaceType|

      next if spaceType.floorArea == 0

      # get floor area
      floor_area_si = spaceType.floorArea

      # create variable for number of people
      num_people = nil

      # gather list of spaces and zones in space type
      zone_name_list = []
      space_name_list = []
      spaceType.spaces.each do |space|
        # grabspace and zone names
        space_name_list << space.name.to_s
        if space.thermalZone.is_initialized
          zone_name_list << space.thermalZone.get.name.to_s
        end
      end
      #@output_data_space_type_details[:data] << [space_name_list.uniq.join(","),space_name_list.uniq.size,"Spaces",""]
      #@output_data_space_type_details[:data] << [zone_name_list.uniq.join(","),zone_name_list.uniq.size,"Thermal Zones",""]

      # data for space type details
      @output_data_space_type_details[:data] << ["<b><i><font color = Blue >#{spaceType.name} </font></i></b>","(#{space_name_list.uniq.size} spaces and #{zone_name_list.uniq.size} thermal zones)","",""]

      instances = spaceType.internalMass
      instances.each do |instance|
        def_display = instance.definition.name
        if instance.surfaceArea.is_initialized and instance.surfaceArea.get > 0
          def_value = OpenStudio::convert(instance.surfaceArea.get,"m^2","ft^2").get
          def_value_neat = OpenStudio::toNeatString(def_value,0,true)
          def_units = "ft^2"
        elsif instance.surfaceAreaPerFloorArea.is_initialized and instance.surfaceAreaPerFloorArea.get > 0
          def_value = instance.surfaceAreaPerFloorArea.get
          def_value_neat = OpenStudio::toNeatString(def_value,0,true)
          def_units = "ft^2/floor area ft^2"
        elsif instance.surfaceAreaPerPerson.is_initialized and instance.surfaceAreaPerPerson.get > 0
          def_value = OpenStudio::convert(instance.surfaceAreaPerPerson.get,"m^2","ft^2").get
          def_value_neat = OpenStudio::toNeatString(def_value,0,true)
          def_units = "ft^2/person"
        end
        count = instance.multiplier
        @output_data_space_type_details[:data] << [def_display,def_value_neat,def_units,count]
      end

      instances = spaceType.people
      instances.each do |instance|
        def_display = instance.definition.name
        if instance.numberOfPeople.is_initialized and instance.numberOfPeople.get > 0
          def_value = instance.numberOfPeople.get
          def_value_neat = OpenStudio::toNeatString(def_value,0,true)
          def_units = "people"
        elsif instance.peoplePerFloorArea.is_initialized and instance.peoplePerFloorArea.get > 0
          def_value = instance.peoplePerFloorArea.get / OpenStudio::convert(1,"m^2","ft^2").get
          def_value_neat = OpenStudio::toNeatString(def_value,4,true)
          def_units = "people/ft^2"
        elsif instance.spaceFloorAreaPerPerson.is_initialized and instance.spaceFloorAreaPerPerson.get > 0
          def_value = OpenStudio::convert(instance.spaceFloorAreaPerPerson.get,"m^2","ft^2").get
          def_value_neat = OpenStudio::toNeatString(def_value,0,true)
          def_units = "ft^2/person"
        end
        count = instance.multiplier
        @output_data_space_type_details[:data] << [def_display,def_value_neat,def_units,count]
      end

      instances = spaceType.electricEquipment
      instances.each do |instance|
        def_display = instance.definition.name
        if instance.designLevel.is_initialized and instance.designLevel.get > 0
          def_value = instance.designLevel.get
          def_value_neat = OpenStudio::toNeatString(def_value,0,true)
          def_units = "W"
        elsif instance.powerPerFloorArea.is_initialized and instance.powerPerFloorArea.get > 0
          def_value = instance.powerPerFloorArea.get / OpenStudio::convert(1,"m^2","ft^2").get
          def_value_neat = OpenStudio::toNeatString(def_value,4,true)
          def_units = "W/ft^2"
        elsif instance.powerPerPerson .is_initialized and instance.powerPerPerson .get > 0
          def_value = OpenStudio::convert(instance.powerPerPerson .get,"m^2","ft^2").get
          def_value_neat = OpenStudio::toNeatString(def_value,0,true)
          def_units = "W/person"
        end
        count = instance.multiplier
        @output_data_space_type_details[:data] << [def_display,def_value_neat,def_units,count]
      end

      instances = spaceType.gasEquipment
      instances.each do |instance|
        def_display = instance.definition.name
        if instance.designLevel.is_initialized and instance.designLevel.get > 0
          def_value = instance.designLevel.get
          def_value_neat = OpenStudio::toNeatString(def_value,0,true)
          def_units = "W"
        elsif instance.powerPerFloorArea.is_initialized and instance.powerPerFloorArea.get > 0
          def_value = instance.powerPerFloorArea.get / OpenStudio::convert(1,"m^2","ft^2").get
          def_value_neat = OpenStudio::toNeatString(def_value,4,true)
          def_units = "W/ft^2"
        elsif instance.powerPerPerson .is_initialized and instance.powerPerPerson .get > 0
          def_value = OpenStudio::convert(instance.powerPerPerson .get,"m^2","ft^2").get
          def_value_neat = OpenStudio::toNeatString(def_value,0,true)
          def_units = "W/person"
        end
        count = instance.multiplier
        @output_data_space_type_details[:data] << [def_display,def_value_neat,def_units,count]
      end

      instances = spaceType.lights
      instances.each do |instance|
        def_display = instance.definition.name
        if instance.lightingLevel.is_initialized and instance.lightingLevel.get > 0
          def_value = instance.lightingLevel.get
          def_value_neat = OpenStudio::toNeatString(def_value,0,true)
          def_units = "W"
        elsif instance.powerPerFloorArea.is_initialized and instance.powerPerFloorArea.get > 0
          def_value = instance.powerPerFloorArea.get / OpenStudio::convert(1,"m^2","ft^2").get
          def_value_neat = OpenStudio::toNeatString(def_value,4,true)
          def_units = "W/ft^2"
        elsif instance.powerPerPerson .is_initialized and instance.powerPerPerson .get > 0
          def_value = OpenStudio::convert(instance.powerPerPerson .get,"m^2","ft^2").get
          def_value_neat = OpenStudio::toNeatString(def_value,0,true)
          def_units = "W/person"
        end
        count = instance.multiplier
        @output_data_space_type_details[:data] << [def_display,def_value_neat,def_units,count]
      end

      instances = spaceType.spaceInfiltrationDesignFlowRates
      instances.each do |instance|
        instance_display = instance.name
        if instance.designFlowRate.is_initialized
          inst_value = OpenStudio::convert(instance.designFlowRate.get,"m^3/s","ft^3/min").get
          inst_value_neat = OpenStudio::toNeatString(inst_value,4,true)
          inst_units = "cfm"
          count = ""
          @output_data_space_type_details[:data] << [instance_display,inst_value_neat,inst_units,count]
        end
        if instance.flowperSpaceFloorArea.is_initialized
          inst_value = OpenStudio::convert(instance.flowperSpaceFloorArea.get,"m/s","ft/min").get
          inst_value_neat = OpenStudio::toNeatString(inst_value,4,true)
          inst_units = "cfm/ floor area ft^2"
          count = ""
          @output_data_space_type_details[:data] << [instance_display,inst_value_neat,inst_units,count]
        end
        if instance.flowperExteriorSurfaceArea.is_initialized
          inst_value = OpenStudio::convert(instance.flowperExteriorSurfaceArea.get,"m/s","ft/min").get
          inst_value_neat = OpenStudio::toNeatString(inst_value,4,true)
          inst_units = "cfm/ext surf area ft^2"
          count = ""
          @output_data_space_type_details[:data] << [instance_display,inst_value_neat,inst_units,count]
        end
        if instance.flowperExteriorWallArea.is_initialized # uses same input as exterior surface area but different calc method
          inst_value = OpenStudio::convert(instance.flowperExteriorWallArea.get,"m/s","ft/min").get
          inst_value_neat = OpenStudio::toNeatString(inst_value,4,true)
          inst_units = "cfm/ext wall area ft^2"
          count = ""
          @output_data_space_type_details[:data] << [instance_display,inst_value_neat,inst_units,count]
        end
        if instance.airChangesperHour.is_initialized
          inst_value = instance.airChangesperHour.get
          inst_value_neat = OpenStudio::toNeatString(inst_value,4,true)
          inst_units = "ach"
          count = ""
          @output_data_space_type_details[:data] << [instance_display,inst_value_neat,inst_units,count]
        end
      end

      if spaceType.designSpecificationOutdoorAir.is_initialized
        instance = spaceType.designSpecificationOutdoorAir.get
        instance_display = instance.name
        if instance.to_DesignSpecificationOutdoorAir.is_initialized
          instance = instance.to_DesignSpecificationOutdoorAir.get
          outdoor_air_method = instance.outdoorAirMethod
          count = ""

          # calculate and report various methods
          if instance.outdoorAirFlowperPerson > 0
            inst_value = OpenStudio::convert(instance.outdoorAirFlowperPerson,"m^3/s","ft^3/min").get
            inst_value_neat = OpenStudio::toNeatString(inst_value,4,true)
            inst_units = "cfm/person"
            @output_data_space_type_details[:data] << ["#{instance_display} (outdoor air method #{outdoor_air_method})",inst_value_neat,inst_units,count]
          end
          if instance.outdoorAirFlowperFloorArea > 0
            inst_value = OpenStudio::convert(instance.outdoorAirFlowperFloorArea,"m/s","ft/min").get
            inst_value_neat = OpenStudio::toNeatString(inst_value,4,true)
            inst_units = "cfm/floor area ft^2"
            @output_data_space_type_details[:data] << ["#{instance_display} (outdoor air method #{outdoor_air_method})",inst_value_neat,inst_units,count]
          end
          if instance.outdoorAirFlowRate  > 0
            inst_value = OpenStudio::convert(instance.outdoorAirFlowRate ,"m^3/s","ft^3/min").get
            inst_value_neat = OpenStudio::toNeatString(inst_value,4,true)
            inst_units = "cfm"
            @output_data_space_type_details[:data] << ["#{instance_display} (outdoor air method #{outdoor_air_method})",inst_value_neat,inst_units,count]
          end
          if instance.outdoorAirFlowAirChangesperHour > 0
            inst_value = instance.outdoorAirFlowAirChangesperHour
            inst_value_neat = OpenStudio::toNeatString(inst_value,4,true)
            inst_units = "ach"
            @output_data_space_type_details[:data] << ["#{instance_display} (outdoor air method #{outdoor_air_method})",inst_value_neat,inst_units,count]
          end

        end
      end

      # blank row at the end of each space type
      @output_data_space_type_details[:data] << ["","","",""]

    end

    return @output_data_space_type_details

  end

end