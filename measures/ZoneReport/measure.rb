require 'erb'
#require 'pry'

#start the measure
class ZoneReport < OpenStudio::Ruleset::ReportingUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Zone Report"
  end
  
  #define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new
    return args
  end #end the arguments method
  
  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    result = OpenStudio::IdfObjectVector.new

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(), user_arguments)
      return result
    end

    request = OpenStudio::IdfObject.load("Output:Table:SummaryReports,AllSummaryAndSizingPeriod;").get
    result << request

    return result
  end

  # Method to make class names nicer (remove OS and _)
  def niceClassName(class_name)
    class_name = class_name.gsub('OS_','')
    class_name = class_name.gsub('_',' ')
    return class_name
  end
  
  # Convert a value from the view TabularDataWithStrings from the unit represented there to the given unit.
  # We make a bunch of special cases for unit aliases used by EnergyPlus which are not in the default
  # list of OpenStudio conversions
  # We also special case a few conversions for unitless 'units' so that our final display makes more sense to the user.
  # When the property is not present (for instance, cooled beams don't have properties in the sql file under 1.5)
  # this method will return "-" as a placeholder.
  def eplus_to_openstudio(unitstr)
    unitstr.gsub("m3", "m^3").gsub("pa", "Pa").gsub("m2", "m^2").gsub(" per ", "/")
  end
  
  def convert_prop(property, final_units)
    return ["-", "-"] unless property

    return [property[0].to_f.round(2), ""] if final_units.empty?
    return [(property[0].to_f * 100).round(2), "%"] if final_units == "%"
    return [property[0].to_f.round(2), "COP"] if final_units == "COP"

    initial_units = eplus_to_openstudio(property[1])
    converted = OpenStudio::convert(property[0].to_f, initial_units, final_units)
    if converted.empty?
      "Could not convert from #{initial_units} to #{final_units}"
    else
      final_units = final_units.gsub("inH_{2}O", "in. w.c.")
      [converted.get.round(2), final_units]
    end
  end

  def properties_for_cooling_coil(e, props, parent)
    autosized = case e.iddObjectType
                  when OpenStudio::Model::CoilCoolingDXSingleSpeed.iddObjectType
                    coil = e.to_CoilCoolingDXSingleSpeed.get
                    (coil.isRatedTotalCoolingCapacityAutosized and coil.isRatedSensibleHeatRatioAutosized and coil.isRatedAirFlowRateAutosized) ? "Yes" : "No"
                  when OpenStudio::Model::CoilCoolingWater.iddObjectType
                    coil = e.to_CoilCoolingWater.get
                    (coil.isDesignWaterFlowRateAutosized and coil.isDesignAirFlowRateAutosized and coil.isDesignInletWaterTemperatureAutosized) ? "Yes" : "No"
                  when OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit.iddObjectType
                    coil = e.to_CoilCoolingWaterToAirHeatPumpEquationFit.get
                    (coil.isRatedTotalCoolingCapacityAutosized and coil.isRatedSensibleHeatRatioAutosized and coil.isRatedAirFlowRateAutosized) ? "Yes" : "No"
                  else
                    "?"
                end

    coolingcap = convert_prop(props["Nominal Total Capacity"], "kBtu/hr")
    coolingeff = convert_prop(props["Nominal Efficiency"], "COP")
    sensibleheatratio = convert_prop(props["Nominal Sensible Heat Ratio"], "")
    parent_name = parent.name.get
    name = e.name.get
    coiltype = niceClassName(e.iddObjectType.valueName)

    {"Terminal/Zone Equip Name" => parent_name, "Coil Type" => coiltype, "Name" => name, "Autosized" => autosized, "Nominal Capacity" => coolingcap, "Nominal Efficiency" => coolingeff, "Nominal SHR" => sensibleheatratio}
  end

  def properties_for_heating_coil(e, props, parent)
    autosized = "-"
    eff_units = "COP"
    heatingcap = ["-", "-"]
    heatingeff = ["-", "-"]
    case e.iddObjectType
      when OpenStudio::Model::CoilHeatingElectric.iddObjectType
        coil = e.to_CoilHeatingElectric.get
        autosized = coil.isNominalCapacityAutosized ? "Yes" : "No"
        heatingcap = convert_prop(props["Nominal Total Capacity"], "kW")
        heatingeff = convert_prop(props["Nominal Efficiency"], "%")
      when OpenStudio::Model::CoilHeatingGas.iddObjectType
        coil = e.to_CoilHeatingGas.get
        autosized = coil.isNominalCapacityAutosized ? "Yes" : "No"
        heatingcap = convert_prop(props["Nominal Total Capacity"], "kBtu/hr")
        heatingeff = convert_prop(props["Nominal Efficiency"], "COP")
      when OpenStudio::Model::CoilHeatingDXSingleSpeed.iddObjectType
        coil = e.to_CoilHeatingDXSingleSpeed.get
        autosized = (coil.isRatedTotalHeatingCapacityAutosized and coil.isRatedAirFlowRateAutosized) ? "Yes" : "No"
        heatingcap = convert_prop(props["Nominal Total Capacity"], "kBtu/hr")
        heatingeff = convert_prop(props["Nominal Efficiency"], "COP")
      when OpenStudio::Model::CoilHeatingWater.iddObjectType
        coil = e.to_CoilHeatingWater.get
        autosized = (coil.isMaximumWaterFlowRateAutosized and coil.isRatedCapacityAutosized and coil.isUFactorTimesAreaValueAutosized) ? "Yes" : "No"
        heatingcap = convert_prop(props["Nominal Total Capacity"], "kBtu/hr")
        heatingeff =["-", "-"]
      when OpenStudio::Model::CoilHeatingWaterBaseboard.iddObjectType
        coil = e.to_CoilHeatingWaterBaseboard.get
        autosized = (coil.isMaximumWaterFlowRateAutosized and coil.isUFactorTimesAreaValueAutosized) ? "Yes" : "No"
        heatingcap = convert_prop(props["Nominal Total Capacity"], "kBtu/hr")
        heatingeff =["-", "-"]
      when OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit.iddObjectType
        coil = e.to_CoilHeatingWaterToAirHeatPumpEquationFit.get
        autosized = (coil.isRatedHeatingCapacityAutosized and coil.isRatedAirFlowRateAutosized and coil.isRatedWaterFlowRateAutosized) ? "Yes" : "No"
        heatingcap = convert_prop(props["Nominal Total Capacity"], "kBtu/hr")
        heatingeff = convert_prop(props["Nominal Efficiency"], "COP")
      else
        autosized = "?"
    end

    parent_name = parent.name.get
    name = e.name.get
    coiltype = niceClassName(e.iddObjectType.valueName)

    {"Terminal/Zone Equip Name" => parent_name, "Coil Type" => coiltype, "Name" => name, "Autosized" => autosized, "Nominal Capacity" => heatingcap, "Nominal Efficiency" => heatingeff}
  end

  def properties_for_fan(equipment, properties, parent)
    autosized = case equipment.iddObjectType
                  when OpenStudio::Model::FanConstantVolume.iddObjectType
                    fan = equipment.to_FanConstantVolume.get
                    fan.isMaximumFlowRateAutosized ? "Yes" : "No"
                  when OpenStudio::Model::FanVariableVolume.iddObjectType
                    fan = equipment.to_FanVariableVolume.get
                    fan.isMaximumFlowRateAutosized ? "Yes" : "No"
                  when OpenStudio::Model::FanOnOff.iddObjectType
                    fan = equipment.to_FanOnOff.get
                    fan.isMaximumFlowRateAutosized ? "Yes" : "No"
                  when OpenStudio::Model::FanZoneExhaust.iddObjectType
                    "N/A"
                  else
                    "?"
                end

    name = equipment.name.get
    parent_name = parent.name.get
    maxflowrate = convert_prop(properties["Max Air Flow Rate"], "cfm")
    fanpressure = convert_prop(properties["Delta Pressure"], "inH_{2}O")
    totalefficiency  = convert_prop(properties["Total Efficiency"], "%")
    ratedfanpower = convert_prop(properties["Rated Electric Power"], "W")
    {"Terminal/Zone Equip Name" => parent_name, "Fan Type" => niceClassName(equipment.iddObjectType.valueName), "Name" => name, "Autosized" => autosized, "Max Flow" => maxflowrate, "Efficiency" => totalefficiency, "Pressure" => fanpressure, "Power" => ratedfanpower}
  end

# Each equipment is grouped into Heating, Cooling or Fans and has properties extracted appropriate for that group.
# This method returns a tuple [equipment group, properties] where properties is a hash of name, value or name, [value, units] pairs
  def properties_for_zone_equipment(equipment, equipment_properties, parent)
# Make properties an empty hash if it was nil
    equipment_properties = equipment_properties || {}
    case
      when /^OS_Coil_Cooling/ =~ equipment.iddObjectType.valueName
        return "Cooling", properties_for_cooling_coil(equipment, equipment_properties, parent)
      when /^OS_Coil_Heating/ =~ equipment.iddObjectType.valueName
        return "Heating", properties_for_heating_coil(equipment, equipment_properties, parent)
      when /^OS_Fan/ =~ equipment.iddObjectType.valueName
        return "Fans", properties_for_fan(equipment, equipment_properties, parent)
      when OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.iddObjectType == equipment.iddObjectType
        baseboard = equipment.to_ZoneHVACBaseboardConvectiveElectric.get
        autosized = baseboard.isNominalCapacityAutosized ? "Yes" : "No"
        heatingcap = convert_prop(equipment_properties["Design Size Nominal Capacity"], "kW")
        name = baseboard.name.get
        coiltype = niceClassName(baseboard.iddObjectType.valueName)
        return "Heating", {"Terminal/Zone Equip Name" => name, "Coil Type" => coiltype, "Name" => name, "Autosized" => autosized, "Nominal Capacity" => heatingcap, "Nominal Efficiency" => [100, "%"]}
      else
        return nil, nil
    end
  end
  
  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    @runner = runner

    # get the last model and sql file

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    @sqlFile = runner.lastEnergyPlusSqlFile
    if @sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    @sqlFile = @sqlFile.get
    model.setSqlFile(@sqlFile)

    @graph_data = []

# Collect and collate information about the hvac equipment
# When we are done we will have a hash of equipment keyed by equipment name
# who's values are hashes keyed by the property name.  The values of the
# property hashes are [value, unit] pairs
# Some types of equipment (for instance CoilCoolingCooledBeams) are not present
# in the database as of OS 1.5


# find table names, etc. in the SupportZoneHVACEquipFields
    tableNames = getDataByColumn( "TableName" )
    columnNames = getDataByColumn( "ColumnName" )
    rowNames = getDataByColumn( "RowName" )
    units = getDataByColumn( "Units" )
    values = getDataByColumn( "Value" )
    equipment_rows = tableNames.zip( columnNames, rowNames, units, values )
    equipment = {}
    equipment_rows.each do |r|
      _, field, name, units, value = r
      if name != "None"
        eh = equipment[name] || {}
        eh[field] = [value, units]
        equipment[name] = eh
      end
    end

    @zone_collection = []


    @testData = {}

# Go through each zone in the model and collect all the zone equipment
    model.getThermalZones.sort.each do |thermalZone|
    
      # Skip unconditioned zones
      if thermalZone.thermostatSetpointDualSetpoint.empty?
        @runner.registerInfo("Skipping #{thermalZone.name} because it is unconditioned.")
        next
      end
      
      # Skip plenums
      if thermalZone.isPlenum == true
        @runner.registerInfo("Skipping #{thermalZone.name} because it is a plenum.")
        next
      end
    
      zone_equipment = {}

      thermalZone.equipment.each do |e|
        childquipment = e.to_ParentObject.get.children
# Look for data on the top level equipment and each of that equipment's children
        found_primary_heat = false
        ([e] + childquipment).each do |ce|
          ename = ce.name.get.upcase
          reporting_type, equipment_properties = properties_for_zone_equipment(ce, equipment[ename], e)
          if equipment_properties
# The first heating coil in a zone equipment chain will be primary heating; all
# following heating coils will be marked as Backup Heating.
            if reporting_type == "Heating"
              reporting_type = "Backup Heating" if found_primary_heat
              found_primary_heat = true
            end
# Find the priority for heating or cooling equipment - the priority is based on the 'parent' zone equipment priority
            if reporting_type == "Heating"
              equipment_properties["Priority"] = (thermalZone.equipmentInHeatingOrder.index {|ze| ze.name.get == e.name.get && ze.iddObjectType == e.iddObjectType}) + 1
            end
            if reporting_type == "Cooling"
              equipment_properties["Priority"] = (thermalZone.equipmentInCoolingOrder.index {|ze| ze.name.get == e.name.get && ze.iddObjectType == e.iddObjectType}) + 1
            end
# If we don't yet have equipment of this type, make a new array.  Then add
# our equipment information to the array and update our zone equipment hash.
            equip_of_type = zone_equipment[reporting_type] || []
            equip_of_type << equipment_properties
            zone_equipment[reporting_type] = equip_of_type
          end
        end
      end

      zoneMetrics = {}
      zoneMetrics[:name] = !thermalZone.name.empty? ? thermalZone.name.get : ''
      zoneMetrics[:equipment] = zone_equipment
      zoneMetrics[:area] = (OpenStudio.convert( thermalZone.floorArea, "m^2", "ft^2" ).get).round(2)

      @currentZoneName = zoneMetrics[:name]

      vals = {}

      vals[:va] = getDetailsData( "LightingSummary", "Entire Facility", "Interior Lighting", "#{zoneMetrics[:name]}%", "Lighting Power Density", "W/m2", "W/ft^2").round(2)
      vals[:vb] = getDetailsData( "LightingSummary", "Entire Facility", "Interior Lighting", "#{zoneMetrics[:name]}%", "Full Load Hours/Week", "hr", "hr").round(2)

      vals[:vc] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Electricity", "InteriorLights:Electricity:Zone:#{zoneMetrics[:name]}", "Electricity Annual Value", "GJ", "kWh").round(2)

      vals[:vd] = getDetailsData( "InputVerificationandResultsSummary", "Entire Facility", "Zone Summary", zoneMetrics[:name], "Plug and Process", "W/m2", "W/ft^2").round(2)

      vals[:ve] = getDetailsData( "InputVerificationandResultsSummary", "Entire Facility", "Zone Summary", zoneMetrics[:name], "Area", "m2", "ft^2").round(2)

      vals[:vf] = getDetailsData( "InputVerificationandResultsSummary", "Entire Facility", "Zone Summary", zoneMetrics[:name], "Conditioned (Y/N)", "", "s" )
      if ( vals[:vf] == "" ) then vals[:vf] = "No" end

      vals[:vg] = getDetailsData( "HVACSizingSummary", "Entire Facility", "Zone Heating", zoneMetrics[:name], "User Design Load", "W", "kBtu/hr" ).round(2)
      vals[:vh] = getDetailsData( "HVACSizingSummary", "Entire Facility", "Zone Heating", zoneMetrics[:name], "User Design Air Flow", "m3/s", "ft^3/s" ).round(2)
      vals[:vi] = getDetailsData( "HVACSizingSummary", "Entire Facility", "Zone Cooling", zoneMetrics[:name], "User Design Load", "W", "kBtu/hr" ).round(2)
      vals[:vj] = getDetailsData( "HVACSizingSummary", "Entire Facility", "Zone Cooling", zoneMetrics[:name], "User Design Air Flow", "m3/s", "ft^3/s" ).round(2)

      vals[:vk] = getDetailsData( "OutdoorAirSummary", "Entire Facility", "Average Outdoor Air During Occupied Hours", zoneMetrics[:name], "Mechanical Ventilation", "ach", "ach" ).round(2)
      vals[:vl] = getDetailsData( "OutdoorAirSummary", "Entire Facility", "Average Outdoor Air During Occupied Hours", zoneMetrics[:name], "Infiltration", "ach", "ach" ).round(2)


      vals[:vm] = getDetailsData( "InputVerificationandResultsSummary", "Entire Facility", "Zone Summary", zoneMetrics[:name], "People", "m2 per person", "ft^2/person" ).round(2)

      vals[:vn] = getDetailsData( "HVACSizingSummary", "Entire Facility", "Zone Cooling", zoneMetrics[:name], "Date/Time Of Peak", "", "s" )
      vals[:vo] = getDetailsData( "HVACSizingSummary", "Entire Facility", "Zone Heating", zoneMetrics[:name], "Date/Time Of Peak", "", "s" )


      vals[:vp] = getDetailsData( "SystemSummary", "Entire Facility", "Time Setpoint Not Met", zoneMetrics[:name], "During Heating", "hr", "hr" )
      vals[:vq] = getDetailsData( "SystemSummary", "Entire Facility", "Time Setpoint Not Met", zoneMetrics[:name], "During Cooling", "hr", "hr" )




      vals[:vr] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Gas", "InteriorEquipment:Gas:Zone:#{zoneMetrics[:name]}", "Electricity Annual Value", "GJ", "Therm" ).round(2)
      vals[:vs] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Electricity", "InteriorEquipment:Electricity:Zone:#{zoneMetrics[:name]}", "Electricity Annual Value", "GJ", "kWh" ).round(2)

      vals[:vt] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Gas", "InteriorEquipment:Gas:Zone:#{zoneMetrics[:name]}", "Gas Maximum  Value", "W", "kBtu/hr" ).round(2)
      vals[:vu] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Gas", "InteriorEquipment:Gas:Zone:#{zoneMetrics[:name]}", "Timestamp of Maximum", "", "s" )


      vals[:vv] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Electricity", "InteriorLights:Electricity:Zone:#{zoneMetrics[:name]}", "Electricity Maximum Value", "W", "kW" ).round(2)
      vals[:vw] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Electricity", "InteriorLights:Electricity:Zone:#{zoneMetrics[:name]}", "Timestamp of Maximum", "", "s" )

      #X unused

      vals[:vy] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Electricity", "InteriorEquipment:Electricity:Zone:#{zoneMetrics[:name]}", "Electricity Maximum Value", "W", "kW" ).round(2)
      vals[:vz] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Electricity", "InteriorEquipment:Electricity:Zone:#{zoneMetrics[:name]}", "Timestamp of Maximum", "", "s" )

      vals[:vaa] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Other", "InteriorEquipment:DistrictHeating:Zone:#{zoneMetrics[:name]}", "Annual Value", "GJ", "kBtu" ).round(2)
      vals[:vab] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Other", "InteriorEquipment:DistrictHeating:Zone:#{zoneMetrics[:name]}", "Maximum Value", "W", "kBtu/hr" ).round(2)
      vals[:vac] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Other", "InteriorEquipment:DistrictHeating:Zone:#{zoneMetrics[:name]}", "Timestamp of Maximum", "", "s" )

      vals[:vad] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Other", "Heating:EnergyTransfer:Zone:#{zoneMetrics[:name]}", "Annual Value", "GJ", "kBtu" ).round(2)
      vals[:vae] = (getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Other", "Heating:EnergyTransfer:Zone:#{zoneMetrics[:name]}", "Maximum Value", "W", "kBtu/hr")/zoneMetrics[:area]).round(2)
      vals[:vaf] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Other", "Heating:EnergyTransfer:Zone:#{zoneMetrics[:name]}", "Timestamp of Maximum", "", "s" )

      vals[:vag] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Other", "Cooling:EnergyTransfer:Zone:#{zoneMetrics[:name]}", "Annual Value", "GJ", "kBtu" ).round(2)
      vals[:vah] = (getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Other", "Cooling:EnergyTransfer:Zone:#{zoneMetrics[:name]}", "Maximum Value", "W", "kBtu/hr")/zoneMetrics[:area]).round(2)
      vals[:vai] = getDetailsData( "EnergyMeters", "Entire Facility", "Annual and Peak Values - Other", "Cooling:EnergyTransfer:Zone:#{zoneMetrics[:name]}", "Timestamp of Maximum", "", "s" )


      vals[:vaj] = zoneHeatComponentCalc("People",zoneMetrics )
      vals[:vak] = zoneHeatComponentCalc("Lights",zoneMetrics )
      vals[:val] = zoneHeatComponentCalc("Equipment",zoneMetrics )
      vals[:vam] = zoneHeatComponentCalc("Refrigeration",zoneMetrics )
      vals[:van] = zoneHeatComponentCalc("Water Use Equipment",zoneMetrics )
      vals[:vao] = zoneHeatComponentCalc("HVAC Equipment Losses",zoneMetrics )
      vals[:vap] = zoneHeatComponentCalc("Power Generation Equipment",zoneMetrics )
      vals[:vaq] = zoneHeatComponentCalc("Infiltration",zoneMetrics )
      vals[:var] = zoneHeatComponentCalc("Zone Ventilation",zoneMetrics )
      vals[:vas] = zoneHeatComponentCalc("Interzone Mixing",zoneMetrics )
      vals[:vat] = zoneHeatComponentCalc("Exterior Wall",zoneMetrics )
      vals[:vau] = zoneHeatComponentCalc("Interzone Wall",zoneMetrics )
      vals[:vav] = zoneHeatComponentCalc("Ground Contact Wall",zoneMetrics )
      vals[:vaw] = zoneHeatComponentCalc("Other Wall",zoneMetrics )
      vals[:vax] = zoneHeatComponentCalc("Opaque Door",zoneMetrics )
      vals[:vay] = zoneHeatComponentCalc("Roof",zoneMetrics )
      vals[:vaz] = zoneHeatComponentCalc("Interzone Ceiling",zoneMetrics )
      vals[:vba] = zoneHeatComponentCalc("Other Roof",zoneMetrics )
      vals[:vbb] = zoneHeatComponentCalc("Exterior Floor",zoneMetrics )
      vals[:vbc] = zoneHeatComponentCalc("Interzone Floor",zoneMetrics )
      vals[:vbd] = zoneHeatComponentCalc("Ground Contact Floor",zoneMetrics )
      vals[:vbe] = zoneHeatComponentCalc("Other Floor",zoneMetrics )
      vals[:vbf] = zoneHeatComponentCalc("Fenestration Conduction",zoneMetrics )
      vals[:vbg] = zoneHeatComponentCalc("Fenestration Solar",zoneMetrics )


      vals[:vbh] = getDetailsData( "ZoneComponentLoadSummary", "#{zoneMetrics[:name]}", "Heating Peak Conditions", "Time of Peak Load", "Value", "", "s" )

      vals[:vbi] = zoneCoolComponentCalc("People",zoneMetrics )
      vals[:vbj] = zoneCoolComponentCalc("Lights",zoneMetrics )
      vals[:vbk] = zoneCoolComponentCalc("Equipment",zoneMetrics )
      vals[:vbl] = zoneCoolComponentCalc("Refrigeration",zoneMetrics )
      vals[:vbm] = zoneCoolComponentCalc("Water Use Equipment",zoneMetrics )
      vals[:vbn] = zoneCoolComponentCalc("HVAC Equipment Losses",zoneMetrics )
      vals[:vbo] = zoneCoolComponentCalc("Power Generation Equipment",zoneMetrics )
      vals[:vbp] = zoneCoolComponentCalc("Infiltration",zoneMetrics )
      vals[:vbq] = zoneCoolComponentCalc("Zone Ventilation",zoneMetrics )
      vals[:vbr] = zoneCoolComponentCalc("Interzone Mixing",zoneMetrics )
      vals[:vbs] = zoneCoolComponentCalc("Exterior Wall",zoneMetrics )
      vals[:vbt] = zoneCoolComponentCalc("Interzone Wall",zoneMetrics )
      vals[:vbu] = zoneCoolComponentCalc("Ground Contact Wall",zoneMetrics )
      vals[:vbv] = zoneCoolComponentCalc("Other Wall",zoneMetrics )
      vals[:vbw] = zoneCoolComponentCalc("Opaque Door",zoneMetrics )
      vals[:vbx] = zoneCoolComponentCalc("Roof",zoneMetrics )
      vals[:vby] = zoneCoolComponentCalc("Interzone Ceiling",zoneMetrics )
      vals[:vbz] = zoneCoolComponentCalc("Other Roof",zoneMetrics )
      vals[:vca] = zoneCoolComponentCalc("Exterior Floor",zoneMetrics )
      vals[:vcb] = zoneCoolComponentCalc("Interzone Floor",zoneMetrics )
      vals[:vcc] = zoneCoolComponentCalc("Ground Contact Floor",zoneMetrics )
      vals[:vcd] = zoneCoolComponentCalc("Other Floor",zoneMetrics )
      vals[:vce] = zoneCoolComponentCalc("Fenestration Conduction",zoneMetrics )
      vals[:vcf] = zoneCoolComponentCalc("Fenestration Solar",zoneMetrics )

      vals[:vcg] = getDetailsData( "ZoneComponentLoadSummary", "#{zoneMetrics[:name]}", "Cooling Peak Conditions", "Time of Peak Load", "Value", "", "s" )

    #vals = loadTestVals( vals )


      vals[:sumBasicHeating] = (vals[:vaj] + vals[:vak] + vals[:val] + vals[:vam] + vals[:vaq] + vals[:var] + vals[:vas]).round(2)
      vals[:sumBasicCooling] = (vals[:vbi] + vals[:vbj] + vals[:vbk] + vals[:vbl] + vals[:vbp] + vals[:vbq] + vals[:vbr]).round(2)

      vals[:sumOtherHeating] = (vals[:van] + vals[:vao] + vals[:vap]).round(2)
      vals[:sumOtherCooling] = (vals[:vbm] + vals[:vbn] + vals[:vbo]).round(2)

      vals[:sumWallDoorHeating] = (vals[:vat] + vals[:vau] + vals[:vav] + vals[:vaw] + vals[:vax]).round(2)
      vals[:sumWallDoorCooling] = (vals[:vbs] + vals[:vbt] + vals[:vbu] + vals[:vbv] + vals[:vbw]).round(2)

      vals[:sumRoofCeilingHeating] = (vals[:vay] + vals[:vaz] + vals[:vba]).round(2)
      vals[:sumRoofCeilingCooling] = (vals[:vbx] + vals[:vby] + vals[:vbz]).round(2)

      vals[:sumFloorHeating] = (vals[:vbb] + vals[:vbc] + vals[:vbd] + vals[:vbe]).round(2)
      vals[:sumFloorCooling] = (vals[:vca] + vals[:vcb] + vals[:vcc] + vals[:vcd]).round(2)

      vals[:sumWindowsHeating] = (vals[:vbf] + vals[:vbg]).round(2)
      vals[:sumWindowsCooling] = (vals[:vce] + vals[:vcf]).round(2)

      vals[:sumHeatingTotal] = (vals[:sumBasicHeating] + vals[:sumOtherHeating] + vals[:sumWallDoorHeating] + vals[:sumRoofCeilingHeating] + vals[:sumFloorHeating] + vals[:sumWindowsHeating]).round(2)
      vals[:sumCoolingTotal] = (vals[:sumBasicCooling] + vals[:sumOtherCooling] + vals[:sumWallDoorCooling] + vals[:sumRoofCeilingCooling] + vals[:sumFloorCooling] + vals[:sumWindowsCooling]).round(2)

      zoneMetrics[:vals] = vals

      @zone_collection.push( zoneMetrics )

      stacked_bars( zoneMetrics )

    end

	@zone_collection = @zone_collection.sort_by { |z| z[:name] }
	
    equipment_lengths = @zone_collection.map { |z| z[:equipment].values.map { |equip_list| equip_list.length } }
    max_zone_equipments = equipment_lengths.flatten.max


    # Convert the graph data to JSON
    # This measure requires ruby 2.0.0 to create the JSON for the report graph
    if RUBY_VERSION >= "2.0.0"
      require 'json'
      @graph_data = @graph_data.to_json
    else
      runner.registerInfo("This Measure needs Ruby 2.0.0 to generate timeseries graphs on the report.  You have Ruby #{RUBY_VERSION}.  OpenStudio 1.4.2 and higher user Ruby 2.0.0.")
    end

    web_asset_path = OpenStudio::getSharedResourcesPath() / OpenStudio::Path.new("web_assets")

    html_in = getResourceFileData( "report.html.in" )

    # configure template with variable values
    renderer = ERB.new(html_in)
    html_out = renderer.result(binding)

    writeResourceFileData( "report.html", html_out )
    #copyResourceFile( "graph_resource.js" )
    #copyResourceFile( "style_resource.css" )

    #closing the sql file
    @sqlFile.close()

    #reporting final condition
    runner.registerFinalCondition("Successfully finished writing 'Zone Report'.")
    
    return true
 
  end #end the run method

  def zoneHeatComponentCalc( component, zoneMetrics )
    (getDetailsData( "ZoneComponentLoadSummary", "#{zoneMetrics[:name]}", "Estimated Heating Peak Load Components", component, "Total", "W", "Btu/hr") / zoneMetrics[:area]).round(2)
  end

  def zoneCoolComponentCalc( component, zoneMetrics )
    (getDetailsData( "ZoneComponentLoadSummary", "#{zoneMetrics[:name]}", "Estimated Cooling Peak Load Components", component, "Total", "W", "Btu/hr") / zoneMetrics[:area]).round(2)
  end  
  
    def stacked_bars( zoneMetrics )

    #people, lights, equipment, refrigeration, other, infiltration, zone ventilation,
    #interzone mixing, walls/doors, roof/ceiling, floor, windows

    vals = zoneMetrics[:vals]


    heatingVals = [vals[:vaj],
                      vals[:vak],
                      vals[:val],
                      vals[:vam],
                      vals[:sumOtherHeating],
                      vals[:vaq],
                      vals[:var],
                      vals[:vas],
                      vals[:sumWallDoorHeating],
                      vals[:sumRoofCeilingHeating],
                      vals[:sumFloorHeating],
                      vals[:sumWindowsHeating]];


    coolingVals = [vals[:vbi],
                      vals[:vbj],
                      vals[:vbk],
                      vals[:vbl],
                      vals[:sumOtherCooling],
                      vals[:vbp],
                      vals[:vbq],
                      vals[:vbr],
                      vals[:sumWallDoorCooling],
                      vals[:sumRoofCeilingCooling],
                      vals[:sumFloorCooling],
                      vals[:sumWindowsCooling]];

    positiveHeating = heatingVals.select{ |v| v >= 0 }.inject{|sum,x| sum + x } || 0
    negativeHeating = heatingVals.select{ |v| v < 0 }.inject{|sum,x| sum + x } || 0

    positiveCooling = coolingVals.select{ |v| v >= 0 }.inject{|sum,x| sum + x } || 0
    negativeCooling = coolingVals.select{ |v| v < 0 }.inject{|sum,x| sum + x } || 0

    maxPositive = positiveHeating > positiveCooling ? positiveHeating : positiveCooling
    maxNegative = negativeHeating < negativeCooling ? negativeHeating : negativeCooling

    maxPositive = maxPositive == 0 ? maxNegative * -0.20 : maxPositive
    maxNegative = maxNegative == 0 ? maxPositive * -0.10 : maxNegative

    maxPositive = maxPositive + ( maxPositive * 0.20 ).round(2)
    maxNegative = maxNegative + ( maxNegative * 0.10 ).round(2)

    stacked_vals = [[ 0, maxPositive, maxNegative, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
                    [ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, vals[:sumHeatingTotal], 0 ],
                    [ 2,
                      vals[:vaj],
                      vals[:vak],
                      vals[:val],
                      vals[:vam],
                      vals[:sumOtherHeating],
                      vals[:vaq],
                      vals[:var],
                      vals[:vas],
                      vals[:sumWallDoorHeating],
                      vals[:sumRoofCeilingHeating],
                      vals[:sumFloorHeating],
                      vals[:sumWindowsHeating],
                      0,
                      0],
                    [ 3,
                      vals[:vbi],
                      vals[:vbj],
                      vals[:vbk],
                      vals[:vbl],
                      vals[:sumOtherCooling],
                      vals[:vbp],
                      vals[:vbq],
                      vals[:vbr],
                      vals[:sumWallDoorCooling],
                      vals[:sumRoofCeilingCooling],
                      vals[:sumFloorCooling],
                      vals[:sumWindowsCooling],
                      0,
                      0],
                    [ 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, vals[:sumCoolingTotal] ],
                    [ 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]]

    # Add the hourly load data to JSON for the report.html
    graph = {}
    graph["title"] = ""
    graph["xaxislabel"] = ""
    graph["yaxislabel"] = "Contribution Btu/hr/ft2"
    graph["labels"] = %w(index, people lights equipment refrigeration other infiltration zone_ventilation interzone_mixing walls/doors roof/ceiling floor windows net/heating net/cooling)
    graph["colors"] = ["#888855", "#AAAA55", "#3333AA", "#8888FF", "#888888", "#9999FF", "#AAAAFF", "#AA6666", "#777733", "#888833", "#999933", "#9999FF", "#FF9999", "#9999FF" ]
    graph["data"] = stacked_vals

    @graph_data << graph
  end

  def getPctLoad( val, total )
    if val != "" && total != 0 then
      return (val * 100 / total).round(2)
    else
      return 0
    end
  end

  def getResourceFileData( fileName )
    data_in_path = "#{File.dirname(__FILE__)}/resources/#{fileName}"
    if !File.exist?(data_in_path)
        data_in_path = "#{File.dirname(__FILE__)}/#{fileName}"
    end

    html_in = ""
    File.open(data_in_path, 'r') do |file|
      html_in = file.read
    end

    html_in
  end

  def writeResourceFileData( fileName, data )
    File.open("./#{fileName}", 'w') do |file|
      file << data
      # make sure data is written to the disk one way or the other
      begin
        file.fsync
      rescue
        file.flush
      end
    end
  end

  # Fetch a value from the tabulardatawithstrings database view
  # If final_units is "s" the value is returned unchanged as a string
  # Otherwise the value is converted from units to final_units - units is specified in energy plus style (m2, m3, etc)
  # and final_units should be open studio style (m^2, m^3, ...)
  # If the data is not found or cannot be converted a warning is registered and "" or 0.0 is returned.
  def getDetailsData( report, forstring, table, row, column, units, final_units)

    if report == "ZoneComponentLoadSummary" then
      forstring.upcase!
    end

    str_HVACEquipment_query = "SELECT Value FROM tabulardatawithstrings WHERE "
    str_HVACEquipment_query << "ReportName='#{report}' AND "
    str_HVACEquipment_query << "ReportForString='#{forstring}' AND "
    str_HVACEquipment_query << "TableName='#{table}' AND "
    str_HVACEquipment_query << "RowName LIKE '#{row}' AND "
    str_HVACEquipment_query << "ColumnName='#{column}' AND "
    str_HVACEquipment_query << "Units='#{units}'"

    query_results = @sqlFile.execAndReturnFirstString(str_HVACEquipment_query)

    if query_results.empty?

      @runner.registerWarning("Could not get data for #{report} #{forstring} #{table} #{row} #{column}.")
      return "s" == final_units ? "" : 0.0

    else
      r = query_results.get
      if report == "ZoneComponentLoadSummary" then
        @testData["#{@currentZoneName}_#{table}_#{row}"] = r
      end

      if "s" == final_units
        return r
      else
        converted = OpenStudio::convert(r.to_f, eplus_to_openstudio(units), final_units)
        if converted.empty?
          @runner.registerError("Could not convert #{r} from #{units} to #{final_units}")
          return 0.0
        else
          return converted.get.round(2)
        end
      end

    end

  end

  def getDataByColumn( colName )

      strvec_HVACEquipment_query = "SELECT #{colName} FROM tabulardatawithstrings WHERE "
      strvec_HVACEquipment_query << "ReportName='EquipmentSummary' and "
      strvec_HVACEquipment_query << "ReportForString='Entire Facility'"
      strvec_HVACEquipment_query << "ORDER BY TableName, ColumnName, RowName, Units, Value"

      query_results = @sqlFile.execAndReturnVectorOfString(strvec_HVACEquipment_query).get

      if query_results.empty?
        @runner.registerError("Could not get data for requested Column #{colName}.")
        return []
      else
        return query_results
      end
  end

  # Accessor to support unit tests
  def zone_collection
	@zone_collection
  end
  
end #end the measure

#this allows the measure to be use by the application
ZoneReport.new.registerWithApplication