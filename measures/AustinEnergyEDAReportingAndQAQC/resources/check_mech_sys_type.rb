module OsLib_QAQC

  # include any general notes about QAQC method here

  #checks the number of unmet hours in the model
  def check_mech_sys_type(category,target_standard)
    
    # add ASHRAE to display of target standard if includes with 90.1
    if target_standard.include?('90.1')
      display_standard = "ASHRAE #{target_standard} Tables G3.1.1 A-B"
    else
      display_standard = target_standard
    end

    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "Mechanical System Type")
    check_elems << OpenStudio::Attribute.new("category", category)
    check_elems << OpenStudio::Attribute.new("description", "Check against #{display_standard}. Infers the baseline system type based on the equipment serving the zone and their heating/cooling fuels. Only does a high-level inference; does not look for the presence/absence of required controls, etc.")

    begin

      # get ashrae climate zone from model
      model_climate_zone = nil
      climateZones = @model.getClimateZones
      climateZones.climateZones.each do |climateZone|
        if climateZone.institution == "ASHRAE"
          model_climate_zone = climateZone.value
          next
        end
      end

      # Get the actual system type for all zones in the model
      act_zone_to_sys_type = {}
      @model.getThermalZones.each do |zone|
        act_zone_to_sys_type[zone] = zone.infer_system_type
      end

      # Get the baseline system type for all zones in the model
      # for now pass in climate zone, but if utility has multiple climate zones then change to get from model
      req_zone_to_sys_type = @model.get_baseline_system_type_by_zone(target_standard, model_climate_zone)

      # Compare the actual to the correct
      @model.getThermalZones.each do |zone|

        # todo - skip if plenum
        is_plenum = false
        zone.spaces.each do |space|
          if space.is_plenum
            is_plenum = true
          end
        end
        next if is_plenum

        req_sys_type = req_zone_to_sys_type[zone]
        act_sys_type = act_zone_to_sys_type[zone]

        if act_sys_type == req_sys_type
          puts "#{zone.name} system type = #{act_sys_type}"
        else
          if req_sys_type == "" then req_sys_type = "Unknown" end
          puts "#{zone.name} baseline system type is incorrect. Supposed to be #{req_sys_type}, but was #{act_sys_type} instead."
          check_elems << OpenStudio::Attribute.new("flag", "#{zone.name} baseline system type is incorrect. Supposed to be #{req_sys_type}, but was #{act_sys_type} instead.")
        end

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