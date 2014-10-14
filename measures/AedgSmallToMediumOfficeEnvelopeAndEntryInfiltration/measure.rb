#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"
require "#{File.dirname(__FILE__)}/resources/OsLib_HelperMethods"
require "#{File.dirname(__FILE__)}/resources/OsLib_OutdoorAirAndInfiltration"
require "#{File.dirname(__FILE__)}/resources/OsLib_Schedules"

#start the measure
class AedgSmallToMediumOfficeEnvelopeAndEntryInfiltration < OpenStudio::Ruleset::ModelUserScript

  # include measure libraries
  include OsLib_AedgMeasures
  include OsLib_HelperMethods
  include OsLib_OutdoorAirAndInfiltration
  include OsLib_Schedules

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AedgSmallToMediumOfficeEnvelopeAndEntryInfiltration"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make choice argument for target performance
    choices = OpenStudio::StringVector.new
    choices << "AEDG Small To Medium Office - Baseline"
    choices << "AEDG Small To Medium Office - Target"
    infiltrationEnvelope = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("infiltrationEnvelope", choices)
    infiltrationEnvelope.setDisplayName("Envelope Infiltration Level (Not including Occupant Entry Infiltration)")
    infiltrationEnvelope.setDefaultValue("AEDG Small To Medium Office - Target")
    args << infiltrationEnvelope

    #make choice argument for vestibule preference
    choices = OpenStudio::StringVector.new
    choices << "Model Occupant Entry With a Vestibule if Recommended by Small to Medium Office AEDG"
    choices << "Don't model Occupant Entry Infiltration With a Vestibule"
    choices << "Model Occupant Entry With a Vestibule"
    infiltrationOccupant = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("infiltrationOccupant", choices)
    infiltrationOccupant.setDisplayName("Occupant Entry Infiltration Modeling Approach")
    infiltrationOccupant.setDefaultValue("Model Occupant Entry With a Vestibule if Recommended by Small to Medium Office AEDG")
    args << infiltrationOccupant

    #putting stories and names into hash
    story_args = model.getBuildingStorys
    story_args_hash = {}
    story_args.each do |story_arg|
      next if not story_arg.spaces.size > 0
      story_args_hash[story_arg.name.to_s] = story_arg
    end

    # call method to make argument handles and display names from hash of model objects
    storyChoiceArgument = OsLib_HelperMethods.populateChoiceArgFromModelObjects(model,story_args_hash,includeBuilding = nil)

    # make an argument for construction (todo - it would be nice to make this optional and have infiltration spread across entire building if no stories exist)
    story = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("story", storyChoiceArgument["modelObject_handles"], storyChoiceArgument["modelObject_display_names"],true)
    story.setDisplayName("Apply Occupant Entry Infiltration to ThermalZones on this floor.")
    if not storyChoiceArgument["modelObject_display_names"][0].nil?
      story.setDefaultValue(storyChoiceArgument["modelObject_display_names"][0])
    end
    args << story

    #make an argument for number primary occupant entry points
    num_entries = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("num_entries",true)
    num_entries.setDisplayName("Number of Primary Occupant Entry Points on Selected Floor.")
    num_entries.setDefaultValue(4)
    args << num_entries

    #make an argument for number primary occupant entry points
    doorOpeningEventsPerPerson = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("doorOpeningEventsPerPerson",true)
    doorOpeningEventsPerPerson.setDisplayName("Number of Door Opening Events Per Person Per Day (2 is expected minimum for one entry and exit).")
    doorOpeningEventsPerPerson.setDefaultValue(3.0)
    args << doorOpeningEventsPerPerson

    #make an argument for number primary occupant entry points
    pressureDifferenceAcrossDoor_pa = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("pressureDifferenceAcrossDoor_pa",true)
    pressureDifferenceAcrossDoor_pa.setDisplayName("Pressure Difference Across Door At Occupant Entries (pa).")
    pressureDifferenceAcrossDoor_pa.setDefaultValue(4.0)
    args << pressureDifferenceAcrossDoor_pa

    #make an argument for material and installation cost
    costTotalEnvelopeInfiltration = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("costTotalEnvelopeInfiltration",true)
    costTotalEnvelopeInfiltration.setDisplayName("Total cost for all Envelope Improvements ($).")
    costTotalEnvelopeInfiltration.setDefaultValue(0.0)
    args << costTotalEnvelopeInfiltration

    #make an argument for material and installation cost
    costTotalEntryInfiltration = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("costTotalEntryInfiltration",true)
    costTotalEntryInfiltration.setDisplayName("Total cost for all Occupant Entry Improvements ($).")
    costTotalEntryInfiltration.setDefaultValue(0.0)
    args << costTotalEntryInfiltration

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    infiltrationEnvelope = runner.getStringArgumentValue("infiltrationEnvelope",user_arguments)
    infiltrationOccupant = runner.getStringArgumentValue("infiltrationOccupant",user_arguments)
    story = runner.getOptionalWorkspaceObjectChoiceValue("story",user_arguments,model) #model is passed in because of argument type
    num_entries = runner.getIntegerArgumentValue("num_entries",user_arguments)
    doorOpeningEventsPerPerson = runner.getDoubleArgumentValue("doorOpeningEventsPerPerson",user_arguments)
    pressureDifferenceAcrossDoor_pa = runner.getDoubleArgumentValue("pressureDifferenceAcrossDoor_pa",user_arguments)
    costTotalEnvelopeInfiltration = runner.getDoubleArgumentValue("costTotalEnvelopeInfiltration",user_arguments)
    costTotalEntryInfiltration = runner.getDoubleArgumentValue("costTotalEntryInfiltration",user_arguments)

    # check that story exists in model
    modelObjectCheck = OsLib_HelperMethods.checkChoiceArgFromModelObjects(story, "story","to_BuildingStory", runner, user_arguments)

    if modelObjectCheck == false
      return false
    else
      story = modelObjectCheck["modelObject"]
      apply_to_building = modelObjectCheck["apply_to_building"]
    end

    # make hash of argument display name and value  #todo - would be better to get these directly from the display name
    argumentHash = {
        "number of entries" => num_entries,
        "door opening events per person" => doorOpeningEventsPerPerson,
    }
    #check arguments for reasonableness (runner, min, max, argumentArray)
    checkDoubleArguments = OsLib_HelperMethods.checkDoubleArguments(runner,0,nil,argumentHash)
    if not checkDoubleArguments
      return false
    end

      # global variables for costs
    expected_life = 25
    years_until_costs_start = 0

    #reporting initial condition of model
    space_infiltration_objects = model.getSpaceInfiltrationDesignFlowRates
    if space_infiltration_objects.size > 0
      runner.registerInitialCondition("The initial model contained #{space_infiltration_objects.size} space infiltration objects.")
    else
      runner.registerInitialCondition("The initial model did not contain any space infiltration objects.")
    end

    # erase existing infiltration objects used in the model, but save most commonly used schedule
    # todo - would be nice to preserve attic space infiltration. There are a number of possible solutions for this
    removedInfiltration = OsLib_OutdoorAirAndInfiltration.eraseInfiltrationUsedInModel(model,runner)

    # find most common hard assigned from removed infiltration objects
    if removedInfiltration.size > 0
      defaultSchedule = removedInfiltration[0][0]  # not sure why this is array vs. hash. I wanted to use removedInfiltration.keys[0]
    else
      defaultSchedule = nil
    end

    # get desired envelope infiltration area
    if infiltrationEnvelope == "AEDG Small To Medium Office - Baseline"
      targetFlowPerExteriorArea = 0.0003048  #0.06 cfm/ft^2
    else
      targetFlowPerExteriorArea = 0.000254  #0.05 cfm/ft^2
    end

    # hash to pass into infiltration method
    options_OsLib_OutdoorAirAndInfiltration_envelope = {
        "nameSuffix" => " - envelope infiltration", # add this to object name for infiltration
        "defaultBuildingSchedule" => defaultSchedule, # this will set schedule set for selected object
        "setCalculationMethod" => "setFlowperExteriorSurfaceArea",
        "valueForSelectedCalcMethod" => targetFlowPerExteriorArea,
    }
    # add in new envelope infiltration to all spaces in the model
    newInfiltrationPerExteriorSurfaceArea = OsLib_OutdoorAirAndInfiltration.addSpaceInfiltrationDesignFlowRate(model,runner,model.getBuilding, options_OsLib_OutdoorAirAndInfiltration_envelope)
    targetFlowPerExteriorArea_ip =  OpenStudio::convert(targetFlowPerExteriorArea,"m/s","ft/min").get
    runner.registerInfo("Adding infiltration object to all spaces in model with value of #{OpenStudio::toNeatString(targetFlowPerExteriorArea_ip,2,true)} (cfm/ft^2) of exterior surface area.")

    # create lifecycle costs for floors
    envelopeImprovementTotalCost = 0
    totalArea = model.building.get.exteriorSurfaceArea
    newInfiltrationPerExteriorSurfaceArea.each do |infiltrationObject|
      spaceType = infiltrationObject.spaceType.get
      areaForEnvelopeInfiltration_si = OsLib_HelperMethods.getAreaOfSpacesInArray(model,spaceType.spaces,"exteriorArea")["totalArea"]
      fractionOfTotal = areaForEnvelopeInfiltration_si/totalArea
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("#{spaceType.name} - Entry Infiltration Cost", model.getBuilding, fractionOfTotal*costTotalEnvelopeInfiltration, "CostPerEach", "Construction", expected_life, years_until_costs_start)
      envelopeImprovementTotalCost += lcc_mat.get.totalCost
    end

    # get model climate zone and size and set defaultVestibule flag
    vestibuleFlag = false

    # check if vestibule should be used
    if infiltrationOccupant == "Don't model Occupant Entry Infiltration With a Vestibule"
      vestibuleFlag = false
    elsif infiltrationOccupant == "Model Occupant Entry With a Vestibule"
      vestibuleFlag = true
    else
      climateZoneNumber = OsLib_AedgMeasures.getClimateZoneNumber(model,runner)
      if climateZoneNumber == false
        return false
      elsif climateZoneNumber.to_f > 3
        vestibuleFlag = true
      elsif climateZoneNumber.to_f == 3
        building = model.getBuilding
        if building.floorArea > OpenStudio::convert(10000.0,"ft^2","m^2").get
          vestibuleFlag = true
        end
      end
    end

    scheduleWeightHash = {} # make hash of schedules used for occupancy and then the number of people associated with it. Take instance multiplier into account
    nonRulesetScheduleWeighHash = {} # make hash of schedules used for occupancy and then the number of people associated with it. Take instance multiplier into account
    peopleInstances = model.getPeoples
    peopleInstances.each do |peopleInstance|

      # get value from def

      # get schedule
      if not peopleInstance.numberofPeopleSchedule.empty?

        # get floor area for spaceType or space
        if not peopleInstance.spaceType.empty?
          spaceArray = peopleInstance.spaceType.get.spaces
        else
          spaceArray = [peopleInstance.space.get] # making an array just so I can pass in what is expected to measure
        end
        schedule = peopleInstance.numberofPeopleSchedule.get
        floorArea = OsLib_HelperMethods.getAreaOfSpacesInArray(model,spaceArray,areaType = "floorArea")["totalArea"]
        if not schedule.to_ScheduleRuleset.empty?
          if scheduleWeightHash[schedule]
            scheduleWeightHash[schedule] += peopleInstance.getNumberOfPeople(floorArea)
          else
            scheduleWeightHash[schedule] = peopleInstance.getNumberOfPeople(floorArea)
          end
        else # maybe use hash later to get proper number of people vs. just people related to ruleset schedules
          if nonRulesetScheduleWeighHash[schedule]
            nonRulesetScheduleWeighHash[schedule] += peopleInstance.getNumberOfPeople(floorArea)
          else
            nonRulesetScheduleWeighHash[schedule] = peopleInstance.getNumberOfPeople(floorArea)
          end
          runner.registerWarning("#{peopleInstance.name} uses '#{schedule.name}' as a schedule. It isn't a ScheduleRuleset object. That may affect the results of this measure.")
        end
      else
        runner.registerWarning("#{peopleInstance.name} does not have a schedule associated with it.")
      end
    end # end of peopleInstances.each do

    # get maxPeopleInBuilding with merged occupancy schedule
    mergedSchedule = OsLib_Schedules.weightedMergeScheduleRulesets(model, scheduleWeightHash)

    # get max value for merged occupancy schedule
    maxFractionMergedOccupancy = OsLib_Schedules.getMinMaxAnnualProfileValue(model, mergedSchedule["mergedSchedule"])

    # create rate of change schedule from merged schedule
    rateOfChange =  OsLib_Schedules.scheduleFromRateOfChange(model, mergedSchedule["mergedSchedule"])

    # get max value for rate of change. this will help determine max people per hour
    maxFractionRateOfChange = OsLib_Schedules.getMinMaxAnnualProfileValue(model, rateOfChange)

    # misc inputs
    areaPerDoorOpening_ip = 21.0 #ft^2
    pressureDifferenceAcrossDoor_wc = pressureDifferenceAcrossDoor_pa/250 #wc
    typicalOperationHours = 12.0

    # get fraction for merge of occupancy schedule
    if doorOpeningEventsPerPerson <= 2.0
      fractionForRateOfChange = 1.0
    else
      fractionForRateOfChange = (2.0/doorOpeningEventsPerPerson)*0.6 # multiplier added to get closer to expected area under curve.
    end

    # merge the pre and post rate of change schedules together.
    mergedRateSchedule = OsLib_Schedules.weightedMergeScheduleRulesets(model, {mergedSchedule["mergedSchedule"] =>(1.0 - fractionForRateOfChange),rateOfChange => fractionForRateOfChange})
    mergedRateSchedule["mergedSchedule"].setName("Merged Rate of Change/Occupancy Hybrid")

    # todo - until I can make the merge schedule script work on rules I'm going to hard code rule to with 0 value on weekends and summer
    runner.registerInfo("Occupant Entry Infiltration schedule based on default rule profile of people schedules. Hard coded to apply monday through friday.")

    hybridSchedule = mergedRateSchedule["mergedSchedule"]
    yearDescription = model.getYearDescription
    summerStart = yearDescription.makeDate(7,1)
    summerEnd = yearDescription.makeDate(8,31)

    # create weekend rule
    weekendRule = OpenStudio::Model::ScheduleRule.new(hybridSchedule)
    weekendRule.setApplySaturday(true)
    weekendRule.setApplySunday(true)

    # create schedule days to use with weekend rules
    weekendProfile = weekendRule.daySchedule
    weekendProfile.addValue(OpenStudio::Time.new(0, 24, 0, 0),0.0)

    typicalPeopleInBuilding = mergedSchedule["denominator"] * maxFractionMergedOccupancy["max"] # this is max capacity from people objects * max annual schedule fraction value
    if num_entries > 0
      typicalAvgPeoplePerHour = (typicalPeopleInBuilding*doorOpeningEventsPerPerson)/(typicalOperationHours*num_entries)
    else
      typicalAvgPeoplePerHour = 0
    end
    #prepare rule hash for airflow coefficient. Uses people/hour/door as input
    rules = [] # [people per hour per door, airflow coef with vest, airflow coef without vest]
    finalPeoplePerHour = nil # this will be used a little later
    lowAbs = nil

    # values from ASHRAE Fundamentals 16.26 figure 16 for automatic doors with and without vestibules (people per hour per door, with vestibule, without)
    rules << [0.0,0.0,0.0]
    rules << [75.0,190.0,275.0]
    rules << [150.0,315.0,500.0]
    rules << [225.0,475.0,750.0]
    rules << [300.0,610.0,900.0]
    rules << [375.0,750.0,1100.0]
    rules << [450.0,850.0,1225.0]

    #make rule hash for cleaner code
    rulesHash = {}
    rules.each do |rule|
      rulesHash[rule[0]] = {"vestibule" => rule[1],"noVestibule" => rule[2]}
    end

    # get airflow coef from rules
    if vestibuleFlag then hashValue = "vestibule" else hashValue = "noVestibule" end

    # get rule above and below target people per hour and interpolate airflow coefficient
    lower = nil
    upper = nil
    target = typicalAvgPeoplePerHour # calculated earlier
    rulesHash.each do |peoplePerHour,values|
      if target >= peoplePerHour then lower = peoplePerHour  end
      if target <= peoplePerHour
        upper = peoplePerHour
        next
      end
    end
    if lower.nil? then lower = 0 end
    if upper.nil? then upper = 450.0 end
    range = upper-lower
    airflowCoefficient = ((upper - target)/range)*rulesHash[lower][hashValue]  + ((target - lower)/range)*rulesHash[upper][hashValue]

    # Method 2 formula for occupant entry airflow rate from 16.26 of the 2013 ASHRAE Fundamentals
    airFlowRateCfm = num_entries*airflowCoefficient*areaPerDoorOpening_ip*(Math.sqrt(pressureDifferenceAcrossDoor_wc))
    airFlowRate_si =  OpenStudio::convert(airFlowRateCfm,"ft^3","m^3").get/60 # couldn't direct get CFM to m^3/s

    runner.registerInfo("Objects representing #{OpenStudio::toNeatString(airFlowRate_si,2,true)}(cfm) of infiltration will be added to spaces on #{story.name}. Calculated with an airflow coefficent of #{OpenStudio::toNeatString(airflowCoefficient,0,true)} for each door That was calculated on a max door events per hour per door of #{OpenStudio::toNeatString(num_entries,0,true)}. Occupancy schedules in your model were used to both determine the airflow coefficient and to create a custom schedule to use the this infiltration object.")
    if vestibuleFlag
    runner.registerInfo("While infiltration at primary occupant entries is based on using vestibules, vestibule geometry was not added to the model. Per Small to Medium Office AEDG how to implement recommendation EN18 interior and exterior doors should have a minimum distance between them of not less than 7 ft when in the closed position.")
    end

    # find floor area selected floor spaces
    areaForOccupantEntryInfiltration_si = OsLib_HelperMethods.getAreaOfSpacesInArray(model,story.spaces)

    # hash to pass into infiltration method
    options_OsLib_OutdoorAirAndInfiltration_entry = {
        "nameSuffix" => " - occupant entry infiltration", # add this to object name for infiltration
        "schedule" => mergedRateSchedule["mergedSchedule"], # this will set schedule set for selected object
        "setCalculationMethod" => "setFlowperSpaceFloorArea",
        "valueForSelectedCalcMethod" => airFlowRate_si/areaForOccupantEntryInfiltration_si["totalArea"],
    }
    # add in new envelope infiltration to all spaces in the model
    newInfiltrationPerFloorArea =  OsLib_OutdoorAirAndInfiltration.addSpaceInfiltrationDesignFlowRate(model,runner,story.spaces, options_OsLib_OutdoorAirAndInfiltration_entry)

    # create lifecycle costs for floors
    entryImprovementTotalCost = 0
    totalArea = areaForOccupantEntryInfiltration_si["totalArea"]
    storySpaceHash = areaForOccupantEntryInfiltration_si["spaceAreaHash"]
    newInfiltrationPerFloorArea.each do |infiltrationObject|
      space = infiltrationObject.space.get
      fractionOfTotal = storySpaceHash[space]/totalArea
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("#{space.name} - Entry Infiltration Cost", space, fractionOfTotal*costTotalEntryInfiltration, "CostPerEach", "Construction", expected_life, years_until_costs_start)
      entryImprovementTotalCost += lcc_mat.get.totalCost
    end

    # populate AEDG tip keys
    aedgTips = []

    # always need tip 17
    aedgTips.push("EN17")

    if vestibuleFlag
      aedgTips.push("EN18")
    end

    # don't really need not applicable flag on this measure, any building with spaces will be affected

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips("SmMdOff",aedgTips.uniq.sort,runner)
    if not aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    #reporting final condition of model
    space_infiltration_objects = model.getSpaceInfiltrationDesignFlowRates
    if space_infiltration_objects.size > 0
      runner.registerFinalCondition("The final model contains #{space_infiltration_objects.size} space infiltration objects. Cost was increased by $#{OpenStudio::toNeatString(envelopeImprovementTotalCost,2,true)} for envelope infiltration, and $#{OpenStudio::toNeatString(entryImprovementTotalCost,2,true)} for occupant entry infiltration. #{aedgTipsLong}")
    else
      runner.registerFinalCondition("The final model does not contain any space infiltration objects. Cost was increased by $#{OpenStudio::toNeatString(envelopeImprovementTotalCost,2,true)} for envelope infiltration, and $#{OpenStudio::toNeatString(envelopeImprovementTotalCost,2,true)} for occupant entry infiltration. #{aedgTipsLong}")
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AedgSmallToMediumOfficeEnvelopeAndEntryInfiltration.new.registerWithApplication