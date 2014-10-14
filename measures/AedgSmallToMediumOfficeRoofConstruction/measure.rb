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
class AedgSmallToMediumOfficeRoofConstruction < OpenStudio::Ruleset::ModelUserScript
  include OsLib_AedgMeasures
  include OsLib_Constructions

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AedgSmallToMediumOfficeRoofConstruction"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for material and installation cost
    material_cost_insulation_increase_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost_insulation_increase_ip",true)
    material_cost_insulation_increase_ip.setDisplayName("Increase Cost per Area of Construction Where Insulation was Improved ($/ft^2).")
    material_cost_insulation_increase_ip.setDefaultValue(0.0)
    args << material_cost_insulation_increase_ip

    #make an argument for material and installation cost
    material_cost_sri_increase_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost_sri_increase_ip",true)
    material_cost_sri_increase_ip.setDisplayName("Increase Cost per Area of Construction Where Solar Reflectance Index (SRI) was Improved. ($/ft^2).")
    material_cost_sri_increase_ip.setDefaultValue(0.0)
    args << material_cost_sri_increase_ip    
    
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
    material_cost_sri_increase_ip = runner.getDoubleArgumentValue("material_cost_sri_increase_ip",user_arguments)

    # no validation needed for cost inputs, negative values are fine, however negative would be odd choice since this measure only improves vs. decreases insulation and SRI performance

    # global variables for costs
    expected_life = 25
    years_until_costs_start = 0
    material_cost_insulation_increase_si = OpenStudio::convert(material_cost_insulation_increase_ip,"1/ft^2","1/m^2").get
    material_cost_sri_increase_si = OpenStudio::convert(material_cost_sri_increase_ip,"1/ft^2","1/m^2").get
    running_cost_insulation = 0
    running_cost_sri = 0

    #prepare rule hash
    rules = [] #climate zone, roof type, thermal transmittance (Btu/h·ft2·°F), SRI

    # IEAD
    rules << ["1","IEAD",0.048,78.0] # R-20.0 ci.
    rules << ["2","IEAD",0.039,78.0] # R-25.0 ci.
    rules << ["3","IEAD",0.039,78.0] # R-25.0 ci.
    rules << ["4","IEAD",0.032,0] # R-30.0 ci., SRI Comply with Standard 90.1
    rules << ["5","IEAD",0.032,0] # R-30.0 ci., SRI Comply with Standard 90.1
    rules << ["6","IEAD",0.032,0] # R-30.0 ci., SRI Comply with Standard 90.1
    rules << ["7","IEAD",0.028,0] # R-35.0 ci., SRI Comply with Standard 90.1
    rules << ["8","IEAD",0.028,0] # R-35.0 ci., SRI Comply with Standard 90.1

    # Attic
    rules << ["1","Attic",0.027,78.0] # R-38.0
    rules << ["2","Attic",0.027,78.0] # R-38.0
    rules << ["3","Attic",0.027,78.0] # R-38.0
    rules << ["4","Attic",0.021,0] # R-49.0, SRI Comply with Standard 90.1
    rules << ["5","Attic",0.021,0] # R-49.0, SRI Comply with Standard 90.1
    rules << ["6","Attic",0.021,0] # R-49.0, SRI Comply with Standard 90.1
    rules << ["7","Attic",0.017,0] # R-60.0, SRI Comply with Standard 90.1
    rules << ["8","Attic",0.017,0] # R-60.0, SRI Comply with Standard 90.1

    # Metal
    rules << ["1","Metal",0.041,78.0] # R-19.0 + R-10.0 FC (confirm same change as K12 using 0.041 vs. 0.057)
    rules << ["2","Metal",0.041,78.0] # R-19.0 + R-10.0 FC (confirm same change as K12 using 0.041 vs. 0.057)
    rules << ["3","Metal",0.041,78.0] # R-19.0 + R-10.0 FC (confirm same change as K12 using 0.041 vs. 0.057)
    rules << ["4","Metal",0.035,0] # R-19.0 + R-11 Ls, SRI Comply with Standard 90.1
    rules << ["5","Metal",0.031,0] # R-25.0 + R-11 Ls, SRI Comply with Standard 90.1
    rules << ["6","Metal",0.031,0] # R-25.0 + R-11 Ls, SRI Comply with Standard 90.1
    rules << ["7","Metal",0.029,0] # R-30.0 + R-11 Ls, SRI Comply with Standard 90.1
    rules << ["8","Metal",0.026,0] # R-25.0 + R-11 + R-11 Ls, SRI Comply with Standard 90.1

    #make rule hash for cleaner code
    rulesHash = {}
    rules.each do |rule|
      rulesHash["#{rule[0]} #{rule[1]}"] = {"conductivity_ip" => rule[2], "sri" => rule[3]}
    end

    #get climate zone
    climateZoneNumber = OsLib_AedgMeasures.getClimateZoneNumber(model,runner)
    #climateZoneNumber = "4" # this is just in for quick testing of different climate zones

    # add message for climate zones 4-8 about SRI (while the office AEDG doesn't mention this in table like the K-12 AEDG does, still seems like relevant message.)
    if climateZoneNumber == false
      return false
    elsif climateZoneNumber.to_f > 3
      runner.registerInfo("For Climate Zone #{climateZoneNumber} Solar Reflectance Index (SRI) should comply with Standard 90.1.")
    end

    # get starting r-value and SRI ranges
    startingRvaluesExtRoof = []
    startingRvaluesAtticInterior = []
    startingSriExtRoof = []

    # flag for roof surface type for tips
    ieadFlag = false
    metalFlag = false
    atticFlag = false

    # affected area counter
    insulation_affected_area = 0
    sri_affected_area = 0

    # construction hashes  (construction is key, value is array [thermal transmittance (Btu/h·ft2·°F), SRI,rule thermal transmittance (Btu/h·ft2·°F), rule SRI,classification string)
    ieadConstructions = {}
    metalConstructions = {}
    atticConstructions = {} #will initially load all constructions used in model, and will delete later if passes test

    # this contains constructions that should not have exterior roofs assigned
    otherConstructions = []

    # make array for spaces that have a surface with at least one exterior attic surface
    atticSpaces = []

    # loop through constructions
    constructions = model.getConstructions
    constructions.each do |construction|

      #skip if not used
      next if not construction.getNetArea > 0

      #skip if not opaque
      next if not construction.isOpaque

      # get construction and standard
      constructionStandard = construction.standardsInformation

      # get roof type
      intendedSurfaceType = constructionStandard.intendedSurfaceType
      constructionType = constructionStandard.standardsConstructionType

      # get conductivity
      conductivity_si = construction.thermalConductance.get
      r_value_ip = OpenStudio::convert(1/conductivity_si,"m^2*K/W","ft^2*h*R/Btu").get

      # get SRI (only need of climate zones 1-3)
      sri = OsLib_Constructions.getConstructionSRI(construction)

      # flags for construction loop
      ruleRvalueFlag = true
      ruleSriFlag = true

      # IEAD and Metal roofs should have intendedSurfaceType of ExteriorRoof
      if intendedSurfaceType.to_s == "ExteriorRoof"

        if constructionType.to_s == "IEAD"

          #store starting values
          startingRvaluesExtRoof << r_value_ip
          startingSriExtRoof << sri
          ieadFlag = true

          # test construction against rules
          ruleSet = rulesHash["#{climateZoneNumber} IEAD"]
          if 1/r_value_ip > ruleSet["conductivity_ip"]
            ruleRvalueFlag = false
          end
          if sri < ruleSet["sri"]
            ruleSriFlag = false
          end
          if not ruleRvalueFlag or not ruleSriFlag
            ieadConstructions[construction] = {"conductivity_ip" => 1/r_value_ip,"sri" => sri,"transmittance_ip_rule" => ruleSet["conductivity_ip"],"sri_rule" => ruleSet["sri"],"classification" => "ieadConstructions"}
          end

        elsif constructionType.to_s == "Metal"

          #store starting values
          startingRvaluesExtRoof << r_value_ip
          startingSriExtRoof << sri
          metalFlag = true

          # test construction against rules
          ruleSet = rulesHash["#{climateZoneNumber} Metal"]
          if 1/r_value_ip > ruleSet["conductivity_ip"]
            ruleRvalueFlag = false
          end
          if sri < ruleSet["sri"]
            ruleSriFlag = false
          end
          if not ruleRvalueFlag or not ruleSriFlag
            metalConstructions[construction] = {"conductivity_ip" => 1/r_value_ip,"sri" => sri,"transmittance_ip_rule" => ruleSet["conductivity_ip"],"sri_rule" => ruleSet["sri"],"classification" => "metalConstructions"}
          end

        else
          # create warning if a construction passing through here is used on a roofCeiling surface with a boundary condition of "Outdoors"
          otherConstructions << construction
        end

      elsif intendedSurfaceType.to_s == "AtticRoof" or intendedSurfaceType.to_s == "AtticWall" or intendedSurfaceType.to_s == "AtticFloor"

        #store starting values
        atticFlag = true

        atticConstructions[construction] = {"conductivity_ip" => 1/r_value_ip,"sri" => sri} # will extend this hash later

      else
        # create warning if a construction passing through here is used on a roofCeiling surface with a boundary condition of "Outdoors"
        otherConstructions << construction

      end # end of intendedSurfaceType == "ExteriorRoof"

    end #end of constructions.each do

    # create warning if construction used on exterior roof doesn't have a surface type of "ExteriorRoof", or if constructions tagged to be used as roof, are used on other surface types
    otherConstructionsWarned = []
    atticSurfaces = [] # to test against attic spaces later on
    surfaces = model.getSurfaces
    surfaces.each do |surface|

      if not surface.construction.empty?
        construction = surface.construction.get

        # populate attic spaces
        if surface.outsideBoundaryCondition == "Outdoors" and atticConstructions.include? construction
          if not surface.space.empty?
            if not atticSpaces.include? surface.space.get
            atticSpaces << surface.space.get
            end
          end
        elsif atticConstructions.include? construction
          atticSurfaces << surface
        end

        if surface.outsideBoundaryCondition == "Outdoors" and surface.surfaceType == "RoofCeiling"

          if otherConstructions.include? construction and not otherConstructionsWarned.include? construction
            runner.registerWarning("#{construction.name} is used on one or more exterior roof surfaces but has an intended surface type or construction type not recognized by this measure. As we can not infer the proper performance target, this construction will not be altered.")
            otherConstructionsWarned << construction
          end

        else

          if ieadConstructions.include? construction or metalConstructions.include? construction
            runner.registerWarning("#{surface.name} uses #{construction.name} as a construction that this measure expects to be used for exterior roofs. This surface has a type of #{surface.surfaceType} and a a boundary condition of #{surface.outsideBoundaryCondition}. This may result in unexpected changes to your model.")
          end

        end #end of surface.outsideBoundaryCondition

      end # end of if not surface.construction.empty?

    end # end of surfaces.each do

    # hashes to hold classification of attic surfaces
    atticSurfacesInterior = {} # this will include paris of matched surfaces
    atticSurfacesExteriorExposed = {}
    atticSurfacesExteriorExposedNonRoof = {}
    atticSurfacesOtherAtticDemising = {}

    # look for attic surfaces that are not in attic space or matched to them.
    atticSpaceWarning = false
    atticSurfaces.each do |surface|
      if not surface.space.empty?
        space = surface.space.get
        if not atticSpaces.include? space
          if surface.outsideBoundaryCondition == "Surface"
            #get space of matched surface and see if it is also an attic
            next if surface.adjacentSurface.empty?
            adjacentSurface = surface.adjacentSurface.get
            next if adjacentSurface.space.empty?
            adjacentSurfaceSpace =  adjacentSurface.space.get
            if not atticSpaces.include? adjacentSurfaceSpace
              atticSpaceWarning = true
            end
          else
            atticSpaceWarning = true
          end
        end
      end
    end
    if atticSpaceWarning
      runner.registerWarning("#{surface.name} uses #{construction.name} as a construction that this measure expects to be used for attics. This surface has a type of #{surface.surfaceType} and a a boundary condition of #{surface.outsideBoundaryCondition}. This may result in unexpected changes to your model.")
    end

    # flag for testing
    interiorAtticSurfaceInSpace = false

    # loop through attic spaces to classify surfaces with attic intended surface type
    atticSpaces.each do |atticSpace|
      atticSurfaces = atticSpace.surfaces

      # array for surfaces that don't use an attic construction
      surfacesWithNonAtticConstructions = []

      # loop through attic surfaces
      atticSurfaces.each do |atticSurface|

        next if atticSurface.construction.empty?
        construction = atticSurface.construction.get
        if atticConstructions.include? construction
          conductivity_ip = atticConstructions[construction]["conductivity_ip"]
          r_value_ip = 1/conductivity_ip
          sri = atticConstructions[construction]["sri"]
        else
          surfacesWithNonAtticConstructions << atticSurface.name
          next
        end

        # warn if any exterior exposed roof surfaces are not attic.
        if atticSurface.outsideBoundaryCondition == "Outdoors"

          # only want to change SRI if it is a roof
          if atticSurface.surfaceType == "RoofCeiling"

            # store starting value for SRI
            startingSriExtRoof << sri
            atticSurfacesExteriorExposed[atticSurface] = construction
          else
            atticSurfacesExteriorExposedNonRoof[atticSurface] = construction
          end

        elsif atticSurface.outsideBoundaryCondition == "Surface"

          #get space of matched surface and see if it is also an attic
          next if atticSurface.adjacentSurface.empty?
          adjacentSurface = atticSurface.adjacentSurface.get
          next if adjacentSurface.space.empty?
          adjacentSurfaceSpace =  adjacentSurface.space.get

          if atticSpaces.include? adjacentSurfaceSpace and atticSpaces.include? atticSpace
            atticSurfacesOtherAtticDemising[atticSurface] = construction
          else
            # store starting values
            startingRvaluesAtticInterior << r_value_ip
            atticSurfacesInterior[atticSurface] = construction
            interiorAtticSurfaceInSpace = true #this is to confirm that space has at least one interior surface flagged as an attic
          end

        else
          runner.registerWarning("Can't infer use case for attic surface with an outside boundary condition of #{atticSurface.outsideBoundaryCondition}.")
        end

      end #end of atticSurfaces.each do

      # warning message for each space that has mix of attic and non attic constructions
      runner.registerWarning("#{atticSpace.name} has surfaces with a mix of attic and non attic constructions which may produce unexpected results. The following surfaces use constructions not tagged as attic and will not be altered: #{surfacesWithNonAtticConstructions.sort.join(",")}.")

      # confirm that all spaces have at least one or more surface of both exterior attic and interior attic
      if not interiorAtticSurfaceInSpace
        runner.registerWarning("#{atticSpace.name} has at least one exterior attic surface but does not have an interior attic surface. Please confirm that this space is intended to be an attic and update the constructions used.")
      end

      # see if attic is part of floor area and/or if it has people in it
      if atticSpace.partofTotalFloorArea
        runner.registerWarning("#{atticSpace.name} is part of the floor area. That is not typical for an attic.")
      end
      if atticSpace.people.size > 0
        runner.registerWarning("#{atticSpace.name} has people. That is not typical for an attic.")
      end

    end # end of atticSpaces.each do

    # hash to look for classification conflicts in attic constructions
    atticConstructionLog = {}

    # test attic constructions and identify conflicts
    # conflict resolution order (insulation,sri,nothing-for demising)
    atticSurfacesInterior.each do |surface,construction|

      next if atticConstructionLog[construction] == "atticSurfacesInterior"
      conductivity_ip = atticConstructions[construction]["conductivity_ip"]

      # test construction against rules
      ruleSet = rulesHash["#{climateZoneNumber} Attic"]
      if conductivity_ip > ruleSet["conductivity_ip"]
        atticConstructions[construction] = {"conductivity_ip" => conductivity_ip,"sri" => "NA","transmittance_ip_rule" => ruleSet["conductivity_ip"],"sri_rule" => "NA","classification" => "atticSurfacesInterior"}
      else
        # delete const from main hash
        atticConstructions.delete(construction)
      end
      atticConstructionLog[construction] = "atticSurfacesInterior" #pass in construction object and the type of rule it was tested against

    end

    atticSurfacesExteriorExposed.each do |surface,construction|

      next if atticConstructionLog[construction] == "atticSurfacesExteriorExposed"
      sri = atticConstructions[construction]["sri"]

      # warn user if construction used on attic interior surface
      if atticConstructionLog[construction] == "atticSurfacesInterior"
        runner.registerWarning("#{surface.name} appears to be an exterior surface but uses a construction #{construction.name} that is also used on interior attic surfaces. The construction was classified and tested as an insulated interior attic construction. You may see unexpected results.")
        next
      end

      # test construction against rules
      ruleSet = rulesHash["#{climateZoneNumber} Attic"]
      if sri < ruleSet["sri"]
        atticConstructions[construction] = {"conductivity_ip" => "NA","sri" => sri,"transmittance_ip_rule" => "NA","sri_rule" => ruleSet["sri"],"classification" => "atticSurfacesExteriorExposed"}
      else
        # delete const from main hash
        atticConstructions.delete(construction)
      end
      atticConstructionLog[construction] = "atticSurfacesExteriorExposed" #pass in construction object and the type of rule it was tested against

    end

    atticSurfacesOtherAtticDemising.each do |k,construction|

      next if atticConstructionLog[construction] == "atticSurfacesOtherAtticDemising"
      sri = atticConstructions[construction]["sri"]

      # warn user if construction used on attic interior surface
      if atticConstructionLog[construction] == "atticSurfacesInterior"
        runner.registerWarning("#{surface.name} appears to be an exterior surface but uses a construction #{construction.name} that is also used on interior attic surfaces. The construction was classified and tested as an insulated interior attic construction. You may see unexpected results.")
        next
      elsif atticConstructionLog[construction] == "atticSurfacesExteriorExposed"
        runner.registerWarning("#{surface.name} appears to be an surface between two attic spaces uses a construction #{construction.name} that is also used on exterior attic surfaces. The construction was classified and tested as an insulated interior attic construction. You may see unexpected results.")
        next
      end

      # delete const from main hash.
      atticConstructions.delete(construction)

      # No rule test needed for demising.
      atticConstructionLog[construction] = "atticSurfacesOtherAtticDemising" #pass in construction object and the type of rule it was tested against

    end

    # delete constructions from hash that are non used on roof attic surfaces, but are exterior exposed
     atticSurfacesExteriorExposedNonRoof.each do |surface,construction|
       if atticSurfacesExteriorExposed.has_value? construction #make sure I'm checking for value not key
         runner.registerWarning("#{surface.name} is a non-roof surface but uses a construction that the measure is treating as an exterior attic roof. Having this associated with a non-roof surface may increase affected area of SRI improvements.")
       else
         atticConstructions.delete(construction)
       end
     end

    # alter constructions and add lcc
    constructionsToChange = ieadConstructions.sort + metalConstructions.sort + atticConstructions.sort
    constructionsToChange.each do |construction,hash|

      #gather insulation inputs
      if not hash["transmittance_ip_rule"] == "NA"

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
        minThermalResistance = OpenStudio::convert(1,"ft^2*h*R/Btu","m^2*K/W").get
        inferredInsulationLayer = OsLib_Constructions.inferInsulationLayer(construction,minThermalResistance)
        rvalue_si_deficiency = r_value_si_target - r_value_si_starting

        # add lcc for insulation
        lcc_mat_insulation = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat_Insulation - #{construction.name}", construction, material_cost_insulation_increase_si, "CostPerArea", "Construction", expected_life, years_until_costs_start)
        lcc_mat_insulation_value = lcc_mat_insulation.get.totalCost
        running_cost_insulation += lcc_mat_insulation_value

        # adjust existing material or add new one
        if inferredInsulationLayer["insulationFound"] #if insulation layer was found

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

      end # end if not hash[transmittance_ip_rule] == "NA"

      #gather sri inputs
      if hash["sri_rule"] == 78.0 and hash["sri_rule"] > hash["sri"]

        #hard assign material properies that will result in an SRI of 78
        setConstructionSurfaceProperties_Inputs = {
            "thermalAbsorptance" => 0.86,
            "solarAbsorptance" => 1 - 0.65,
        }

        #alter surface properties (construction,roughness,thermalAbsorptance, solarAbsorptance,visibleAbsorptance)
        surfaceProperties = OsLib_Constructions.setConstructionSurfaceProperties(construction,setConstructionSurfaceProperties_Inputs)
        sri = OsLib_Constructions.getConstructionSRI(construction)

        # add lcc for SRI
        lcc_mat_sri = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat_SRI - #{construction.name}", construction, material_cost_sri_increase_si, "CostPerArea", "Construction", expected_life, years_until_costs_start)
        lcc_mat_sri_value = lcc_mat_sri.get.totalCost
        running_cost_sri += lcc_mat_sri_value

        #add to area counter
        sri_affected_area += construction.getNetArea

        # report performance and cost change for material, or area
        runner.registerInfo("The Solar Reflectance Index (SRI) of #{construction.name} has been increased from #{OpenStudio::toNeatString(hash["sri"],0,true)} to #{OpenStudio::toNeatString(sri,0,true)} for a cost of $#{OpenStudio::toNeatString(lcc_mat_sri_value,0,true)}. Affected area is #{OpenStudio::toNeatString(OpenStudio::convert(construction.getNetArea,"m^2","ft^2").get,0,true)} (ft^2)")

      end

    end

    # populate AEDG tip keys
    aedgTips = []

    if ieadFlag
      aedgTips.push("EN01","EN02","EN17","EN19","EN21","EN22")
    end
    if atticFlag
      aedgTips.push("EN01","EN03","EN17","EN19","EN20","EN21")
    end
    if metalFlag
      aedgTips.push("EN01","EN04","EN17","EN19","EN21")
    end

    # create not applicable of no constructions were tagged to change
    # if someone had a model with only attic floors and no attic ceilings current logic would flag as not applicable, but a warning would be issued alerting them of the issue (attic surface being used outside of attic space)
    if aedgTips.size == 0
      runner.registerAsNotApplicable("No surfaces use constructions tagged as a roof type recognized by this measure. No roofs were altered.")
      return true
    end

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips("SmMdOff",aedgTips.uniq.sort,runner)
    if not aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    #reporting initial condition of model
    startingRvalue = startingRvaluesExtRoof + startingRvaluesAtticInterior #adding non attic and attic values together

    runner.registerInitialCondition("Starting R-values for constructions intended for insulated roof surfaces range from #{OpenStudio::toNeatString(startingRvalue.min,2,true)} to #{OpenStudio::toNeatString(startingRvalue.max,2,true)}(ft^2*h*R/Btu). Starting Solar Reflectance Index (SRI) for constructions intended for exterior roof surfaces range from #{OpenStudio::toNeatString(startingSriExtRoof.min,0,true)} to #{OpenStudio::toNeatString(startingSriExtRoof.max,0,true)}.")

    #reporting final condition of model
    insulation_affected_area_ip = OpenStudio::convert(insulation_affected_area,"m^2","ft^2").get
    sri_affected_area_ip = OpenStudio::convert(sri_affected_area,"m^2","ft^2").get
    runner.registerFinalCondition("#{OpenStudio::toNeatString(insulation_affected_area_ip,0,true)}(ft^2) of constructions intended for roof surfaces had insulation enhanced at a cost of $#{OpenStudio::toNeatString(running_cost_insulation,0,true)}. #{OpenStudio::toNeatString(sri_affected_area_ip,0,true)}(ft^2) of constructions intended for roof surfaces had the Solar Reflectance Index (SRI) enhanced at a cost of $#{OpenStudio::toNeatString(running_cost_sri,0,true)}. #{aedgTipsLong}")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AedgSmallToMediumOfficeRoofConstruction.new.registerWithApplication