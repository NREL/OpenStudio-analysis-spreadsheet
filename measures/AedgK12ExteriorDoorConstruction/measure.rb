#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_hash/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"
require "#{File.dirname(__FILE__)}/resources/OsLib_Constructions"

#start the measure
class AedgK12ExteriorDoorConstruction < OpenStudio::Ruleset::ModelUserScript
  include OsLib_AedgMeasures
  include OsLib_Constructions

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AedgK12ExteriorDoorConstruction"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for material and installation cost
    material_cost_insulation_increase_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost_insulation_increase_ip",true)
    material_cost_insulation_increase_ip.setDisplayName("Increase Cost per Area of Construction Where Insulation was Improved ($/ft^2).")
    material_cost_insulation_increase_ip.setDefaultValue(0.0)
    args << material_cost_insulation_increase_ip

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    material_cost_insulation_increase_ip = runner.getDoubleArgumentValue("material_cost_insulation_increase_ip",user_arguments)

    # no validation needed for cost inputs, negative values are fine, however negative would be odd choice since this measure only improves vs. decreases insulation and SRI performance

    # global variables for costs
    expected_life = 25
    years_until_costs_start = 0
    material_cost_insulation_increase_si = OpenStudio::convert(material_cost_insulation_increase_ip,"1/ft^2","1/m^2").get
    running_cost_insulation = 0

    #prepare rule hash
    rules = [] #climate zone, door type, standards surface type, thermal transmittance (Btu/h·ft2·°F)

    # while metal roll up doors should be highly reflective the AEDG doesn't give a target.

    # Door
    # notes: doesn't matter if swinging or not
    rules << ["1","ExteriorDoor","NA",0.70]
    rules << ["2","ExteriorDoor","NA",0.70]
    rules << ["3","ExteriorDoor","NA",0.70]
    rules << ["4","ExteriorDoor","NA",0.50]
    rules << ["5","ExteriorDoor","NA",0.50]
    rules << ["6","ExteriorDoor","NA",0.50]
    rules << ["7","ExteriorDoor","NA",0.50]
    rules << ["8","ExteriorDoor","NA",0.50]

    # SteelFramed
    # notes: overhead sliding and rollup have same targets
    rules << ["1","OverheadDoor","RollUp",1.45]
    rules << ["2","OverheadDoor","RollUp",0.50]
    rules << ["3","OverheadDoor","RollUp",0.50]
    rules << ["4","OverheadDoor","RollUp",0.50]
    rules << ["5","OverheadDoor","RollUp",0.50]
    rules << ["6","OverheadDoor","RollUp",0.50]
    rules << ["7","OverheadDoor","RollUp",0.50]
    rules << ["8","OverheadDoor","RollUp",0.50]

    # WoodFramed
    # notes: this will be catch all of user doesn't have roll up as standards surface type
    rules << ["1","OverheadDoor","Sliding",1.45]
    rules << ["2","OverheadDoor","Sliding",0.50]
    rules << ["3","OverheadDoor","Sliding",0.50]
    rules << ["4","OverheadDoor","Sliding",0.50]
    rules << ["5","OverheadDoor","Sliding",0.50]
    rules << ["6","OverheadDoor","Sliding",0.50]
    rules << ["7","OverheadDoor","Sliding",0.50]
    rules << ["8","OverheadDoor","Sliding",0.50]

    #make rule hash for cleaner code
    rulesHash = {}
    rules.each do |rule|
      rulesHash["#{rule[0]} #{rule[1]} #{rule[2]}"] = {"conductivity_ip" => rule[3]}
    end

    #get climate zone
    climateZoneNumber = OsLib_AedgMeasures.getClimateZoneNumber(model,runner)
    #climateZoneNumber = "4" # this is just in for quick testing of different climate zones

    # return false with error if can't find climate zone number
    if climateZoneNumber == false
      return false
    end

    # get starting r-value
    startingRvaluesExtWall = []

    # flag for roof surface type for tips
    doorFlag = false
    overheadDoorRollUpFlag = false
    overheadDoorSlidingFlag = false

    # affected area counter
    insulation_affected_area = 0

    # construction hashes  (construction is key, value is array [thermal transmittance (Btu/h·ft2·°F),rule thermal transmittance (Btu/h·ft2·°F),classification string)
    doorConstructions = {}
    overheadDoorRollUpConstructions = {}
    overheadDoorSlidingConstructions = {}

    # this contains constructions that do not have a recognized Standards Construction Type
    otherConstructions = []

    # loop through constructions
    constructions = model.getConstructions
    constructions.each do |construction|

      #skip if not used
      next if not construction.getNetArea > 0

      #skip if not opaque
      next if not construction.isOpaque

      # get construction and standard
      constructionStandard = construction.standardsInformation

      # get intended surface and standards construction type
      intendedSurfaceType = constructionStandard.intendedSurfaceType
      constructionType = constructionStandard.standardsConstructionType

      # get conductivity
      conductivity_si = construction.thermalConductance.get
      r_value_ip = OpenStudio::convert(1/conductivity_si,"m^2*K/W","ft^2*h*R/Btu").get

      # check rules based on intended use and type
      if intendedSurfaceType.to_s == "OverheadDoor"

        if constructionType.to_s == "RollUp"


          #store starting values
          startingRvaluesExtWall << r_value_ip
          overheadDoorRollUpFlag = true

          # test construction against rules
          ruleSet = rulesHash["#{climateZoneNumber} OverheadDoor RollUp"]
          if 1/r_value_ip > ruleSet["conductivity_ip"]
            overheadDoorRollUpConstructions[construction] = {"conductivity_ip" => 1/r_value_ip,"transmittance_ip_rule" => ruleSet["conductivity_ip"],"classification" => "overheadDoorRollUpConstructions"}
          end

        else # don't need to test, this is a catch all constructionType.to_s == "Sliding"

          #store starting values
          startingRvaluesExtWall << r_value_ip
          overheadDoorSlidingFlag = true

          # test construction against rules
          ruleSet = rulesHash["#{climateZoneNumber} OverheadDoor Sliding"]
          if 1/r_value_ip > ruleSet["conductivity_ip"]
            overheadDoorSlidingConstructions[construction] = {"conductivity_ip" => 1/r_value_ip,"transmittance_ip_rule" => ruleSet["conductivity_ip"],"classification" => "overheadDoorSlidingConstructions"}
          end

        end

      elsif intendedSurfaceType.to_s == "ExteriorDoor"

        # don't need to check standards construction type, all non overhead doors will be treated the same.

        #store starting values
        startingRvaluesExtWall << r_value_ip
        doorFlag = true

        # test construction against rules
        ruleSet = rulesHash["#{climateZoneNumber} ExteriorDoor NA"]
        if 1/r_value_ip > ruleSet["conductivity_ip"]
          doorConstructions[construction] = {"conductivity_ip" => 1/r_value_ip,"transmittance_ip_rule" => ruleSet["conductivity_ip"],"classification" => "doorConstructions"}
        end

      end # end of intendedSurfaceType == "OverheadDoor"

    end #end of constructions.each do

    # create warning if construction used on exterior wall doesn't have a surface type of "ExteriorWall", or if constructions tagged to be used as exterior wall, are used on other surface types
    otherConstructionsWarned = []
    surfaces = model.getSurfaces
    surfaces.each do |surface|

      if not surface.construction.empty?
        construction = surface.construction.get

        if surface.outsideBoundaryCondition == "Outdoors" and surface.surfaceType == "Door"

          if otherConstructions.include? construction and not otherConstructionsWarned.include? construction
            runner.registerWarning("#{construction.name} is used on one or more exterior door surfaces but has an intended surface type that is not a door. We can not infer the proper performance target, this construction will not be altered.")
            otherConstructionsWarned << construction
          end

        elsif surface.outsideBoundaryCondition == "Outdoors" and surface.surfaceType == "OverheadDoor"

          if otherConstructions.include? construction and not otherConstructionsWarned.include? construction
            runner.registerWarning("#{construction.name} is used on one or more exterior overhead door surfaces but has an intended surface type that is not an overhead door. We can not infer the proper performance target, this construction will not be altered.")
            otherConstructionsWarned << construction
          end

        else

          if doorConstructions.include? construction or overheadDoorRollUpConstructions.include? construction or overheadDoorSlidingConstructions.include? construction
            runner.registerWarning("#{surface.name} uses #{construction.name} as a construction that this measure expects to be used for exterior doors. This surface has a type of #{surface.surfaceType} and a a boundary condition of #{surface.outsideBoundaryCondition}. This may result in unexpected changes to your model.")
          end

        end #end of surface.outsideBoundaryCondition

      end # end of if not surface.construction.empty?

    end # end of surfaces.each do

    # alter constructions and add lcc
    constructionsToChange = doorConstructions.sort + overheadDoorRollUpConstructions.sort + overheadDoorSlidingConstructions.sort
    constructionsToChange.each do |construction,hash|

      #gather insulation inputs

      # gather target decrease in conductivity
      conductivity_ip_starting = hash["conductivity_ip"]
      conductivity_si_starting = OpenStudio::convert(conductivity_ip_starting,"Btu/ft^2*h*R","W/m^2*K").get
      r_value_ip_starting = 1/conductivity_ip_starting # ft^2*h*R/Btu
      r_value_si_starting = 1/conductivity_si_starting # m^2*K/W
      conductivity_ip_target = hash["transmittance_ip_rule"].to_f
      conductivity_si_target = OpenStudio::convert(conductivity_ip_target,"Btu/ft^2*h*R","W/m^2*K").get
      r_value_ip_target = 1/conductivity_ip_target # ft^2*h*R/Btu
      r_value_si_target = 1/conductivity_si_target # m^2*K/W

      # infer insulation material to get input for target thickness
      minThermalResistance = OpenStudio::convert(0.25,"ft^2*h*R/Btu","m^2*K/W").get # lowered min to 0.25 here vs. 1.0 that was used in wall and roof measures.
      inferredInsulationLayer = OsLib_Constructions.inferInsulationLayer(construction,minThermalResistance)
      rvalue_si_deficiency = r_value_si_target - r_value_si_starting

      # add lcc for insulation
      lcc_mat_insulation = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat_Insulation - #{construction.name}", construction, material_cost_insulation_increase_si, "CostPerArea", "Construction", expected_life, years_until_costs_start)
      lcc_mat_insulation_value = lcc_mat_insulation.get.totalCost
      running_cost_insulation += lcc_mat_insulation_value

      # adjust existing material or add new one
      if (inferredInsulationLayer["insulationFound"] and hash["classification"] == "doorConstructions") or (inferredInsulationLayer["insulationFound"] and hash["classification"] == "metalConstructions") #if insulation layer was found

        # gather inputs for method
        target_material_rvalue_si = inferredInsulationLayer["construction_thermal_resistance"] +  rvalue_si_deficiency

        # run method to change insulation layer thickness in cloned material (material,starting_r_value_si,target_r_value_si, model)
        new_material = OsLib_Constructions.setMaterialThermalResistance(inferredInsulationLayer["construction_layer"],target_material_rvalue_si)

        # connect new material to original construction
        construction.eraseLayer(inferredInsulationLayer["layer_index"])
        construction.insertLayer(inferredInsulationLayer["layer_index"],new_material)

        # get conductivity
        final_conductivity_si = construction.thermalConductance.get
        final_r_value_ip = OpenStudio::convert(1/final_conductivity_si,"m^2*K/W","ft^2*h*R/Btu").get

        # report on edited material
        runner.registerInfo("The R-value of #{construction.name} has been increased from #{OpenStudio::toNeatString(r_value_ip_starting,2,true)} to #{OpenStudio::toNeatString(final_r_value_ip,2,true)}(ft^2*h*R/Btu) at a cost of $#{OpenStudio::toNeatString(lcc_mat_insulation_value,2,true)}. Increased performance was accomplished by adjusting thermal resistance of #{new_material.name}.")

      else

        # inputs to pass to method
        conductivity = 0.045 # W/m*K
        thickness = rvalue_si_deficiency * conductivity # meters

        addNewLayerToConstruction_Inputs = {
            "roughness" => "MediumRough",
            "thickness" => thickness, # meters,
            "conductivity" => conductivity, # W/m*K
            "density" => 265.0,
            "specificHeat" => 836.8,
            "thermalAbsorptance" => 0.9,
            "solarAbsorptance" => 0.7,
            "visibleAbsorptance" => 0.7,
        }

        # create new material if can't infer insulation material (construction,thickness, conductivity, density, specificHeat, roughness,thermalAbsorptance, solarAbsorptance,visibleAbsorptance,model)
        newMaterialLayer = OsLib_Constructions.addNewLayerToConstruction(construction,addNewLayerToConstruction_Inputs)

        # get conductivity
        final_conductivity_si = construction.thermalConductance.get
        final_r_value_ip = OpenStudio::convert(1/final_conductivity_si,"m^2*K/W","ft^2*h*R/Btu").get

        # report on edited material
        runner.registerInfo("The R-value of #{construction.name} has been increased from #{OpenStudio::toNeatString(r_value_ip_starting,2,true)} to #{OpenStudio::toNeatString(final_r_value_ip,2,true)}(ft^2*h*R/Btu) at a cost of $#{OpenStudio::toNeatString(lcc_mat_insulation_value,2,true)}. Increased performance was accomplished by adding a new material layer to the outside of #{construction.name}.")

      end # end of if inferredInsulationLayer[4]

      #add to area counter
      insulation_affected_area += construction.getNetArea # OpenStudio handles matched surfaces so they are not counted twice.

    end #end of constructionsToChange.each do

    # populate AEDG tip keys
    aedgTips = []

    if doorFlag
      aedgTips.push("EN15","EN17")
    end
    if overheadDoorRollUpFlag
      aedgTips.push("EN16","EN17")
    end
    if overheadDoorSlidingFlag
      aedgTips.push("EN16","EN17")
    end

    # create not applicable of no constructions were tagged to change
    if aedgTips.size == 0
      runner.registerAsNotApplicable("No surfaces use constructions tagged as an exterior door type recognized by this measure. No exterior door constructions were altered.")
      return true
    end

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips("K12",aedgTips.uniq.sort,runner)
    if not aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    #reporting initial condition of model
    startingRvalue = startingRvaluesExtWall

    runner.registerInitialCondition("Starting R-values for constructions intended for exterior door surfaces range from #{OpenStudio::toNeatString(startingRvalue.min,2,true)} to #{OpenStudio::toNeatString(startingRvalue.max,2,true)}(ft^2*h*R/Btu).")

    #reporting final condition of model
    insulation_affected_area_ip = OpenStudio::convert(insulation_affected_area,"m^2","ft^2").get
    runner.registerFinalCondition("#{OpenStudio::toNeatString(insulation_affected_area_ip,0,true)}(ft^2) of constructions intended for exterior door surfaces had insulation enhanced at a cost of $#{OpenStudio::toNeatString(running_cost_insulation,0,true)}. #{aedgTipsLong}")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AedgK12ExteriorDoorConstruction.new.registerWithApplication