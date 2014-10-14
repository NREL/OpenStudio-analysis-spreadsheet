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
class AedgK12Swh < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AedgK12Swh"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new  
    
    # make an argument for material and installation cost
    costTotalSwhSystem = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("costTotalSwhSystem",true)
    costTotalSwhSystem.setDisplayName("Total Cost for Kitchen System ($).")
    costTotalSwhSystem.setDefaultValue(0.0)
    args << costTotalSwhSystem
    
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
    costTotalSwhSystem = runner.getDoubleArgumentValue("costTotalSwhSystem",user_arguments)
    numberOfStudents = runner.getIntegerArgumentValue("numberOfStudents",user_arguments)
    # default building/kitchen space types
    standardBuildingTypeTest = ["PrimarySchool","SecondarySchool"]
    primarySpaceType = "Classroom"
    swhSpaceTypes = {}
    swhSpaceTypes["PrimarySchool"] = ["Kitchen","Restroom"]
    swhSpaceTypes["SecondarySchool"] = ["Kitchen","Restroom","Gym"]
    # water use equipment inputs
    waterUsePerStudent = {}
    # kitchen
    kitchenWaterUsePerStudent = {}
    kitchenWaterUsePerStudent["PrimarySchool"] = 0.00000016176923077 # m3/s*student
    kitchenWaterUsePerStudent["SecondarySchool"] = 0.00000011654166667 # m3/s*student
    waterUsePerStudent["Kitchen"] = kitchenWaterUsePerStudent
    # restroom
    restroomWaterUsePerStudent = {}
    restroomWaterUsePerStudent["PrimarySchool"] = 0.00000009145299145 # m3/s*student
    restroomWaterUsePerStudent["SecondarySchool"] = 0.00000009143518519 # m3/s*student
    waterUsePerStudent["Restroom"] = restroomWaterUsePerStudent
    # gym
    gymWaterUsePerStudent = {}
    gymWaterUsePerStudent["PrimarySchool"] = 0 # m3/s*student
    gymWaterUsePerStudent["SecondarySchool"] = 0.00000016602546296 # m3/s*student
    waterUsePerStudent["Gym"] = gymWaterUsePerStudent
    ### END INPUTS
  
    ### START DETERMINE BUILDING TYPE
    standardBuildingType = false
    if model.building.is_initialized
      if model.building.get.standardsBuildingType.is_initialized
        standardBuildingType = model.building.standardsBuildingType.get
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
  
    ### START FIND REPRESENTATIVE THERMAL ZONES AND SPACES
    # for kitchen and gym, water use will be applied to representative spaces
    # for restroom, water use will be applied to each restroom
    applyMeasure = false
    numberOfRestrooms = 0
    restroomSpaces = []
    representativeZone = {}
    representativeSpace = {}
    swhSpaceTypes[building_type].each do |applicableSpaceType|
      if applicableSpaceType == "Restroom"
        # get all restroom spaces
        model.getSpaces.each do |space|
          if space.spaceType.is_initialized
            if space.spaceType.get.standardsSpaceType.is_initialized
              if space.spaceType.get.standardsSpaceType.get.include? applicableSpaceType
                restroomSpaces << space
                numberOfRestrooms += 1
              end
            end
          end  
        end
        unless numberOfRestrooms > 0
          runner.registerInfo("Model does not have any #{applicableSpaceType} spaces.  Measure will not apply #{applicableSpaceType} recommendations.")
        else
          applyMeasure = true
        end
      else
        # applicable space type is kitchen or gym
        maxRepresentativeZoneArea = 0
        spaceTypeZones = []
        representativeZone[applicableSpaceType] = false
        representativeSpace[applicableSpaceType] = false
        # find representative zone
        model.getThermalZones.each do |zone|
          isRepresentativeZone = false
          zoneArea = 0
          zone.spaces.each do |space|
            zoneArea += space.floorArea
            if space.spaceType.is_initialized
              if space.spaceType.get.standardsSpaceType.is_initialized
                if space.spaceType.get.standardsSpaceType.get.include? applicableSpaceType
                  # if zone contains an applicable space, assume it is an applicable zone
                  isRepresentativeZone = true
                end
              end             
            end   
          end
          if isRepresentativeZone
            spaceTypeZones << zone
            if zoneArea > maxRepresentativeZoneArea
              # set zone as the representative zone if it is the largest applicable zone
              representativeZone[applicableSpaceType] = zone
              maxRepresentativeZoneArea = zoneArea
            end  
          end
        end
        # find largest space in representative zone
        if representativeZone[applicableSpaceType]
          applyMeasure = true
          maxRepresentativeSpaceArea = 0
          representativeZone[applicableSpaceType].spaces.each do |space|
            if space.spaceType.is_initialized
              if space.spaceType.get.standardsSpaceType.is_initialized
                if space.spaceType.get.standardsSpaceType.get.include? applicableSpaceType
                  if space.floorArea > maxRepresentativeSpaceArea
                    maxRepresentativeSpaceArea = space.floorArea
                    representativeSpace[applicableSpaceType] = space
                  end
                end
              end  
            end          
          end
        else  
          runner.registerInfo("Model does not have any #{applicableSpaceType} spaces.  Measure will not apply #{applicableSpaceType} recommendations.")
        end
      end  
    end
    # exit measure if nothing to apply
    unless applyMeasure
      runner.registerInfo("Model does not have any spaces expected to have SWH use.  Measure will not modify the model.")
      return true
    end    
    ### END FIND REPRESENTATIVE THERMAL ZONE AND SPACE

    ### START DELETE EXISTING EQUIPMENT
    # remove plant loops for SWH
    model.getPlantLoops.each do |plantLoop|
      usedForSHW = false
      plantLoop.demandComponents.each do |comp|
        if comp.to_WaterUseConnections.is_initialized
          usedForSHW = true
        end
      end
      if usedForSHW
        plantLoop.remove
        runner.registerWarning("#{plantLoop.name} for service water heating will be deleted so that AEDG recommendations can be applied.")
      end
    end #next plantLoop
    ### END DELETE EXISTING EQUIPMENT
  
    ### START APPLY SWH RECOMMENDATIONS
    # create swh water plant
    swhPlant = OpenStudio::Model::PlantLoop.new(model)
    swhPlant.setName("AEDG SWH Loop")
    swhPlant.setMaximumLoopTemperature(60)
    swhPlant.setMinimumLoopTemperature(10)
    loopSizing = swhPlant.sizingPlant
    loopSizing.setLoopType("Heating")
    loopSizing.setDesignLoopExitTemperature(60) #ML follows convention of sizing temp being larger than supply temp
    loopSizing.setLoopDesignTemperatureDifference(5)
    # create a pump
    pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    pump.setRatedPumpHead(1) #Pa
    pump.setMotorEfficiency(1.0)
    pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
    pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient4ofthePartLoadPerformanceCurve(0)
    # supply components
    # create a water heater
    waterHeater = OpenStudio::Model::WaterHeaterMixed.new(model)
    waterHeater.setTankVolume(1) #ML volume is arbitrary; just needs to be big enough to serve building
    waterHeater.setHeaterThermalEfficiency(0.9)
    waterHeater.setOffCycleParasiticHeatFractiontoTank(0.9)
    waterHeater.setAmbientTemperatureIndicator("Schedule")
    # setpoint temperature schedule
    waterHeaterSetpointSchedule = OsLib_Schedules.createComplexSchedule(model, {"name" => "AEDG Water-Heater-Temp-Schedule",
                                                                                "default_day" => ["All Days",[24,60.0]]})
    waterHeater.setSetpointTemperatureSchedule(waterHeaterSetpointSchedule)
    # ambient temperature schedule
    waterHeaterAmbientTemperatureSchedule = OsLib_Schedules.createComplexSchedule(model, {"name" => "AEDG Water-Heater-Ambient-Temp-Schedule",
                                                                                          "default_day" => ["All Days",[24,22.0]]})
    waterHeater.setAmbientTemperatureSchedule(waterHeaterAmbientTemperatureSchedule)                                                                                      
    # create a scheduled setpoint manager
    swhSetpointSchedule = OsLib_Schedules.createComplexSchedule(model, {"name" => "AEDG SWH-Loop-Temp-Schedule",
                                                                                  "default_day" => ["All Days",[24,60.0]]})
    setpointManagerScheduled = OpenStudio::Model::SetpointManagerScheduled.new(model,swhSetpointSchedule)
    # create a supply bypass pipe
    pipeSupplyBypass = OpenStudio::Model::PipeAdiabatic.new(model)
    # create a supply outlet pipe
    pipeSupplyOutlet = OpenStudio::Model::PipeAdiabatic.new(model)
    # demand components
    waterUseEquipmentDefinition = {}
    waterUseConnections = []
    # building swh flow fraction schedule
    ruleset_name = "AEDG SWH-Flow-Fraction-Schedule"
    winter_design_day = [[24,0]]
    summer_design_day = [[24,1]]
    default_day = ["Weekday",[7,0.05],[8,0.10],[9,0.34],[10,0.60],[11,0.63],[12,0.72],[13,0.79],[14,0.83],[15,0.61],[16,0.65],[18,0.10],[19,0.19],[20,0.25],[22,0.22],[23,0.12],[24,0.09]]
    rules = []
    rules << ["Weekend","1/1-12/31","Sat/Sun",[8,0.03],[14,0.05],[24,0.03]]
    rules << ["Summer Weekday","7/1-8/31","Mon/Tue/Wed/Thu/Fri",[7,0.05],[18,0.10],[19,0.19],[20,0.25],[22,0.22],[23,0.12],[24,0.09]]
    optionsFlowFraction = {"name" => ruleset_name,
                    "winter_design_day" => winter_design_day,
                    "summer_design_day" => summer_design_day,
                    "default_day" => default_day,
                    "rules" => rules}
    flowFractionSchedule = OsLib_Schedules.createComplexSchedule(model, optionsFlowFraction)
    # target temperature schedule
    targetTemperatureSchedule = OsLib_Schedules.createComplexSchedule(model, {"name" => "AEDG SWH-Target-Temperature-Schedule",
                                                                              "default_day" => ["All Days",[24,40]]})
    # sensible fraction schedule name
    sensibleFractionSchedule = OsLib_Schedules.createComplexSchedule(model, {"name" => "AEDG SWH-Sensible-Fraction-Schedule",
                                                                             "default_day" => ["All Days",[24,0.2]]})
    # latent fraction schedule name
    latentFractionSchedule = OsLib_Schedules.createComplexSchedule(model, {"name" => "AEDG SWH-Latent-Fraction-Schedule",
                                                                             "default_day" => ["All Days",[24,0.05]]})
    # hot water supply temperature schedule
    hotWaterSupplyTemperatureSchedule = OsLib_Schedules.createComplexSchedule(model, {"name" => "AEDG SWH-Hot-Supply-Temperature-Schedule",
                                                                                    "default_day" => ["All Days",[24,55]]})
    # create water use equipment definitions, equipment, and connections
    swhSpaceTypes[building_type].each do |applicableSpaceType|
      if applicableSpaceType == "Restroom" and numberOfRestrooms > 0
        waterUsePerRestroom = waterUsePerStudent[applicableSpaceType][building_type]*numberOfStudents/numberOfRestrooms
        # create water use equipment definition for restrooms
        waterUseEquipmentDefinition[applicableSpaceType] = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
        waterUseEquipmentDefinition[applicableSpaceType].setName("AEDG #{applicableSpaceType} Water Use")
        waterUseEquipmentDefinition[applicableSpaceType].setPeakFlowRate(waterUsePerRestroom)
        waterUseEquipmentDefinition[applicableSpaceType].setTargetTemperatureSchedule(targetTemperatureSchedule)                                                                          
        waterUseEquipmentDefinition[applicableSpaceType].setSensibleFractionSchedule(sensibleFractionSchedule)                                                                         
        waterUseEquipmentDefinition[applicableSpaceType].setLatentFractionSchedule(latentFractionSchedule)
        restroomSpaces.each do |restroomSpace|
          # water use equipment
          waterUseEquipment = OpenStudio::Model::WaterUseEquipment.new(waterUseEquipmentDefinition[applicableSpaceType])
          waterUseEquipment.setSpace(restroomSpace)
          waterUseEquipment.setFlowRateFractionSchedule(flowFractionSchedule)
          # water use connection
          waterUseConnection = OpenStudio::Model::WaterUseConnections.new(model)
          waterUseConnection.addWaterUseEquipment(waterUseEquipment)
          waterUseConnection.setHotWaterSupplyTemperatureSchedule(hotWaterSupplyTemperatureSchedule)
          waterUseConnections << waterUseConnection 
        end  
      else
        if representativeSpace[applicableSpaceType]
          # water use equipment definition        
          waterUseEquipmentDefinition[applicableSpaceType] = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
          waterUseEquipmentDefinition[applicableSpaceType].setName("AEDG #{applicableSpaceType} Water Use")
          waterUse = waterUsePerStudent[applicableSpaceType][building_type]*numberOfStudents
          waterUseEquipmentDefinition[applicableSpaceType].setPeakFlowRate(waterUse)
          waterUseEquipmentDefinition[applicableSpaceType].setTargetTemperatureSchedule(targetTemperatureSchedule)                                                                          
          waterUseEquipmentDefinition[applicableSpaceType].setSensibleFractionSchedule(sensibleFractionSchedule)                                                                         
          waterUseEquipmentDefinition[applicableSpaceType].setLatentFractionSchedule(latentFractionSchedule)
          # water use equipment
          waterUseEquipment = OpenStudio::Model::WaterUseEquipment.new(waterUseEquipmentDefinition[applicableSpaceType])
          waterUseEquipment.setSpace(representativeSpace[applicableSpaceType])
          waterUseEquipment.setFlowRateFractionSchedule(flowFractionSchedule)
          # water use connection
          waterUseConnection = OpenStudio::Model::WaterUseConnections.new(model)
          waterUseConnection.addWaterUseEquipment(waterUseEquipment)
          waterUseConnection.setHotWaterSupplyTemperatureSchedule(hotWaterSupplyTemperatureSchedule)
          waterUseConnections << waterUseConnection 
        end
      end  
    end  
    # create a demand bypass pipe
    pipeDemandBypass = OpenStudio::Model::PipeAdiabatic.new(model)
    # create a demand inlet pipe
    pipeDemandInlet = OpenStudio::Model::PipeAdiabatic.new(model)
    # create a demand outlet pipe
    pipeDemandOutlet = OpenStudio::Model::PipeAdiabatic.new(model)
    # connect components to plant loop
    # supply side components
    swhPlant.addSupplyBranchForComponent(waterHeater)
    swhPlant.addSupplyBranchForComponent(pipeSupplyBypass)
    pump.addToNode(swhPlant.supplyInletNode)
    pipeSupplyOutlet.addToNode(swhPlant.supplyOutletNode)
    setpointManagerScheduled.addToNode(swhPlant.supplyOutletNode)
    # demand side components (water coils are added as they are added to airloops and zoneHVAC)
    waterUseConnections.each do |waterUseConnection|
      swhPlant.addDemandBranchForComponent(waterUseConnection)
    end
    swhPlant.addDemandBranchForComponent(pipeDemandBypass)
    pipeDemandInlet.addToNode(swhPlant.demandInletNode)
    pipeDemandOutlet.addToNode(swhPlant.demandOutletNode)
    ### END APPLY SWH RECOMMENDATIONS
    
    # todo - add in lifecycle costs
    expected_life = 25
    years_until_costs_start = 0
    costSwh = costTotalSwhSystem
    lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Refrigeration System", model.getBuilding, costSwh, "CostPerEach", "Construction", expected_life, years_until_costs_start).get

    # add AEDG tips
    aedgTips = ["WH01","WH02","WH03","WH04","WH05","WH06","WH07"]

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips("K12",aedgTips.uniq.sort,runner)
    if not aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
AedgK12Swh.new.registerWithApplication