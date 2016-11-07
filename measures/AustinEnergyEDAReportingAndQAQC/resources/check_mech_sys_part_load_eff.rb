module OsLib_QAQC

  # include any general notes about QAQC method here
  # 'standard performance curves' based on what is in OpenStudio standards for prototype building
  # initially the tollerance will be hard coded vs. passed in as a method argument

  #checks the number of unmet hours in the model
  def check_mech_sys_part_load_eff(category,target_standard,min_pass,max_pass)

    if target_standard.include?('90.1')
      display_standard = "ASHRAE #{target_standard}"
    else
      display_standard = target_standard
    end

    component_type_array = ["ChillerElectricEIR","CoilCoolingDXSingleSpeed","CoilCoolingDXTwoSpeed","CoilHeatingDXSingleSpeed"]

    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "Mechanical System Part Load Efficiency")
    check_elems << OpenStudio::Attribute.new("category", category)
    check_elems << OpenStudio::Attribute.new("description", "Check 40% and 80% part load efficency against #{display_standard} for the following compenent types: #{component_type_array.join(", ")}. Checking EIR Function of Part Load Ratio curve for chiller and EIR Function of Flow Fraction for DX coils.")
    # todo - add in check for VAV fan

    begin

      # check getChillerElectricEIRs objects (will also have curve check in different script)
      @model.getChillerElectricEIRs.each do |component|
        # get curve and evaluate
        electric_input_to_cooling_output_ratio_function_of_PLR = component.electricInputToCoolingOutputRatioFunctionOfPLR
        curve_40_pct = electric_input_to_cooling_output_ratio_function_of_PLR.evaluate(0.4)
        curve_80_pct = electric_input_to_cooling_output_ratio_function_of_PLR.evaluate(0.8)

        # find ac properties
        search_criteria = component.find_search_criteria(target_standard)
        capacity_btu_per_hr = component.find_capacity
        chlr_props = component.model.find_object($os_standards["chillers"], search_criteria, capacity_btu_per_hr)

        # temp model to hold temp curve
        model_temp = OpenStudio::Model::Model.new

        # create temp curve
        target_curve_name = chlr_props["eirfplr"]
        if target_curve_name.nil?
          check_elems <<  OpenStudio::Attribute.new("flag", "Can't find target eirfplr curve for #{component.name}")
          next # don't go past here in loop if can't find curve
        end
        temp_curve = model_temp.add_curve(target_curve_name)
        target_curve_40_pct = temp_curve.evaluate(0.4)
        target_curve_80_pct = temp_curve.evaluate(0.8)

        # check curve at two points
        if curve_40_pct < target_curve_40_pct*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 40% of #{curve_40_pct.round(2)} for #{component.name} is more than #{min_pass*100} % below the typical value of #{target_curve_40_pct.round(2)} for #{display_standard}.")
        elsif curve_40_pct > target_curve_40_pct*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 40% of #{curve_40_pct.round(2)} for #{component.name} is more than #{max_pass*100} % above the typical value of #{target_curve_40_pct.round(2)} for #{display_standard}.")
        end
        if curve_80_pct < target_curve_80_pct*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 80% of #{curve_80_pct.round(2)} for #{component.name} is more than #{min_pass*100} % below the typical value of #{target_curve_80_pct.round(2)} for #{display_standard}.")
        elsif curve_80_pct > target_curve_80_pct*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 80% of #{curve_80_pct.round(2)} for #{component.name} is more than #{max_pass*100} % above the typical value of #{target_curve_80_pct.round(2)} for #{display_standard}.")
        end
      end

      # check getCoilCoolingDXSingleSpeeds objects (will also have curve check in different script)
      @model.getCoilCoolingDXSingleSpeeds.each do |component|
        # get curve and evaluate
        eir_function_of_flow_fraction_curve = component.energyInputRatioFunctionOfFlowFractionCurve
        curve_40_pct = eir_function_of_flow_fraction_curve.evaluate(0.4)
        curve_80_pct = eir_function_of_flow_fraction_curve.evaluate(0.8)

        # find ac properties
        search_criteria = component.find_search_criteria(target_standard)
        capacity_btu_per_hr = component.find_capacity
        ac_props = component.model.find_object($os_standards["unitary_acs"], search_criteria, capacity_btu_per_hr)

        # temp model to hold temp curve
        model_temp = OpenStudio::Model::Model.new

        # create temp curve
        target_curve_name = ac_props["cool_eir_fflow"]
        if target_curve_name.nil?
          check_elems <<  OpenStudio::Attribute.new("flag", "Can't find target cool_eir_fflow curve for #{component.name}")
          next # don't go past here in loop if can't find curve
        end
        temp_curve = model_temp.add_curve(target_curve_name)
        target_curve_40_pct = temp_curve.evaluate(0.4)
        target_curve_80_pct = temp_curve.evaluate(0.8)

        # check curve at two points
        if curve_40_pct < target_curve_40_pct*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 40% of #{curve_40_pct.round(2)} for #{component.name} is more than #{min_pass*100} % below the typical value of #{target_curve_40_pct.round(2)} for #{display_standard}.")
        elsif curve_40_pct > target_curve_40_pct*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 40% of #{curve_40_pct.round(2)} for #{component.name} is more than #{max_pass*100} % above the typical value of #{target_curve_40_pct.round(2)} for #{display_standard}.")
        end
        if curve_80_pct < target_curve_80_pct*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 80% of #{curve_80_pct.round(2)} for #{component.name} is more than #{min_pass*100} % below the typical value of #{target_curve_80_pct.round(2)} for #{display_standard}.")
        elsif curve_80_pct > target_curve_80_pct*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 80% of #{curve_80_pct.round(2)} for #{component.name} is more than #{max_pass*100} % above the typical value of #{target_curve_80_pct.round(2)} for #{display_standard}.")
        end
      end

      # check CoilCoolingDXTwoSpeed objects (will also have curve check in different script)
      @model.getCoilCoolingDXTwoSpeeds.each do |component|
        # get curve and evaluate
        eir_function_of_flow_fraction_curve = component.energyInputRatioFunctionOfFlowFractionCurve
        curve_40_pct = eir_function_of_flow_fraction_curve.evaluate(0.4)
        curve_80_pct = eir_function_of_flow_fraction_curve.evaluate(0.8)

        # find ac properties
        search_criteria = component.find_search_criteria(target_standard)
        capacity_btu_per_hr = component.find_capacity
        ac_props = component.model.find_object($os_standards["unitary_acs"], search_criteria, capacity_btu_per_hr)

        # temp model to hold temp curve
        model_temp = OpenStudio::Model::Model.new

        # create temp curve
        target_curve_name = ac_props["cool_eir_fflow"]
        if target_curve_name.nil?
          check_elems <<  OpenStudio::Attribute.new("flag", "Can't find target cool_eir_flow curve for #{component.name}")
          next # don't go past here in loop if can't find curve
        end
        temp_curve = model_temp.add_curve(target_curve_name)
        target_curve_40_pct = temp_curve.evaluate(0.4)
        target_curve_80_pct = temp_curve.evaluate(0.8)

        # check curve at two points
        if curve_40_pct < target_curve_40_pct*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 40% of #{curve_40_pct.round(2)} for #{component.name} is more than #{min_pass*100} % below the typical value of #{target_curve_40_pct.round(2)} for #{display_standard}.")
        elsif curve_40_pct > target_curve_40_pct*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 40% of #{curve_40_pct.round(2)} for #{component.name} is more than #{max_pass*100} % above the typical value of #{target_curve_40_pct.round(2)} for #{display_standard}.")
        end
        if curve_80_pct < target_curve_80_pct*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 80% of #{curve_80_pct.round(2)} for #{component.name} is more than #{min_pass*100} % below the typical value of #{target_curve_80_pct.round(2)} for #{display_standard}.")
        elsif curve_80_pct > target_curve_80_pct*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 80% of #{curve_80_pct.round(2)} for #{component.name} is more than #{max_pass*100} % above the typical value of #{target_curve_80_pct.round(2)} for #{display_standard}.")
        end
      end

      # check CoilCoolingDXTwoSpeed objects (will also have curve check in different script)
      @model.getCoilHeatingDXSingleSpeeds.each do |component|
        # get curve and evaluate
        eir_function_of_flow_fraction_curve = component.energyInputRatioFunctionofFlowFractionCurve  # why lowercase of here but not in CoilCoolingDX objects
        curve_40_pct = eir_function_of_flow_fraction_curve.evaluate(0.4)
        curve_80_pct = eir_function_of_flow_fraction_curve.evaluate(0.8)

        # find ac properties
        search_criteria = component.find_search_criteria(target_standard)
        capacity_btu_per_hr = component.find_capacity
        heat_pump = false
        if component.airLoopHVAC.empty?
          if component.containingHVACComponent.is_initialized
            containing_comp = component.containingHVACComponent.get
            if containing_comp.to_AirLoopHVACUnitaryHeatPumpAirToAir.is_initialized
              heat_pump = true
            end
          end
        end
        ac_props = nil
        if heat_pump == true
          ac_props = component.model.find_object($os_standards['heat_pumps_heating'], search_criteria, capacity_btu_per_hr)
          if ac_props.nil?
            target_curve_name = nil
          else
            target_curve_name = ac_props["heat_eir_fflow"]
          end
        else
          ac_props = component.model.find_object($os_standards['heat_pumps'], search_criteria, capacity_btu_per_hr)
          if ac_props.nil?
            target_curve_name = nil
          else
            target_curve_name = ac_props["cool_eir_fflow"]
          end
        end

        # temp model to hold temp curve
        model_temp = OpenStudio::Model::Model.new

        # create temp curve
        if target_curve_name.nil?
          check_elems <<  OpenStudio::Attribute.new("flag", "Can't find target curve for #{component.name}")
          next # don't go past here in loop if can't find curve
        end
        temp_curve = model_temp.add_curve(target_curve_name)
        target_curve_40_pct = temp_curve.evaluate(0.4)
        target_curve_80_pct = temp_curve.evaluate(0.8)

        # check curve at two points
        if curve_40_pct < target_curve_40_pct*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 40% of #{curve_40_pct.round(2)} for #{component.name} is more than #{min_pass*100} % below the typical value of #{target_curve_40_pct.round(2)} for #{display_standard}.")
        elsif curve_40_pct > target_curve_40_pct*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 40% of #{curve_40_pct.round(2)} for #{component.name} is more than #{max_pass*100} % above the typical value of #{target_curve_40_pct.round(2)} for #{display_standard}.")
        end
        if curve_80_pct < target_curve_80_pct*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 80% of #{curve_80_pct.round(2)} for #{component.name} is more than #{min_pass*100} % below the typical value of #{target_curve_80_pct.round(2)} for #{display_standard}.")
        elsif curve_80_pct > target_curve_80_pct*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 80% of #{curve_80_pct.round(2)} for #{component.name} is more than #{max_pass*100} % above the typical value of #{target_curve_80_pct.round(2)} for #{display_standard}.")
        end
      end

      # check
      @model.getFanVariableVolumes.each do |component|


        # skip if not on multi-zone system.
        if component.airLoopHVAC.is_initialized
          airloop = component.airLoopHVAC.get

          next unless airloop.thermalZones.size > 1.0
        end

        # skip of brake horsepower is 0
        next if component.brakeHorsepower == 0.0

        # temp model for use by temp model and target curve
        model_temp = OpenStudio::Model::Model.new

        # get coeficents for fan
        model_fan_coefs = []
        model_fan_coefs << component.fanPowerCoefficient1.get
        model_fan_coefs << component.fanPowerCoefficient2.get
        model_fan_coefs << component.fanPowerCoefficient3.get
        model_fan_coefs << component.fanPowerCoefficient4.get
        model_fan_coefs << component.fanPowerCoefficient5.get

        # make model curve
        model_curve = OpenStudio::Model::CurveQuartic.new(model_temp)
        model_curve.setCoefficient1Constant(model_fan_coefs[0])
        model_curve.setCoefficient2x(model_fan_coefs[1])
        model_curve.setCoefficient3xPOW2(model_fan_coefs[2])
        model_curve.setCoefficient4xPOW3(model_fan_coefs[3])
        model_curve.setCoefficient5xPOW4(model_fan_coefs[4])
        curve_40_pct = model_curve.evaluate(0.4)
        curve_80_pct = model_curve.evaluate(0.8)

        # get target coefs
        target_fan = OpenStudio::Model::FanVariableVolume.new(model_temp)
        target_fan.set_control_type('Multi Zone VAV with Static Pressure Reset')

        # get coeficents for fan
        target_fan_coefs = []
        target_fan_coefs << target_fan.fanPowerCoefficient1.get
        target_fan_coefs << target_fan.fanPowerCoefficient2.get
        target_fan_coefs << target_fan.fanPowerCoefficient3.get
        target_fan_coefs << target_fan.fanPowerCoefficient4.get
        target_fan_coefs << target_fan.fanPowerCoefficient5.get

        # make model curve
        target_curve = OpenStudio::Model::CurveQuartic.new(model_temp)
        target_curve.setCoefficient1Constant(target_fan_coefs[0])
        target_curve.setCoefficient2x(target_fan_coefs[1])
        target_curve.setCoefficient3xPOW2(target_fan_coefs[2])
        target_curve.setCoefficient4xPOW3(target_fan_coefs[3])
        target_curve.setCoefficient5xPOW4(target_fan_coefs[4])
        target_curve_40_pct = target_curve.evaluate(0.4)
        target_curve_80_pct = target_curve.evaluate(0.8)

        # check curve at two points
        if curve_40_pct < target_curve_40_pct*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 40% of #{curve_40_pct.round(2)} for #{component.name} is more than #{min_pass*100} % below the typical value of #{target_curve_40_pct.round(2)} for #{display_standard}.")
        elsif curve_40_pct > target_curve_40_pct*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 40% of #{curve_40_pct.round(2)} for #{component.name} is more than #{max_pass*100} % above the typical value of #{target_curve_40_pct.round(2)} for #{display_standard}.")
        end
        if curve_80_pct < target_curve_80_pct*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 80% of #{curve_80_pct.round(2)} for #{component.name} is more than #{min_pass*100} % below the typical value of #{target_curve_80_pct.round(2)} for #{display_standard}.")
        elsif curve_80_pct > target_curve_80_pct*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The curve value at 80% of #{curve_80_pct.round(2)} for #{component.name} is more than #{max_pass*100} % above the typical value of #{target_curve_80_pct.round(2)} for #{display_standard}.")
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