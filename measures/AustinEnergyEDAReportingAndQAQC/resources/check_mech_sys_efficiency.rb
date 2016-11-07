module OsLib_QAQC

  # include any general notes about QAQC method here

  #checks the number of unmet hours in the model
  def check_mech_sys_efficiency(category,target_standard,min_pass,max_pass)

    if target_standard.include?('90.1')
      display_standard = "ASHRAE #{target_standard} Tables 6.8.1 A-K"
    else
      display_standard = target_standard
    end

    component_type_array = ["ChillerElectricEIR","CoilCoolingDXSingleSpeed","CoilCoolingDXTwoSpeed","CoilHeatingDXSingleSpeed","BoilerHotWater","FanConstantVolume","FanVariableVolume","PumpConstantSpeed","PumpVariableSpeed"]

    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "Mechanical System Efficiency")
    check_elems << OpenStudio::Attribute.new("category", category)
    check_elems << OpenStudio::Attribute.new("description", "Check against #{display_standard} for the following component types: #{component_type_array.join(", ")}.")

    begin

      # check ChillerElectricEIR objects (will also have curve check in different script)
      @model.getChillerElectricEIRs.each do |component|
        # eff values from model
        reference_COP = component.referenceCOP

        # get eff values from standards (if name doesn't have expected strings find object returns first object of multiple)
        standard_minimum_full_load_efficiency = component.standard_minimum_full_load_efficiency(target_standard, $os_standards)

        # check actual against target
        if standard_minimum_full_load_efficiency.nil?
          check_elems <<  OpenStudio::Attribute.new("flag", "Can't find target full load efficiency for #{component.name}.")
        elsif reference_COP < standard_minimum_full_load_efficiency*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "COP of #{reference_COP.round(2)} for #{component.name} is more than #{min_pass*100} % below the expected value of #{standard_minimum_full_load_efficiency.round(2)}.")
        elsif reference_COP > standard_minimum_full_load_efficiency*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "COP  of #{reference_COP.round(2)} for #{component.name} is more than #{max_pass*100} % above the expected value of #{standard_minimum_full_load_efficiency.round(2)}.")
        end
      end

      # check CoilCoolingDXSingleSpeed objects (will also have curve check in different script)
      @model.getCoilCoolingDXSingleSpeeds.each do |component|
        # eff values from model
        rated_COP = component.ratedCOP.get

        # get eff values from standards
        standard_minimum_cop = component.standard_minimum_cop(target_standard, $os_standards)

        # check actual against target
        if standard_minimum_cop.nil?
          check_elems <<  OpenStudio::Attribute.new("flag", "Can't find target COP for #{component.name}.")
        elsif rated_COP < standard_minimum_cop*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The COP of #{rated_COP.round(2)} for #{component.name} is more than #{min_pass*100} % below the expected value of #{standard_minimum_cop.round(2)} for #{display_standard}.")
        elsif rated_COP > standard_minimum_cop*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The COP of  #{rated_COP.round(2)} for #{component.name} is more than #{max_pass*100} % above the expected value of #{standard_minimum_cop.round(2)} for #{display_standard}.")
        end
      end

      # check CoilCoolingDXTwoSpeed objects (will also have curve check in different script)
      @model.getCoilCoolingDXTwoSpeeds.each do |component|
        # eff values from model
        rated_high_speed_COP = component.ratedHighSpeedCOP.get
        rated_low_speed_COP = component.ratedLowSpeedCOP.get

        # get eff values from standards
        standard_minimum_cop = component.standard_minimum_cop(target_standard, $os_standards)

        # check actual against target
        if standard_minimum_cop.nil?
          check_elems <<  OpenStudio::Attribute.new("flag", "Can't find target COP for #{component.name}.")
        elsif rated_high_speed_COP < standard_minimum_cop*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The high speed COP of #{rated_high_speed_COP.round(2)} for #{component.name} is more than #{min_pass*100} % below the expected value of #{standard_minimum_cop.round(2)} for #{display_standard}.")
        elsif rated_high_speed_COP > standard_minimum_cop*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The high speed COP of  #{rated_high_speed_COP.round(2)} for #{component.name} is more than #{max_pass*100} % above the expected value of #{standard_minimum_cop.round(2)} for #{display_standard}.")
        end
        if standard_minimum_cop.nil?
          check_elems <<  OpenStudio::Attribute.new("flag", "Can't find target COP for #{component.name}.")
        elsif rated_low_speed_COP < standard_minimum_cop*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The low speed COP of #{rated_low_speed_COP.round(2)} for #{component.name} is more than #{min_pass*100} % below the expected value of #{standard_minimum_cop.round(2)} for #{display_standard}.")
        elsif rated_low_speed_COP > standard_minimum_cop*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The low speed COP of  #{rated_low_speed_COP.round(2)} for #{component.name} is more than #{max_pass*100} % above the expected value of #{standard_minimum_cop.round(2)} for #{display_standard}.")
        end
      end

      # check CoilHeatingDXSingleSpeed objects
      # todo - need to test this once json file populated for this data
      @model.getCoilHeatingDXSingleSpeeds.each do |component|
        # eff values from model
        rated_COP = component.ratedCOP

        # get eff values from standards
        standard_minimum_cop = component.standard_minimum_cop(target_standard, $os_standards)

        # check actual against target
        if standard_minimum_cop.nil?
          check_elems <<  OpenStudio::Attribute.new("flag", "Can't find target COP for #{component.name}.")
        elsif rated_COP < standard_minimum_cop*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The COP of #{rated_COP.round(2)} for #{component.name} is more than #{min_pass*100} % below the expected value of #{standard_minimum_cop.round(2)} for #{display_standard}.")
        elsif rated_COP > standard_minimum_cop*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "The COP of  #{rated_COP.round(2)} for #{component.name} is more than #{max_pass*100} % above the expected value of #{standard_minimum_cop.round(2)}. for #{display_standard}")
        end
      end

      # check BoilerHotWater
      @model.getBoilerHotWaters.each do |component|
        # eff values from model
        nominal_thermal_efficiency  = component.nominalThermalEfficiency

        # get eff values from standards
        standard_minimum_thermal_efficiency = component.standard_minimum_thermal_efficiency(target_standard, $os_standards)

        # check actual against target
        if standard_minimum_thermal_efficiency.nil?
          check_elems <<  OpenStudio::Attribute.new("flag", "Can't find target thermal efficiency for #{component.name}.")
        elsif nominal_thermal_efficiency < standard_minimum_thermal_efficiency*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "Nominal thermal efficiency of #{nominal_thermal_efficiency.round(2)} for #{component.name} is more than #{min_pass*100} % below the expected value of #{standard_minimum_thermal_efficiency.round(2)} for #{display_standard}.")
        elsif nominal_thermal_efficiency > standard_minimum_thermal_efficiency*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "Nominal thermal efficiency of  #{nominal_thermal_efficiency.round(2)} for #{component.name} is more than #{max_pass*100} % above the expected value of #{standard_minimum_thermal_efficiency.round(2)} for #{display_standard}.")
        end
      end

      # check FanConstantVolume
      @model.getFanConstantVolumes.each do |component|

        # eff values from model
        motor_eff = component.motorEfficiency

        # get eff values from standards
        motor_bhp = component.brakeHorsepower
        standard_minimum_motor_efficiency_and_size = component.standard_minimum_motor_efficiency_and_size(target_standard, motor_bhp)[0]

        # check actual against target
        if motor_eff < standard_minimum_motor_efficiency_and_size*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "Motor efficiency of #{motor_eff.round(2)} for #{component.name} is more than #{min_pass*100} % below the expected value of #{standard_minimum_motor_efficiency_and_size.round(2)} for #{display_standard}.")
        elsif motor_eff > standard_minimum_motor_efficiency_and_size*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "Motor efficiency of #{motor_eff.round(2)} for #{component.name} is more than #{max_pass*100} % above the expected value of #{standard_minimum_motor_efficiency_and_size.round(2)} for #{display_standard}.")
        end
      end

      # check FanVariableVolume
      @model.getFanVariableVolumes.each do |component|

        # eff values from model
        motor_eff = component.motorEfficiency

        # get eff values from standards
        motor_bhp = component.brakeHorsepower
        standard_minimum_motor_efficiency_and_size = component.standard_minimum_motor_efficiency_and_size(target_standard, motor_bhp)[0]

        # check actual against target
        if motor_eff < standard_minimum_motor_efficiency_and_size*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "Motor efficiency of #{motor_eff.round(2)} for #{component.name} is more than #{min_pass*100} % below the expected value of #{standard_minimum_motor_efficiency_and_size.round(2)} for #{display_standard}.")
        elsif motor_eff > standard_minimum_motor_efficiency_and_size*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "Motor efficiency of #{motor_eff.round(2)} for #{component.name} is more than #{max_pass*100} % above the expected value of #{standard_minimum_motor_efficiency_and_size.round(2)} for #{display_standard}.")
        end
      end

      # check PumpConstantSpeed
      @model.getPumpConstantSpeeds.each do |component|

        # eff values from model
        motor_eff = component.motorEfficiency

        # get eff values from standards
        motor_bhp = component.brakeHorsepower
        next if motor_bhp == 0.0
        standard_minimum_motor_efficiency_and_size = component.standard_minimum_motor_efficiency_and_size(target_standard, motor_bhp)[0]

        # check actual against target
        if motor_eff < standard_minimum_motor_efficiency_and_size*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "Motor efficiency of #{motor_eff.round(2)} for #{component.name} is more than #{min_pass*100} % below the expected value of #{standard_minimum_motor_efficiency_and_size.round(2)} for #{display_standard}.")
        elsif motor_eff > standard_minimum_motor_efficiency_and_size*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "Motor efficiency of #{motor_eff.round(2)} for #{component.name} is more than #{max_pass*100} % above the expected value of #{standard_minimum_motor_efficiency_and_size.round(2)} for #{display_standard}.")
        end
      end

      # check PumpVariableSpeed
      @model.getPumpVariableSpeeds.each do |component|

        # eff values from model
        motor_eff = component.motorEfficiency

        # get eff values from standards
        motor_bhp = component.brakeHorsepower
        next if motor_bhp == 0.0
        standard_minimum_motor_efficiency_and_size = component.standard_minimum_motor_efficiency_and_size(target_standard, motor_bhp)[0]

        # check actual against target
        if motor_eff < standard_minimum_motor_efficiency_and_size*(1.0 - min_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "Motor efficiency of #{motor_eff.round(2)} for #{component.name} is more than #{min_pass*100} % below the expected value of #{standard_minimum_motor_efficiency_and_size.round(2)} for #{display_standard}.")
        elsif motor_eff > standard_minimum_motor_efficiency_and_size*(1.0 + max_pass)
          check_elems <<  OpenStudio::Attribute.new("flag", "Motor efficiency of #{motor_eff.round(2)} for #{component.name} is more than #{max_pass*100} % above the expected value of #{standard_minimum_motor_efficiency_and_size.round(2)} for #{display_standard}.")
        end
      end

      # todo - should I throw flag if any other component types are in the model

      # BasicOfficeTest_Mueller.osm test model current exercises the following component types
      # (CoilCoolingDXTwoSpeed,FanVariableVolume,PumpConstantSpeed)

      # BasicOfficeTest_Mueller_altHVAC_a checks these component types
      #(ChillerElectricEIR,CoilCoolingDXSingleSpeed,CoilHeatingDXSingleSpeed,BoilerHotWater,FanConstantVolume,PumpVariableSpeed)

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