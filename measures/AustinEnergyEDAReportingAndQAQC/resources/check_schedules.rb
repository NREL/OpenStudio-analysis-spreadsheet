module OsLib_QAQC

  # include any general notes about QAQC method here

  #checks the number of unmet hours in the model
  def check_schedules(category,target_standard,min_pass,max_pass)

    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "Schedules")
    check_elems << OpenStudio::Attribute.new("category", category)
    check_elems << OpenStudio::Attribute.new("description", "Check schedules for lighting, ventilation, occupant density, plug loads, and equipment based on DOE reference building schedules in terms of full load hours per year.")

    begin

      # loop through all space types used in the model
      @model.getSpaceTypes.each do |space_type|
        next if not space_type.floorArea > 0

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
            check_elems << OpenStudio::Attribute.new("flag", "Unexpected standards type for #{space_type.name}, can't validate schedules.")
          end

          next
        end

        # temp model to hold schedules to check
        model_temp = OpenStudio::Model::Model.new

        # check lighting schedules
        if data['lighting_per_area'] == nil then target_ip = 0.0 else target_ip = data['lighting_per_area'] end
        if target_ip.to_f > 0
          schedule_target = model_temp.add_schedule(data['lighting_schedule'])
          if not schedule_target
            check_elems << OpenStudio::Attribute.new("flag", "Didn't find schedule named #{data['lighting_schedule']} in standards json.")
          else
            # loop through and test individual load instances
            target_hrs = schedule_target.annual_equivalent_full_load_hrs
            space_type.lights.each do |load_inst|
              inst_sch_check = generate_load_insc_sch_check_attribute(target_hrs,load_inst,space_type,check_elems,min_pass,max_pass)
              if inst_sch_check then check_elems << inst_sch_check end
            end

          end
        end

        # check electric equipment schedules
        if data['electric_equipment_per_area'] == nil then target_ip = 0.0 else target_ip = data['electric_equipment_per_area'] end
        if target_ip.to_f > 0
          schedule_target = model_temp.add_schedule(data['electric_equipment_schedule'])
          if not schedule_target
            check_elems << OpenStudio::Attribute.new("flag", "Didn't find schedule named #{data['electric_equipment_schedule']} in standards json.")
          else
            # loop through and test individual load instances
            target_hrs = schedule_target.annual_equivalent_full_load_hrs
            space_type.electricEquipment.each do |load_inst|
              inst_sch_check = generate_load_insc_sch_check_attribute(target_hrs,load_inst,space_type,check_elems,min_pass,max_pass)
              if inst_sch_check then check_elems << inst_sch_check end
            end
          end
        end

        # check gas equipment schedules
        # todo - update measure test to with space type to check this
        if data['gas_equipment_per_area'] == nil then target_ip = 0.0 else target_ip = data['gas_equipment_per_area'] end
        if target_ip.to_f > 0
          schedule_target = model_temp.add_schedule(data['gas_equipment_schedule'])
          if not schedule_target
            check_elems << OpenStudio::Attribute.new("flag", "Didn't find schedule named #{data['gas_equipment_schedule']} in standards json.")
          else
            # loop through and test individual load instances
            target_hrs = schedule_target.annual_equivalent_full_load_hrs
            space_type.gasEquipment.each do |load_inst|
              inst_sch_check = generate_load_insc_sch_check_attribute(target_hrs,load_inst,space_type,check_elems,min_pass,max_pass)
              if inst_sch_check then check_elems << inst_sch_check end
            end
          end
        end

        # check occupancy schedules
        if data['occupancy_per_area'] == nil then target_ip = 0.0 else target_ip = data['occupancy_per_area'] end
        if target_ip.to_f > 0
          schedule_target = model_temp.add_schedule(data['occupancy_schedule'])
          if not schedule_target
            check_elems << OpenStudio::Attribute.new("flag", "Didn't find schedule named #{data['occupancy_schedule']} in standards json.")
          else
            # loop through and test individual load instances
            target_hrs = schedule_target.annual_equivalent_full_load_hrs
            space_type.people.each do |load_inst|
              inst_sch_check = generate_load_insc_sch_check_attribute(target_hrs,load_inst,space_type,check_elems,min_pass,max_pass)
              if inst_sch_check then check_elems << inst_sch_check end
            end

          end
        end

        # todo - check ventilation schedules
        # if objects are in the model should they just be always on schedule, or have a 8760 annual equiv value
        # oa_schedule should not exist, or if it does shoudl be always on or have 8760 annual equiv value
        if space_type.designSpecificationOutdoorAir.is_initialized
          oa = space_type.designSpecificationOutdoorAir.get
          if oa.outdoorAirFlowRateFractionSchedule.is_initialized
            # todo - update measure test to check this
            target_hrs = 8760
            inst_sch_check = generate_load_insc_sch_check_attribute(target_hrs,oa,space_type,check_elems,min_pass,max_pass)
            if inst_sch_check then check_elems << inst_sch_check end
          end
        end

        # notes
        # current logic only looks at 8760 values and not design days
        # when multiple instances of a type currently check every schedule by itself. In future could do weighted avg. merge
        # not looking at infiltration schedules
        # not looking at luminaires
        # not looking at space loads, only loads at space type
        # only checking schedules where standard shows non zero load value
        # model load for space type where standards doesn't have one wont throw flag about mis-matched schedules

      end

      # warn if there are spaces in model that don't use space type unless they appear to be plenums
      @model.getSpaces.each do |space|
        next if space.is_plenum
        if not space.spaceType.is_initialized
          check_elems << OpenStudio::Attribute.new("flag", "#{space.name} doesn't have a space type assigned, can't validate schedules.")
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

  # code for each load instance for different load types will pass through here
  # will return nill or a single attribute
  def generate_load_insc_sch_check_attribute(target_hrs,load_inst,space_type,check_elems,min_pass,max_pass)

    schedule_inst = nil
    inst_hrs = nil

    # get schedule
    if load_inst.class.to_s == "OpenStudio::Model::People"  and load_inst.numberofPeopleSchedule.is_initialized
      schedule_inst = load_inst.numberofPeopleSchedule.get
    elsif load_inst.class.to_s == "OpenStudio::Model::DesignSpecificationOutdoorAir"  and load_inst.outdoorAirFlowRateFractionSchedule.is_initialized
      schedule_inst = load_inst.outdoorAirFlowRateFractionSchedule .get
    elsif load_inst.schedule.is_initialized
      schedule_inst = load_inst.schedule.get
    else
      return OpenStudio::Attribute.new("flag", "#{load_inst.name} in #{space_type.name} doesn't have a schedule assigned.")
    end

    # get annual equiv for model schedule
    if schedule_inst.to_ScheduleRuleset.is_initialized
      inst_hrs = schedule_inst.to_ScheduleRuleset.get.annual_equivalent_full_load_hrs
    elsif schedule_inst.to_ScheduleConstant.is_initialized
      inst_hrs = schedule_inst.to_ScheduleConstant.get.annual_equivalent_full_load_hrs
    else
      return OpenStudio::Attribute.new("flag", "#{schedule_inst.name} isn't a Ruleset or Constant schedule. Can't calculate annual equivalent full load hours.")
    end

    # check instance against target
    if inst_hrs < target_hrs*(1.0 - min_pass)
      return OpenStudio::Attribute.new("flag", "#{inst_hrs.round} annual equivalent full load hours for #{schedule_inst.name} in #{space_type.name} is more than #{min_pass*100} (%) below the typical value of #{target_hrs.round} hours from the DOE Prototype building.")
    elsif inst_hrs > target_hrs*(1.0 + max_pass)
      return OpenStudio::Attribute.new("flag", "#{inst_hrs.round} annual equivalent full load hours for #{schedule_inst.name} in #{space_type.name}  is more than #{max_pass*100} (%) above the typical value of #{target_hrs.round} hours DOE Prototype building.")
    end

    # will get to this if no flag was thrown
    return false

  end

end  