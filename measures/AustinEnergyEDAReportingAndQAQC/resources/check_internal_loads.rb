module OsLib_QAQC

  # include any general notes about QAQC method here

  #checks the number of unmet hours in the model
  def check_internal_loads(category,target_standard,min_pass,max_pass)

    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "Internal Loads")
    check_elems << OpenStudio::Attribute.new("category", category)
    if target_standard == "ICC IECC 2015"
      check_elems << OpenStudio::Attribute.new("description", "Check internal loads against Table R405.5.2(1) in ICC IECC 2015 Residential Provisions.")
    else

      if target_standard.include?('90.1')
        display_standard = "ASHRAE #{target_standard}"
      else
        display_standard = target_standard
      end

      check_elems << OpenStudio::Attribute.new("description", "Check LPD, ventilation rates, occupant density, plug loads, and equipment loads against #{display_standard} and DOE Prototype buildings.")
    end

    begin

      if target_standard == "ICC IECC 2015"

        num_people = 0.0
        @model.getSpaceTypes.each do |space_type|
          next if not space_type.standardsSpaceType.is_initialized
          next if not space_type.standardsSpaceType.get == "Apartment" # currently only supports midrise apt space type
          space_type_floor_area = space_type.floorArea
          space_type_num_people = space_type.getNumberOfPeople(space_type_floor_area)
          num_people += space_type_num_people
        end

        # lookup iecc internal loads for the building
        bedrooms_per_unit = 2.0 # assumption
        num_units = num_people / 2.5 # Avg 2.5 units per person.
        target_loads_hash = @model.find_icc_iecc_2015_internal_loads(num_units,bedrooms_per_unit)

        # get model internal gains for lights, elec equipment, and gas equipment
        model_internal_gains_si = 0.0
        query_eleint_lights = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' and TableName='End Uses' and RowName= 'Interior Lighting' and ColumnName= 'Electricity'"
        query_elec_equip = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' and TableName='End Uses' and RowName= 'Interior Equipment' and ColumnName= 'Electricity'"
        query_gas_equip = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' and TableName='End Uses' and RowName= 'Interior Equipment' and ColumnName= 'Natural Gas'"
        model_internal_gains_si += results_elec = @sql.execAndReturnFirstDouble(query_eleint_lights).get
        model_internal_gains_si += results_elec = @sql.execAndReturnFirstDouble(query_elec_equip).get
        model_internal_gains_si += results_elec = @sql.execAndReturnFirstDouble(query_gas_equip).get
        model_internal_gains_si_kbtu_per_day = OpenStudio.convert(model_internal_gains_si,"GJ",'kBtu').get/365.0 # assumes annual run

        # get target internal loads
        target_igain_btu_per_day = target_loads_hash['igain_btu_per_day']
        target_igain_kbtu_per_day = OpenStudio.convert(target_igain_btu_per_day,"Btu",'kBtu').get

        # check internal loads
        if model_internal_gains_si_kbtu_per_day < target_igain_kbtu_per_day*(1.0 - min_pass)
          check_elems << OpenStudio::Attribute.new("flag", "The model average of #{OpenStudio.toNeatString(model_internal_gains_si_kbtu_per_day,2,true)} (kBtu/day) is more than #{min_pass*100} % below the expected value of #{OpenStudio.toNeatString(target_igain_kbtu_per_day,2,true)} (kBtu/day) for #{target_standard}.")
        elsif model_internal_gains_si_kbtu_per_day > target_igain_kbtu_per_day*(1.0 + max_pass)
          check_elems << OpenStudio::Attribute.new("flag", "The model average of #{OpenStudio.toNeatString(model_internal_gains_si_kbtu_per_day,2,true)} (kBtu/day) is more than #{max_pass*100} % above the expected value of #{OpenStudio.toNeatString(target_igain_kbtu_per_day,2,true)} k(Btu/day) for #{target_standard}.")
        end

        # get target mech vent
        target_mech_vent_cfm = target_loads_hash['mech_vent_cfm']

        # get model mech vent
        model_mech_vent_si = 0
        @model.getSpaceTypes.each do |space_type|
          next if not space_type.floorArea > 0

          # get necessary space type information
          floor_area = space_type.floorArea
          num_people = space_type.getNumberOfPeople(floor_area)

          # get volume for space type for use with ventilation and infiltration
          space_type_volume = 0.0
          space_type_exterior_area = 0.0
          space_type_exterior_wall_area = 0.0
          space_type.spaces.each do |space|
            space_type_volume += space.volume * space.multiplier
            space_type_exterior_area = space.exteriorArea * space.multiplier
            space_type_exterior_wall_area = space.exteriorWallArea * space.multiplier
          end

          # get design spec OA object
          if space_type.designSpecificationOutdoorAir.is_initialized
            oa = space_type.designSpecificationOutdoorAir.get
            oa_method = oa.outdoorAirMethod
            oa_per_person = oa.outdoorAirFlowperPerson * num_people
            oa_ach = oa.outdoorAirFlowAirChangesperHour * space_type_volume
            oa_per_area = oa.outdoorAirFlowperFloorArea * floor_area
            oa_flow_rate = oa.outdoorAirFlowRate
            oa_space_type_total = oa_per_person + oa_ach + oa_per_area + oa_flow_rate

            value_count = 0
            if oa_per_person > 0 then value_count += 1 end
            if oa_ach > 0 then value_count += 1 end
            if oa_per_area > 0 then value_count += 1 end
            if oa_flow_rate > 0 then value_count += 1 end
            if not oa_method == "Sum" and value_count > 1
              check_elems << OpenStudio::Attribute.new("flag","Outdoor Air Method for #{space_type.name} was #{oa_method}. Expected value was Sum.")
            end
          else
            oa_space_type_total = 0.0
          end
          # add to building total oa
          model_mech_vent_si += oa_space_type_total
        end

        # check oa
        model_mech_vent_cfm = OpenStudio.convert(model_mech_vent_si,'m^3/s','cfm').get
        if model_mech_vent_cfm < target_mech_vent_cfm*(1.0 - min_pass)
          check_elems << OpenStudio::Attribute.new("flag", "The model mechanical ventilation of  #{OpenStudio.toNeatString(model_mech_vent_cfm,2,true)} cfm is more than #{min_pass*100} % below the expected value of #{OpenStudio.toNeatString(target_mech_vent_cfm,2,true)} cfm for #{target_standard}.")
        elsif model_mech_vent_cfm > target_mech_vent_cfm*(1.0 + max_pass)
          check_elems << OpenStudio::Attribute.new("flag", "The model mechanical ventilation of #{OpenStudio.toNeatString(model_mech_vent_cfm,2,true)} cfm is more than #{max_pass*100} % above the expected value of #{OpenStudio.toNeatString(target_mech_vent_cfm,2,true)} cfm for #{target_standard}.")
        end

      else

        # loop through all space types used in the model
        @model.getSpaceTypes.each do |space_type|
          next if not space_type.floorArea > 0

          # get necessary space type information
          floor_area = space_type.floorArea
          num_people = space_type.getNumberOfPeople(floor_area)

          # load in standard info for this space type
          data = space_type.get_standards_data(target_standard)

          if data == nil or data.size == 0

            # skip if all spaces using this space type are plenums
            all_spaces_plenums = true
            space_type.spaces.each do |space|
              if not space.is_plenum
                all_spaces_plenums = false
                next
              end
            end

            if not all_spaces_plenums
              check_elems << OpenStudio::Attribute.new("flag", "Unexpected standards type for #{space_type.name}, can't validate internal loads.")
            end

            next
          end

          # check lpd for space type
          model_lights_si = space_type.getLightingPowerPerFloorArea(floor_area,num_people)
          if data['lighting_per_area'] == nil then target_lights_ip = 0.0 else target_lights_ip = data['lighting_per_area'] end
          source_units = 'W/m^2'
          target_units = 'W/ft^2'
          load_type = "Lighting Power Density"
          model_ip = OpenStudio.convert(model_lights_si, source_units, target_units).get
          target_ip = target_lights_ip.to_f
          model_ip_neat = OpenStudio.toNeatString(model_ip, 2, true)
          target_ip_neat = OpenStudio.toNeatString(target_ip, 2, true)
          if model_ip < target_ip*(1.0 - min_pass)
            check_elems << OpenStudio::Attribute.new("flag", "#{load_type} of #{model_ip_neat} (#{target_units}) for #{space_type.name} is more than #{min_pass*100} % below the expected value of #{target_ip_neat} (#{target_units}) for #{display_standard}.")
          elsif model_ip > target_ip*(1.0 + max_pass)
            check_elems << OpenStudio::Attribute.new("flag", "#{load_type} of #{model_ip_neat} (#{target_units}) for #{space_type.name} is more than #{max_pass*100} % above the expected value of #{target_ip_neat} (#{target_units}) for #{display_standard}.")
          end

          # check electric equipment
          model_elec_si = space_type.getElectricEquipmentPowerPerFloorArea(floor_area,num_people)
          if data['electric_equipment_per_area'] == nil then target_elec_ip = 0.0 else target_elec_ip = data['electric_equipment_per_area'] end
          source_units = 'W/m^2'
          target_units = 'W/ft^2'
          load_type = "Electric Power Density"
          model_ip = OpenStudio.convert(model_elec_si, source_units, target_units).get
          target_ip = target_elec_ip.to_f
          model_ip_neat = OpenStudio.toNeatString(model_ip, 2, true)
          target_ip_neat = OpenStudio.toNeatString(target_ip, 2, true)
          if model_ip < target_ip*(1.0 - min_pass)
            check_elems << OpenStudio::Attribute.new("flag", "#{load_type} of #{model_ip_neat} (#{target_units}) for #{space_type.name} is more than #{min_pass*100} % below the expected value of #{target_ip_neat} (#{target_units}) for #{display_standard}.")
          elsif model_ip > target_ip*(1.0 + max_pass)
            check_elems << OpenStudio::Attribute.new("flag", "#{load_type} of #{model_ip_neat} (#{target_units}) for #{space_type.name} is more than #{max_pass*100} % above the expected value of #{target_ip_neat} (#{target_units}) for #{display_standard}.")
          end

          # check gas equipment
          model_gas_si = space_type.getGasEquipmentPowerPerFloorArea(floor_area,num_people)
          if data['gas_equipment_per_area'] == nil then target_gas_ip = 0.0 else target_gas_ip = data['gas_equipment_per_area'] end
          source_units = 'W/m^2'
          target_units = 'Btu/hr*ft^2'
          load_type = "Gas Power Density"
          model_ip = OpenStudio.convert(model_gas_si, source_units, target_units).get
          target_ip = target_gas_ip.to_f
          model_ip_neat = OpenStudio.toNeatString(model_ip, 2, true)
          target_ip_neat = OpenStudio.toNeatString(target_ip, 2, true)
          if model_ip < target_ip*(1.0 - min_pass)
            check_elems << OpenStudio::Attribute.new("flag", "#{load_type} of #{model_ip_neat} (#{target_units}) for #{space_type.name} is more than #{min_pass*100} % below the expected value of #{target_ip_neat} (#{target_units}) for #{display_standard}.")
          elsif model_ip > target_ip*(1.0 + max_pass)
            check_elems << OpenStudio::Attribute.new("flag", "#{load_type} of #{model_ip_neat} (#{target_units}) for #{space_type.name} is more than #{max_pass*100} % above the expected value of #{target_ip_neat} (#{target_units}) for #{display_standard}.")
          end

          # check people
          model_occ_si = space_type.getPeoplePerFloorArea(floor_area)
          if data['occupancy_per_area'] == nil then target_occ_ip = 0.0 else target_occ_ip = data['occupancy_per_area'] end
          source_units = '1/m^2' # people/m^2
          target_units = '1/ft^2' # people per ft^2 (can't add *1000) to the bottom, need to do later
          load_type = "Occupancy per Area"
          model_ip = OpenStudio.convert(model_occ_si, source_units, target_units).get*1000.0
          target_ip = target_occ_ip.to_f
          model_ip_neat = OpenStudio.toNeatString(model_ip, 2, true)
          target_ip_neat = OpenStudio.toNeatString(target_ip, 2, true)
          # for people need to update target units just for display. Can't be used for converstion.
          target_units = 'People/1000 ft^2'
          if model_ip < target_ip*(1.0 - min_pass)
            check_elems << OpenStudio::Attribute.new("flag", "#{load_type} of #{model_ip_neat} (#{target_units}) for #{space_type.name} is more than #{min_pass*100} % below the expected value of #{target_ip_neat} (#{target_units}) for #{display_standard}.")
          elsif model_ip > target_ip*(1.0 + max_pass)
            check_elems << OpenStudio::Attribute.new("flag", "#{load_type} of #{model_ip_neat} (#{target_units}) for #{space_type.name} is more than #{max_pass*100} % above the expected value of #{target_ip_neat} (#{target_units}) for #{display_standard}.")
          end

          # get volume for space type for use with ventilation and infiltration
          space_type_volume = 0.0
          space_type_exterior_area = 0.0
          space_type_exterior_wall_area = 0.0
          space_type.spaces.each do |space|
            space_type_volume += space.volume * space.multiplier
            space_type_exterior_area = space.exteriorArea * space.multiplier
            space_type_exterior_wall_area = space.exteriorWallArea * space.multiplier
          end

          # get design spec OA object
          if space_type.designSpecificationOutdoorAir.is_initialized
            oa = space_type.designSpecificationOutdoorAir.get
            oa_method = oa.outdoorAirMethod
            oa_per_person = oa.outdoorAirFlowperPerson
            oa_other = 0.0
            oa_ach = oa.outdoorAirFlowAirChangesperHour * space_type_volume
            oa_per_area = oa.outdoorAirFlowperFloorArea * floor_area
            oa_flow_rate = oa.outdoorAirFlowRate
            oa_total = oa_ach + oa_per_area + oa_flow_rate

            value_count = 0
            if oa_per_person > 0 then value_count += 1 end
            if oa_ach > 0 then value_count += 1 end
            if oa_per_area > 0 then value_count += 1 end
            if oa_flow_rate > 0 then value_count += 1 end
            if not oa_method == "Sum" and value_count > 1
              check_elems << OpenStudio::Attribute.new("flag","Outdoor Air Method for #{space_type.name} was #{oa_method}. Expected value was Sum.")
            end
          else
            oa_per_person = 0.0
            oa_other_total = 0.0
          end

          # get target values for OA
          target_oa_per_person_ip = data['ventilation_per_person'].to_f #ft^3/min*person
          target_oa_ach_ip = data['ventilation_air_changes'].to_f #ach
          target_oa_per_area_ip = data['ventilation_per_area'].to_f #ft^3/min*ft^2
          if target_oa_per_person_ip == nil
            target_oa_per_person_si = 0.0
          else
            target_oa_per_person_si = OpenStudio.convert(target_oa_per_person_ip,'cfm','m^3/s').get
          end
          if target_oa_ach_ip == nil
            target_oa_ach_si = 0.0
          else
            target_oa_ach_si = target_oa_ach_ip * space_type_volume
          end
          if target_oa_per_area_ip == nil
            target_oa_per_area_si = 0.0
          else
            target_oa_per_area_si = OpenStudio.convert(target_oa_per_area_ip,'cfm/ft^2','m^3/s*m^2').get * floor_area
          end
          target_oa_total = target_oa_ach_si + target_oa_per_area_si

          # check oa per person
          source_units = 'm^3/s'
          target_units = 'cfm'
          load_type = "Outdoor Air Per Person"
          model_ip_neat = OpenStudio.toNeatString(OpenStudio.convert(oa_per_person,source_units,target_units).get, 2, true)
          target_ip_neat = OpenStudio.toNeatString(target_oa_per_person_ip, 2, true)
          if oa_per_person < target_oa_per_person_si*(1.0 - min_pass)
            check_elems << OpenStudio::Attribute.new("flag", "#{load_type} of #{model_ip_neat} (#{target_units}) for #{space_type.name} is more than #{min_pass*100} % below the expected value of #{target_ip_neat} (#{target_units}) for #{display_standard}.")
          elsif oa_per_person > target_oa_per_person_si*(1.0 + max_pass)
            check_elems << OpenStudio::Attribute.new("flag", "#{load_type} of #{model_ip_neat} (#{target_units}) for #{space_type.name} is more than #{max_pass*100} % above the expected value of #{target_ip_neat} (#{target_units}) for #{display_standard}.")
          end

          # check other oa
          source_units = 'm^3/s'
          target_units = 'cfm'
          load_type = "Outdoor Air (Excluding per Person Value)"
          model_ip_neat = OpenStudio.toNeatString(OpenStudio.convert(oa_total,source_units,target_units).get, 2, true)
          target_ip_neat = OpenStudio.toNeatString(OpenStudio.convert(target_oa_total,source_units,target_units).get, 2, true)
          if oa_total < target_oa_total*(1.0 - min_pass)
            check_elems << OpenStudio::Attribute.new("flag", "#{load_type} of #{model_ip_neat} (#{target_units}) for #{space_type.name} is more than #{min_pass*100} % below the expected value of #{target_ip_neat} (#{target_units}) for #{display_standard}.")
          elsif oa_total > target_oa_total*(1.0 + max_pass)
            check_elems << OpenStudio::Attribute.new("flag", "#{load_type} of #{model_ip_neat} (#{target_units}) for #{space_type.name} is more than #{max_pass*100} % above the expected value of #{target_ip_neat} (#{target_units}) for #{display_standard}.")
          end

        end

        # warn if there are spaces in model that don't use space type unless they appear to be plenums
        @model.getSpaces.each do |space|
          next if space.is_plenum
          if not space.spaceType.is_initialized
            check_elems << OpenStudio::Attribute.new("flag", "#{space.name} doesn't have a space type assigned, can't validate internal loads.")
          end
        end

        # todo - need to address internal loads where fuel is variable like cooking and laundry
        # todo - For now we are not going to loop through spaces looking for loads beyond what comes from space type
        # todo - space infiltration

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