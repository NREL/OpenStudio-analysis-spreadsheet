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
class AedgOfficeSwh < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AedgOfficeSwh"
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
    numberOfEmployees = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("numberOfEmployees",true)
    numberOfEmployees.setDisplayName("Total Number of Employees.")
    # calculate default value
    # get total number of students
    employeeCount = 0
    model.getThermalZones.each do |zone|
      zoneMultiplier = zone.multiplier
      zone.spaces.each do |space|
        if space.spaceType.is_initialized
          if space.spaceType.get.standardsSpaceType.is_initialized
            if space.spaceType.get.standardsBuildingType.is_initialized
              if space.spaceType.get.standardsSpaceType.get.include? "Office" or (space.spaceType.get.standardsSpaceType.get == "WholeBuilding" and space.spaceType.get.standardsBuildingType.get.include? "Office")
                # add up number of people from each classroom space
                employeeCount += space.numberOfPeople * zoneMultiplier
              end  
            end
          end  
        end
      end   
    end
    if employeeCount.to_i > 0
      numberOfEmployees.setDefaultValue(employeeCount.to_i)
    end  
    args << numberOfEmployees
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
    numberOfEmployees = runner.getIntegerArgumentValue("numberOfEmployees",user_arguments)
    # default building/space types
    standardBuildingTypeTest = "Office"
    primarySpaceType = "Office"
    swhSpaceType = "Restroom"
    # water use equipment inputs
    waterUsePerEmployee = 0.00000025957074 # m3/s*employee
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
            if space.spaceType.get.standardsBuildingType.is_initialized
              if space.spaceType.get.standardsSpaceType.get.include? primarySpaceType or (space.spaceType.get.standardsSpaceType.get == "WholeBuilding" and space.spaceType.get.standardsBuildingType.get.include? primarySpaceType)
                standardBuildingType = space.spaceType.get.standardsBuildingType.get
              end  
            end
          end
        end
      end
    end
    building_type = false
    standardBuildingTypeTest.each do |building_type_test|
      if standardBuildingType.include? building_type_test
        building_type = building_type_test
      end  
    end
    unless building_type
      # building type not specified or not appropriate for this measure
      runner.registerInfo("Building type is not specified or not supported.  Measure will proceed assuming type is #{standardBuildingTypeTest}.")
      building_type = standardBuildingTypeTest
    end
    ### END DETERMINE BUILDING TYPE
  
    ### START FIND SWH SPACES
    # for restroom, water use will be applied to each restroom
    numberOfRestrooms = 0
    restroomSpaces = []
    # get all restroom spaces
    model.getSpaces.each do |space|
      if space.spaceType.is_initialized
        if space.spaceType.get.standardsSpaceType.is_initialized
          if space.spaceType.get.standardsSpaceType.get.include? swhSpaceType
            restroomSpaces << space
            numberOfRestrooms += 1
          end
        end
      end  
    end
    unless numberOfRestrooms > 0
      runner.registerInfo("Model does not have any #{swhSpaceType} spaces.  Measure will not apply #{swhSpaceType} recommendations.")
      return true
    end
    ### END FIND SWH SPACES

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
    waterUsePerRestroom = waterUsePerEmployee*numberOfEmployees/numberOfRestrooms
    # create water use equipment definition for restrooms
    waterUseEquipmentDefinition = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
    waterUseEquipmentDefinition.setName("AEDG #{swhSpaceType} Water Use")
    waterUseEquipmentDefinition.setPeakFlowRate(waterUsePerRestroom)
    waterUseEquipmentDefinition.setTargetTemperatureSchedule(targetTemperatureSchedule)                                                                          
    waterUseEquipmentDefinition.setSensibleFractionSchedule(sensibleFractionSchedule)                                                                         
    waterUseEquipmentDefinition.setLatentFractionSchedule(latentFractionSchedule)
    restroomSpaces.each do |restroomSpace|
      # water use equipment
      waterUseEquipment = OpenStudio::Model::WaterUseEquipment.new(waterUseEquipmentDefinition)
      waterUseEquipment.setSpace(restroomSpace)
      waterUseEquipment.setFlowRateFractionSchedule(flowFractionSchedule)
      # water use connection
      waterUseConnection = OpenStudio::Model::WaterUseConnections.new(model)
      waterUseConnection.addWaterUseEquipment(waterUseEquipment)
      waterUseConnection.setHotWaterSupplyTemperatureSchedule(hotWaterSupplyTemperatureSchedule)
      waterUseConnections << waterUseConnection 
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
    aedgTips = ["WH01","WH02","WH03","WH04","WH05","WH06"]

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips("SmMdOff",aedgTips.uniq.sort,runner)
    if not aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
AedgOfficeSwh.new.registerWithApplication