#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"
require "#{File.dirname(__FILE__)}/resources/OsLib_HelperMethods"
require "#{File.dirname(__FILE__)}/resources/OsLib_HVAC"
require "#{File.dirname(__FILE__)}/resources/OsLib_Schedules"

#start the measure
class AedgK12Kitchen < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AedgK12Kitchen"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new  
    
    # make an argument for material and installation cost
    costTotalKitchenSystem = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("costTotalKitchenSystem",true)
    costTotalKitchenSystem.setDisplayName("Total Cost for Kitchen System ($).")
    costTotalKitchenSystem.setDefaultValue(0.0)
    args << costTotalKitchenSystem
    
    # make an argument number of students
    numberOfStudents = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("numberOfStudents",true)
    numberOfStudents.setDisplayName("Total Number of Students.")
    # calculate default value
    # get total number of students
    studentCount = 0
    model.getThermalZones.each do |zone|
      zoneMultiplier = zone.multiplier
      zone.spaces.each do |space|
        if space.spaceType.is_initialized
          if space.spaceType.get.name.is_initialized
            if space.spaceType.get.name.get.include? "Classroom"
              # add up number of people from each classroom space
              studentCount += space.numberOfPeople * zoneMultiplier
            end
          end  
        end
      end   
    end
    if studentCount.to_i > 0
      numberOfStudents.setDefaultValue(studentCount.to_i)
    end  
    # calculate default value
    # get total number of students
    studentCount = 0
    model.getThermalZones.each do |zone|
      zoneMultiplier = zone.multiplier
      zone.spaces.each do |space|
        if space.spaceType.is_initialized
          if space.spaceType.get.standardsSpaceType.is_initialized
            if space.spaceType.get.standardsSpaceType.get.include? "Classroom"
              # add up number of people from each classroom space
              studentCount += space.numberOfPeople * zoneMultiplier
            end
          end  
        end
      end   
    end
    if studentCount.to_i > 0
      numberOfStudents.setDefaultValue(studentCount.to_i)
    end  
    args << numberOfStudents
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    ### START INPUTS
    #assign the user inputs to variables
    costTotalKitchenSystem = runner.getDoubleArgumentValue("costTotalKitchenSystem",user_arguments)
    numberOfStudents = runner.getIntegerArgumentValue("numberOfStudents",user_arguments)
    # default building/kitchen space types
    standardBuildingTypeTest = ["PrimarySchool","SecondarySchool"]
    primarySpaceType = "Classroom"
    kitchenSpaceType = "Kitchen"
    # equipment inputs
    # electric equipment
    electricEquipmentPerStudent = {}
    electricEquipmentPerStudent["PrimarySchool"] = 39.51 # W/student
    electricEquipmentPerStudent["SecondarySchool"] = 23.25 # W/student
    # gas equipment
    gasEquipmentPerStudent = {}
    gasEquipmentPerStudent["PrimarySchool"] = 43.25 # W/student
    gasEquipmentPerStudent["SecondarySchool"] = 53.67 # W/student
    # refrigeration equipment
    
    # exhaust flow
    exhaustFlowPerStudent = {}
    exhaustFlowPerStudent["PrimarySchool"] = 0.001692 # m3/s*student
    exhaustFlowPerStudent["SecondarySchool"] = 0.002833 # m3/s*student
    ### END INPUTS
  
    ### START FIND REPRESENTATIVE THERMAL ZONE AND SPACE
    maxKitchenZoneArea = 0
    kitchenZones = []
    kitchenZone = false
    # find representative kitchen zone
    model.getThermalZones.each do |zone|
      isKitchenZone = false
      zoneArea = 0
      zone.spaces.each do |space|
        zoneArea += space.floorArea
        if space.spaceType.is_initialized
          if space.spaceType.get.standardsSpaceType.is_initialized
            if space.spaceType.get.standardsSpaceType.get.include? kitchenSpaceType
              # if zone contains a kitchen space, assume it is a kitchen zone
              isKitchenZone = true
            end
          end             
        end   
      end
      if isKitchenZone
        kitchenZones << zone
        if zoneArea > maxKitchenZoneArea
          # set zone as the representative kitchen zone if it is the largest kitchen zone
          kitchenZone = zone
          maxKitchenZoneArea = zoneArea
        end  
      end
    end
    # find largest space in representative kitchen zone
    kitchenSpace = false
    if kitchenZone
      maxKitchenSpaceArea = 0
      kitchenZone.spaces.each do |space|
        if space.spaceType.is_initialized
          if space.spaceType.get.standardsSpaceType.is_initialized
            if space.spaceType.get.standardsSpaceType.get.include? kitchenSpaceType
              if space.floorArea > maxKitchenSpaceArea
                maxKitchenSpaceArea = space.floorArea
                kitchenSpace = space
              end
            end
          end  
        end          
      end
    else  
      runner.registerInfo("Model does not have any kitchen spaces.  Measure will not modify the model.")
      return true
    end
    ### END FIND REPRESENTATIVE THERMAL ZONE AND SPACE

    ### START DETERMINE BUILDING TYPE
    standardBuildingType = false
    if model.building.is_initialized
      if model.building.get.standardsBuildingType.is_initialized
        standardBuildingType = model.building.get.standardsBuildingType.get
      end  
    end
    unless standardBuildingType
      # search primary space type for standardsBuildingType
      model.getSpaces.each do |space|
        next if standardBuildingType
        if space.spaceType.is_initialized
          if space.spaceType.get.standardsSpaceType.is_initialized
            if space.spaceType.get.standardsSpaceType.get.include? primarySpaceType
              if space.spaceType.get.standardsBuildingType.is_initialized
                standardBuildingType = space.spaceType.get.standardsBuildingType.get
              end  
            end
          end
        end
      end
    end
    building_type = false
    standardBuildingTypeTest.each do |building_type_test|
      if standardBuildingType == building_type_test
        building_type = building_type_test
      end  
    end
    unless building_type
      # building type not specified or not appropriate for this measure
      runner.registerInfo("Building type is not specified or not supported.  Measure will proceed assuming type is #{standardBuildingTypeTest[0]}.")
      building_type = standardBuildingTypeTest[0]
    end
    ### END DETERMINE BUILDING TYPE
    
    ### START DELETE EXISTING EQUIPMENT
    # delete equipment from space types
    model.getSpaceTypes.each do |spaceType|
      if spaceType.standardsSpaceType.is_initialized
        if spaceType.standardsSpaceType.get.include? kitchenSpaceType
          # space type is kitchen; delete equipment
          spaceType.electricEquipment.each do |electric_equipment|
            electric_equipment.remove
          end
          spaceType.gasEquipment.each do |gas_equipment|
            gas_equipment.remove
          end
        end  
      end
    end
    # delete additional equipment defined at the space level
    model.getSpaces.each do |space|
      if space.spaceType.is_initialized
        if space.spaceType.get.standardsSpaceType.is_initialized
          if space.spaceType.get.standardsSpaceType.get.include? kitchenSpaceType
            # space type is kitchen; delete equipment
            space.spaceType.get.electricEquipment.each do |electric_equipment|
              electric_equipment.remove
            end
            space.spaceType.get.gasEquipment.each do |gas_equipment|
              gas_equipment.remove
            end
          end  
        end
      end  
    end
    # Kitchen Exhaust Fans (delete all in zones with kitchen spaces)
    model.getFanZoneExhausts.each do |exhaust_fan| 
      if exhaust_fan.thermalZone.is_initialized
        if kitchenZones.include? exhaust_fan.thermalZone.get 
          # exhaust fan is a kitchen exhaust fan
          exhaust_fan.remove
        end  
      end
    end
    # Refrigeration Systems
    # assume all refrigeration systems are tied to the kitchen
    model.getRefrigerationSystems.each do |refrigeration_system|
      refrigeration_system.cases.each do |refrigeration_case|
        refrigeration_case.remove
      end
      refrigeration_system.walkins.each do |walkin_case|
        walkin_case.remove
      end
      refrigeration_system.remove
    end
    ### END DELETE EXISTING EQUIPMENT
  
    ### START APPLY COOKING EQUIPMENT RECOMMENDATIONS  
    # Electric Equipment (add to representative kitchen zone)
    electricEquipmentDefinition = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    electricEquipmentDefinition.setDesignLevel(electricEquipmentPerStudent[building_type]*numberOfStudents)
    electricEquipment = OpenStudio::Model::ElectricEquipment.new(electricEquipmentDefinition)
    electricEquipment.setSpace(kitchenSpace)
    # create kitchen electric equipment schedule
    if building_type == "PrimarySchool"
      ruleset_name = "AEDG K-12 Primary Kitchen Electric Equipment Schedule"
      winter_design_day = [[24,0]]
      summer_design_day = [[5,0.29],[6,0.35],[7,0.45],[8,0.85],[9,0.78],[10,0.55],[11,0.7],[12,0.89],[13,1.00],[14,0.45],[15,0.36],[24,0.29]]
      default_day = ["Weekday",[5,0.29],[6,0.35],[7,0.45],[8,0.85],[9,0.78],[10,0.55],[11,0.7],[12,0.89],[13,1.00],[14,0.45],[15,0.36],[24,0.29]]
      rules = []
      rules << ["Weekend","1/1-12/31","Sat/Sun",[24,0.29]]
      rules << ["Summer Weekday","7/1-8/31","Mon/Tue/Wed/Thu/Fri",[24,0.29]]
      options_kitchen_electric = {"name" => ruleset_name,
                      "winter_design_day" => winter_design_day,
                      "summer_design_day" => summer_design_day,
                      "default_day" => default_day,
                      "rules" => rules}
      kitchenElectricSchedule = OsLib_Schedules.createComplexSchedule(model, options_kitchen_electric)
    elsif building_type == "SecondarySchool"
      ruleset_name = "AEDG K-12 Secondary Kitchen Electric Equipment Schedule"
      winter_design_day = [[24,0]]
      summer_design_day = [[6,0.38],[7,0.86],[8,1.00],[11,0.77],[13,1.00],[14,0.60],[15,0.46],[24,0.38]]
      default_day = ["Weekday",[6,0.38],[7,0.86],[8,1.00],[11,0.77],[13,1.00],[14,0.60],[15,0.46],[24,0.38]]
      rules = []
      rules << ["Weekend","1/1-12/31","Sat/Sun",[24,0.38]]
      rules << ["Summer Weekday","7/1-8/31","Mon/Tue/Wed/Thu/Fri",[24,0.38]]
      options_kitchen_electric = {"name" => ruleset_name,
                      "winter_design_day" => winter_design_day,
                      "summer_design_day" => summer_design_day,
                      "default_day" => default_day,
                      "rules" => rules}
      kitchenElectricSchedule = OsLib_Schedules.createComplexSchedule(model, options_kitchen_electric)
    end
    electricEquipment.setSchedule(kitchenElectricSchedule)
    # Gas Equipment
    gasEquipmentDefinition = OpenStudio::Model::GasEquipmentDefinition.new(model)
    gasEquipmentDefinition.setDesignLevel(gasEquipmentPerStudent[building_type]*numberOfStudents)
    gasEquipment = OpenStudio::Model::GasEquipment.new(gasEquipmentDefinition)
    gasEquipment.setSpace(kitchenSpace)
    # create kitchen gas equipment schedule
    if building_type == "PrimarySchool"
      ruleset_name = "AEDG K-12 Primary Kitchen Gas Equipment Schedule"
      winter_design_day = [[24,0]]
      summer_design_day = [[6,0.04],[8,1.00],[9,0.32],[10,0.06],[13,1.00],[24,0.04]]
      default_day = ["Weekday",[6,0.04],[8,1.00],[9,0.32],[10,0.06],[13,1.00],[24,0.04]]
      rules = []
      rules << ["Weekend","1/1-12/31","Sat/Sun",[24,0.04]]
      rules << ["Summer Weekday","7/1-8/31","Mon/Tue/Wed/Thu/Fri",[24,0.04]]
      options_kitchen_gas = {"name" => ruleset_name,
                      "winter_design_day" => winter_design_day,
                      "summer_design_day" => summer_design_day,
                      "default_day" => default_day,
                      "rules" => rules}
      kitchenGasSchedule = OsLib_Schedules.createComplexSchedule(model, options_kitchen_gas)
    elsif building_type == "SecondarySchool"
      ruleset_name = "AEDG K-12 Secondary Kitchen Gas Equipment Schedule"
      winter_design_day = [[24,0]]
      summer_design_day = [[3,0.02],[6,0.22],[7,0.99],[8,0.79],[10,0.40],[11,0.86],[13,1.00],[24,0.02]]
      default_day = ["Weekday",[3,0.02],[6,0.22],[7,0.99],[8,0.79],[10,0.40],[11,0.86],[13,1.00],[24,0.02]]
      rules = []
      rules << ["Weekend","1/1-12/31","Sat/Sun",[24,0.02]]
      rules << ["Summer Weekday","7/1-8/31","Mon/Tue/Wed/Thu/Fri",[24,0.02]]
      options_kitchen_gas = {"name" => ruleset_name,
                      "winter_design_day" => winter_design_day,
                      "summer_design_day" => summer_design_day,
                      "default_day" => default_day,
                      "rules" => rules}
      kitchenGasSchedule = OsLib_Schedules.createComplexSchedule(model, options_kitchen_gas)
    end      
    gasEquipment.setSchedule(kitchenGasSchedule)
    # Exhaust Equipment
    # create new exhaust fan
    exhaustFan = OpenStudio::Model::FanZoneExhaust.new(model)
    # create exhaust fan schedule
    airloops = model.getAirLoopHVACs
    # find airloop with most primary spaces
    max_primary_spaces = 0
    representative_airloop = false
    kitchen_exhaust_schedule = false
    airloops.each do |air_loop|
      primary_spaces = 0
      air_loop.thermalZones.each do |thermal_zone|
        thermal_zone.spaces.each do |space|
          if space.spaceType.is_initialized
            if space.spaceType.get.name.is_initialized
              if space.spaceType.get.name.get.include? primarySpaceType
                primary_spaces += 1
              end
            end  
          end  
        end
      end
      if primary_spaces > max_primary_spaces
        max_primary_spaces = primary_spaces
        representative_airloop = air_loop
      end      
    end
    if representative_airloop
      if representative_airloop.airLoopHVACOutdoorAirSystem.is_initialized
        building_ventilation_schedule = representative_airloop.airLoopHVACOutdoorAirSystem.get.getControllerOutdoorAir.maximumFractionofOutdoorAirSchedule
        if building_ventilation_schedule.is_initialized
          kitchen_exhaust_schedule = building_ventilation_schedule.get
        end
      end  
    end
    unless kitchen_exhaust_schedule
      ruleset_name = "AEDG K-12 Kitchen Exhaust Schedule"
      winter_design_day = [[24,1]]
      summer_design_day = [[24,1]]
      default_day = ["Weekday",[6,0],[18,1],[24,0]]
      rules = []
      rules << ["Weekend","1/1-12/31","Sat/Sun",[24,0]]
      rules << ["Summer Weekday","7/1-8/31","Mon/Tue/Wed/Thu/Fri",[8,0],[13,1],[24,0]]
      options_kitchen_exhaust = {"name" => ruleset_name,
                             "winter_design_day" => winter_design_day,
                             "summer_design_day" => summer_design_day,
                             "default_day" => default_day,
                             "rules" => rules}
      kitchen_exhaust_schedule = OsLib_Schedules.createComplexSchedule(model, options_kitchen_exhaust)
    end
    exhaustFan.setAvailabilitySchedule(kitchen_exhaust_schedule)
    exhaustFan.setFanEfficiency(0.45)
    exhaustFan.setPressureRise(125) # Pa
    exhaustFan.setMaximumFlowRate(exhaustFlowPerStudent[building_type]*numberOfStudents)
    exhaustFan.addToThermalZone(kitchenZone)
    # Refrigeration Equipment 
    # create new medium temperature refrigeration system
    refrigerationSystemMediumTemp = OpenStudio::Model::RefrigerationSystem.new(model)
    refrigerationSystemMediumTemp.setSumUASuctionPiping(150) # W/K, conservatively estimated from model of real refrigeration system
    refrigerationSystemMediumTemp.setSuctionPipingZone(kitchenZone)
    # create compressors
    compressors = []
    compressors << compressor1 = OpenStudio::Model::RefrigerationCompressor.new(model)
    compressors << compressor2 = OpenStudio::Model::RefrigerationCompressor.new(model)
    compressors << compressor3 = OpenStudio::Model::RefrigerationCompressor.new(model)
    # assign curves to compressors and attach to refrigeration system
    compressors.each do |compressor|
      # create compressorMedTempPwrCurve
      compressorMedTempPwrCurve = OpenStudio::Model::CurveBicubic.new(model)
      compressorMedTempPwrCurve.setCoefficient1Constant(3913)
      compressorMedTempPwrCurve.setCoefficient2x(-107.7)
      compressorMedTempPwrCurve.setCoefficient3xPOW2(-3.694)
      compressorMedTempPwrCurve.setCoefficient4y(166.9)
      compressorMedTempPwrCurve.setCoefficient5yPOW2(0.2619)
      compressorMedTempPwrCurve.setCoefficient6xTIMESY(4.543)
      compressorMedTempPwrCurve.setCoefficient7xPOW3(-0.02113)
      compressorMedTempPwrCurve.setCoefficient8yPOW3(-0.006456)
      compressorMedTempPwrCurve.setCoefficient9xPOW2TIMESY(0.03008)
      compressorMedTempPwrCurve.setCoefficient10xTIMESYPOW2(0.004171)
      compressorMedTempPwrCurve.setMinimumValueofx(-17.8)
      compressorMedTempPwrCurve.setMaximumValueofx(4.4)
      compressorMedTempPwrCurve.setMinimumValueofy(10.0)
      compressorMedTempPwrCurve.setMaximumValueofy(48.9)
      # create compressorMedTempCapCurve
      compressorMedTempCapCurve = OpenStudio::Model::CurveBicubic.new(model)
      compressorMedTempCapCurve.setCoefficient1Constant(93210)
      compressorMedTempCapCurve.setCoefficient2x(3325)
      compressorMedTempCapCurve.setCoefficient3xPOW2(34.15)
      compressorMedTempCapCurve.setCoefficient4y(-683.6)
      compressorMedTempCapCurve.setCoefficient5yPOW2(-9.723)
      compressorMedTempCapCurve.setCoefficient6xTIMESY(-30.48)
      compressorMedTempCapCurve.setCoefficient7xPOW3(-0.03525)
      compressorMedTempCapCurve.setCoefficient8yPOW3(0.07694)
      compressorMedTempCapCurve.setCoefficient9xPOW2TIMESY(-0.3221)
      compressorMedTempCapCurve.setCoefficient10xTIMESYPOW2(-0.05519)
      compressorMedTempCapCurve.setMinimumValueofx(-17.8)
      compressorMedTempCapCurve.setMaximumValueofx(4.4)
      compressorMedTempCapCurve.setMinimumValueofy(10.0)
      compressorMedTempCapCurve.setMaximumValueofy(48.9)
      # assign curves
      compressor.setRefrigerationCompressorPowerCurve(compressorMedTempPwrCurve)
      compressor.setRefrigerationCompressorCapacityCurve(compressorMedTempCapCurve)
      refrigerationSystemMediumTemp.addCompressor(compressor)
    end
    # create condenser and attach to refrigeration system
    condenser = OpenStudio::Model::RefrigerationCondenserAirCooled.new(model)
    condenser.setCondenserFanSpeedControlType("Fixed") # estimated from model of real refrigeration system
    condenser.setMinimumFanAirFlowRatio(0.2) # estimated from model of real refrigeration system
    condenserHeatRejectionCurve = OpenStudio::Model::CurveLinear.new(model)
    condenserHeatRejectionCurve.setCoefficient1Constant(0) # estimated from model of real refrigeration system
    condenserHeatRejectionCurve.setCoefficient2x(35000) # estimated from model of real refrigeration system
    condenserHeatRejectionCurve.setMinimumValueofx(8.3) # estimated from model of real refrigeration system
    condenserHeatRejectionCurve.setMaximumValueofx(33.3) # estimated from model of real refrigeration system
    condenser.setRatedEffectiveTotalHeatRejectionRateCurve(condenserHeatRejectionCurve)
    refrigerationSystemMediumTemp.setRefrigerationCondenser(condenser)
    # create medium temperature case
    scheduleDefrost = OsLib_Schedules.createComplexSchedule(model, {"name" => "Always Off",
                                                                    "default_day" => ["All Days",[24,0]]})
    caseRefrigeration = OpenStudio::Model::RefrigerationCase.new(model,scheduleDefrost)
    caseRefrigeration.setThermalZone(kitchenZone)
    caseRefrigeration.setRatedAmbientTemperature(23.88)
    caseRefrigeration.setRatedAmbientRelativeHumidity(55.0)
    caseRefrigeration.setRatedTotalCoolingCapacityperUnitLength(734)
    caseRefrigeration.setRatedLatentHeatRatio(0.08)
    caseRefrigeration.setRatedRuntimeFraction(0.85)
    if building_type == "PrimarySchool"
      caseRefrigeration.setCaseLength(3.66)
    elsif building_type == "SecondarySchool"  
      caseRefrigeration.setCaseLength(7.32)
    end
    caseRefrigeration.setCaseOperatingTemperature(2)
    # latent case credit curve
    latentCaseCreditCurve = OpenStudio::Model::CurveCubic.new(model)
    latentCaseCreditCurve.setCoefficient1Constant(0.026526281)
    latentCaseCreditCurve.setCoefficient2x(0.001078032)
    latentCaseCreditCurve.setCoefficient3xPOW2(0.0000602558)
    latentCaseCreditCurve.setCoefficient4xPOW3(0.00000123732)
    latentCaseCreditCurve.setMinimumValueofx(-35.0)
    latentCaseCreditCurve.setMaximumValueofx(20.0)
    caseRefrigeration.setLatentCaseCreditCurve(latentCaseCreditCurve)
    caseRefrigeration.setStandardCaseFanPowerperUnitLength(55)
    caseRefrigeration.setOperatingCaseFanPowerperUnitLength(40)
    caseRefrigeration.setStandardCaseLightingPowerperUnitLength(33)
    caseRefrigeration.setInstalledCaseLightingPowerperUnitLength(75)
    # get relevant lighting schedule
    maxLightingPower = 0
    kitchenSpaceFloorArea = kitchenSpace.floorArea
    kitchenSpaceNumPeople = 0
    kitchenSpace.people.each do |people|
      if people.numberOfPeople.is_initialized
        kitchenSpaceNumPeople += people.numberOfPeople.get
      end
    end
    representativeLight = false
    caseLightingSchedule = false
    kitchenSpace.spaceType.get.lights.each do |light|
      lightPower = light.getLightingPower(kitchenSpaceFloorArea,kitchenSpaceNumPeople)
      if lightPower > maxLightingPower
        maxLightingPower = lightPower
        representativeLight = light
      end
    end
    if representativeLight
      if representativeLight.schedule.is_initialized
        caseLightingSchedule = representativeLight.schedule.get
      end
    end
    unless caseLightingSchedule
      runner.registerInfo("No lighting schedule is specified for space named #{kitchenSpace.name} in thermal zone named #{kitchenZone.name}.  Measure will assign #{caseRefrigeration.name} refrigerated case lighting schedule as always on.")
      caseLightingSchedule = model.alwaysOnDiscreteSchedule()
    end
    caseRefrigeration.setCaseLightingSchedule(caseLightingSchedule)
    caseRefrigeration.setFractionofLightingEnergytoCase(1)
    caseRefrigeration.setCaseAntiSweatHeaterPowerperUnitLength(0)
    caseRefrigeration.setMinimumAntiSweatHeaterPowerperUnitLength(0)
    caseRefrigeration.setAntiSweatHeaterControlType("None")
    caseRefrigeration.setHumidityatZeroAntiSweatHeaterEnergy(0)
    caseRefrigeration.setCaseHeight(0)
    caseRefrigeration.setFractionofAntiSweatHeaterEnergytoCase(0.2)
    caseRefrigeration.setCaseDefrostPowerperUnitLength(0)
    caseRefrigeration.setCaseDefrostType("None")
    caseRefrigeration.setDefrostEnergyCorrectionCurveType("None")
    caseRefrigeration.setUnderCaseHVACReturnAirFraction(0.05)
    scheduleRestocking = OsLib_Schedules.createComplexSchedule(model, {"name" => "AEDG Medium Temperature Case Restocking Schedule",
                                                                       "default_day" => ["All Days",[6,0],[7,50],[9,70],[10,80],[11,70],[13,50],[14,80],[15,90],[16,80],[24,0]]})
    caseRefrigeration.setRefrigeratedCaseRestockingSchedule(scheduleRestocking)
    caseRefrigeration.setDesignEvaporatorTemperatureorBrineInletTemperature(-7.22) # estimated from model of real refrigeration system
    # assign case to system
    refrigerationSystemMediumTemp.addCase(caseRefrigeration)
    # create new low temperature refrigeration system
    refrigerationSystemLowTemp = OpenStudio::Model::RefrigerationSystem.new(model)
    refrigerationSystemLowTemp.setSumUASuctionPiping(150) # W/K, conservatively estimated from model of real refrigeration system
    refrigerationSystemLowTemp.setSuctionPipingZone(kitchenZone)
    # create compressors
    compressors = []
    compressors << compressor1 = OpenStudio::Model::RefrigerationCompressor.new(model)
    compressors << compressor2 = OpenStudio::Model::RefrigerationCompressor.new(model)
    compressors << compressor3 = OpenStudio::Model::RefrigerationCompressor.new(model)
    # assign curves to compressors and attach to refrigeration system
    compressors.each do |compressor|
      # create compressorLowTempPwrCurve
      compressorLowTempPwrCurve = OpenStudio::Model::CurveBicubic.new(model)
      compressorLowTempPwrCurve.setCoefficient1Constant(25230)
      compressorLowTempPwrCurve.setCoefficient2x(982.8)
      compressorLowTempPwrCurve.setCoefficient3xPOW2(18.47)
      compressorLowTempPwrCurve.setCoefficient4y(-624.9)
      compressorLowTempPwrCurve.setCoefficient5yPOW2(14.10)
      compressorLowTempPwrCurve.setCoefficient6xTIMESY(-21.91)
      compressorLowTempPwrCurve.setCoefficient7xPOW3(0.1344)
      compressorLowTempPwrCurve.setCoefficient8yPOW3(-0.08536)
      compressorLowTempPwrCurve.setCoefficient9xPOW2TIMESY(-0.2288)
      compressorLowTempPwrCurve.setCoefficient10xTIMESYPOW2(0.1977)
      compressorLowTempPwrCurve.setMinimumValueofx(-40.0)
      compressorLowTempPwrCurve.setMaximumValueofx(-17.8)
      compressorLowTempPwrCurve.setMinimumValueofy(10.0)
      compressorLowTempPwrCurve.setMaximumValueofy(48.9)
      # create compressorLowTempCapCurve
      compressorLowTempCapCurve = OpenStudio::Model::CurveBicubic.new(model)
      compressorLowTempCapCurve.setCoefficient1Constant(170800)
      compressorLowTempCapCurve.setCoefficient2x(5801)
      compressorLowTempCapCurve.setCoefficient3xPOW2(65.95)
      compressorLowTempCapCurve.setCoefficient4y(-3117)
      compressorLowTempCapCurve.setCoefficient5yPOW2(22.54)
      compressorLowTempCapCurve.setCoefficient6xTIMESY(-96.33)
      compressorLowTempCapCurve.setCoefficient7xPOW3(0.3026)
      compressorLowTempCapCurve.setCoefficient8yPOW3(-0.05385)
      compressorLowTempCapCurve.setCoefficient9xPOW2TIMESY(-0.6427)
      compressorLowTempCapCurve.setCoefficient10xTIMESYPOW2(0.5012)
      compressorLowTempCapCurve.setMinimumValueofx(-40.0)
      compressorLowTempCapCurve.setMaximumValueofx(-17.8)
      compressorLowTempCapCurve.setMinimumValueofy(10.0)
      compressorLowTempCapCurve.setMaximumValueofy(48.9)
      # set curves
      compressor.setRefrigerationCompressorPowerCurve(compressorLowTempPwrCurve)
      compressor.setRefrigerationCompressorCapacityCurve(compressorLowTempCapCurve)
      refrigerationSystemLowTemp.addCompressor(compressor)
    end
    # create condenser and attach to refrigeration system
    condenser = OpenStudio::Model::RefrigerationCondenserAirCooled.new(model)
    condenser.setCondenserFanSpeedControlType("Fixed") # estimated from model of real refrigeration system
    condenser.setMinimumFanAirFlowRatio(0.2) # estimated from model of real refrigeration system
    condenserHeatRejectionCurve = OpenStudio::Model::CurveLinear.new(model)
    condenserHeatRejectionCurve.setCoefficient1Constant(0) # estimated from model of real refrigeration system
    condenserHeatRejectionCurve.setCoefficient2x(25000) # estimated from model of real refrigeration system
    condenserHeatRejectionCurve.setMinimumValueofx(5.6) # estimated from model of real refrigeration system
    condenserHeatRejectionCurve.setMaximumValueofx(33.3) # estimated from model of real refrigeration system
    condenser.setRatedEffectiveTotalHeatRejectionRateCurve(condenserHeatRejectionCurve)
    refrigerationSystemLowTemp.setRefrigerationCondenser(condenser)
    # create low temperature case
    scheduleDefrost = OsLib_Schedules.createComplexSchedule(model, {"name" => "AEDG Low Temperature Case Defrost Schedule",
                                                                    "default_day" => ["All Days",[11,0],[11.33,1],[23,0],[23.33,1],[24,0]]})
    caseRefrigeration = OpenStudio::Model::RefrigerationCase.new(model,scheduleDefrost)
    caseRefrigeration.setThermalZone(kitchenZone)
    caseRefrigeration.setRatedAmbientTemperature(23.88)
    caseRefrigeration.setRatedAmbientRelativeHumidity(55.0)
    caseRefrigeration.setRatedTotalCoolingCapacityperUnitLength(734)
    caseRefrigeration.setRatedLatentHeatRatio(0.10)
    caseRefrigeration.setRatedRuntimeFraction(0.40)
    if building_type == "PrimarySchool"
      caseRefrigeration.setCaseLength(3.66)
    elsif building_type == "SecondarySchool"  
      caseRefrigeration.setCaseLength(7.32)
    end
    caseRefrigeration.setCaseOperatingTemperature(-23)
    # latent case credit curve
    latentCaseCreditCurve = OpenStudio::Model::CurveCubic.new(model)
    latentCaseCreditCurve.setCoefficient1Constant(0.0236)
    latentCaseCreditCurve.setCoefficient2x(0.0006)
    latentCaseCreditCurve.setCoefficient3xPOW2(0.0)
    latentCaseCreditCurve.setCoefficient4xPOW3(0.0)
    latentCaseCreditCurve.setMinimumValueofx(-35.0)
    latentCaseCreditCurve.setMaximumValueofx(20.0)
    caseRefrigeration.setLatentCaseCreditCurve(latentCaseCreditCurve)
    caseRefrigeration.setStandardCaseFanPowerperUnitLength(68.3)
    caseRefrigeration.setOperatingCaseFanPowerperUnitLength(172.2)
    caseRefrigeration.setStandardCaseLightingPowerperUnitLength(33)
    caseRefrigeration.setInstalledCaseLightingPowerperUnitLength(28.1)
    # use same lighting schedule as for medium temperature case
    caseRefrigeration.setCaseLightingSchedule(caseLightingSchedule)
    caseRefrigeration.setFractionofLightingEnergytoCase(1)
    caseRefrigeration.setCaseAntiSweatHeaterPowerperUnitLength(0)
    caseRefrigeration.setMinimumAntiSweatHeaterPowerperUnitLength(0)
    caseRefrigeration.setAntiSweatHeaterControlType("None")
    caseRefrigeration.setHumidityatZeroAntiSweatHeaterEnergy(0)
    caseRefrigeration.setCaseHeight(0)
    caseRefrigeration.setFractionofAntiSweatHeaterEnergytoCase(0)
    if building_type == "PrimarySchool"
      caseRefrigeration.setCaseDefrostPowerperUnitLength(547)
    elsif building_type == "SecondarySchool"  
      caseRefrigeration.setCaseDefrostPowerperUnitLength(410)
    end
    caseRefrigeration.setCaseDefrostType("Electric")
    scheduleDripDown = OsLib_Schedules.createComplexSchedule(model, {"name" => "AEDG Low Temperature Case Drip Down Schedule",
                                                                    "default_day" => ["All Days",[11,0],[11.5,1],[23,0],[23.5,1],[24,0]]})
    caseRefrigeration.setCaseDefrostDripDownSchedule(scheduleDripDown)
    caseRefrigeration.setDefrostEnergyCorrectionCurveType("None")
    caseRefrigeration.setUnderCaseHVACReturnAirFraction(0.0)
    ruleset_name = "AEDG Low Temperature Case Restocking Schedule"
    default_day = ["All Other Days",[4,0],[5,125],[6,117],[7,90],[19,0],[20,125],[21,117],[22,90],[24,0]]
    rules = []
    rules << ["Tuesdays and Thursdays","1/1-12/31","Tue/Thu",[4,0],[5,725],[6,417],[7,290],[24,0]]
    options_restock = {"name" => ruleset_name,
                           "default_day" => default_day,
                           "rules" => rules}
    scheduleRestocking = OsLib_Schedules.createComplexSchedule(model, options_restock)  
    caseRefrigeration.setRefrigeratedCaseRestockingSchedule(scheduleRestocking)
    scheduleCaseCreditFraction = OsLib_Schedules.createComplexSchedule(model, {"name" => "AEDG Low Temperature Case Credit Fraction Schedule",
                                                                               "default_day" => ["All Days",[7,0.2],[21,0.4],[24,0.2]]})
    caseRefrigeration.setCaseCreditFractionSchedule(scheduleCaseCreditFraction)
    caseRefrigeration.setDesignEvaporatorTemperatureorBrineInletTemperature(-25.56) # estimated from model of real refrigeration system
    # assign case to system
    refrigerationSystemLowTemp.addCase(caseRefrigeration)
    
    # todo - add in lifecycle costs
    expected_life = 25
    years_until_costs_start = 0
    costKitchen = costTotalKitchenSystem
    lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Refrigeration System", model.getBuilding, costKitchen, "CostPerEach", "Construction", expected_life, years_until_costs_start).get

    # add AEDG tips
    aedgTips = ["KE01","KE02","KE03","KE04","KE05","KE06","KE07"]

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips("K12",aedgTips.uniq.sort,runner)
    if not aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
AedgK12Kitchen.new.registerWithApplication