#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"
require "#{File.dirname(__FILE__)}/resources/OsLib_Constructions"
require "#{File.dirname(__FILE__)}/resources/OsLib_Geometry"
require "#{File.dirname(__FILE__)}/resources/OsLib_HelperMethods"
require "#{File.dirname(__FILE__)}/resources/OsLib_LightingAndEquipment"

#start the measure
class AedgSmallToMediumOfficeFenestrationAndDaylightingControls < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AedgSmallToMediumOfficeFenestrationAndDaylightingControls"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for cost of cost_daylight_glazing
    cost_daylight_glazing = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cost_daylight_glazing",true)
    cost_daylight_glazing.setDisplayName("Cost per Area for Proposed Daylighting Window Constructions ($/ft^2).")
    cost_daylight_glazing.setDefaultValue(0.0)
    args << cost_daylight_glazing

    #make an argument for cost of cost_view_glazing
    cost_view_glazing = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cost_view_glazing",true)
    cost_view_glazing.setDisplayName("Cost per Area for Proposed View Window Constructions ($/ft^2).")
    cost_view_glazing.setDefaultValue(0.0)
    args << cost_view_glazing

    #make an argument for cost of cost_skylight
    cost_skylight = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cost_skylight",true)
    cost_skylight.setDisplayName("Cost per Area for Proposed Skylight Construction ($/ft^2).")
    cost_skylight.setDefaultValue(0.0)
    args << cost_skylight
    
    #make an argument for cost of cost_shading_surface (todo - later would be nice to change to linear)
    cost_shading_surface = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cost_shading_surface",true)
    cost_shading_surface.setDisplayName("Cost per Area for Proposed Exterior Shading Surface Construction ($/ft^2).")
    cost_shading_surface.setDefaultValue(0.0)
    args << cost_shading_surface

    #make an argument for cost of cost_light_shelf (todo - later would be nice to change to linear)
    cost_light_shelf = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cost_light_shelf",true)
    cost_light_shelf.setDisplayName("Cost per Area for Proposed Light Shelf Construction ($/ft^2).")
    cost_light_shelf.setDefaultValue(0.0)
    args << cost_light_shelf

    # todo - eventually would be nice to cost each sensor (but wouldn't larger rooms really have more than one sensor)

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
    cost_daylight_glazing = runner.getDoubleArgumentValue("cost_daylight_glazing",user_arguments)
    cost_view_glazing = runner.getDoubleArgumentValue("cost_daylight_glazing",user_arguments)
    cost_skylight = runner.getDoubleArgumentValue("cost_skylight",user_arguments)
    cost_shading_surface = runner.getDoubleArgumentValue("cost_shading_surface",user_arguments)
    cost_light_shelf = runner.getDoubleArgumentValue("cost_light_shelf",user_arguments)

    # validate cost inputs are not less than 0
    argumentHash = {
        "cost for daylight glazing" => cost_daylight_glazing,
        "cost for view glazing" => cost_view_glazing,
        "cost for cost_skylight glazing" => cost_skylight,
        "cost for shading surface" => cost_shading_surface,
        "cost for light shelf" => cost_light_shelf,
    }
    #check arguments for reasonableness (runner, min, max, argumentArray)
    checkDoubleArguments = OsLib_HelperMethods.checkDoubleArguments(runner,0,nil,argumentHash)
    if not checkDoubleArguments
      return false
    end

    # get climate zone
    climateZoneNumber = OsLib_AedgMeasures.getClimateZoneNumber(model,runner)

    # add message if climate zone can't be found
    if climateZoneNumber == false
      return false
    end

    # setup rules view fenestration (from Chapter 4 and Table 5-3)
    viewFenestrationRules = [] # climate zone, framing material, Ufactor(ip), SHGC, VT, WWR-min, WWR-max, overhang
    viewFenestrationRules << ["1","NonmetalFraming",0.56,0.25,0.3,0.2,0.4,0.5]
    viewFenestrationRules << ["2","NonmetalFraming",0.45,0.25,0.3,0.2,0.4,0.5]
    viewFenestrationRules << ["3","NonmetalFraming",0.41,0.25,0.3,0.2,0.4,0.5]
    viewFenestrationRules << ["4","NonmetalFraming",0.38,0.26,0.3,0.2,0.4,0.5]
    viewFenestrationRules << ["5","NonmetalFraming",0.35,0.26,0.3,0.2,0.4,0.5]
    viewFenestrationRules << ["6","NonmetalFraming",0.35,0.35,0.3,0.2,0.4,0.0]
    viewFenestrationRules << ["7","NonmetalFraming",0.33,0.40,0.3,0.2,0.4,0.0]
    viewFenestrationRules << ["8","NonmetalFraming",0.25,0.40,0.3,0.2,0.4,0.0]
    viewFenestrationRules << ["1","MetalFraming",0.65,0.25,0.3,0.2,0.4,0.5]
    viewFenestrationRules << ["2","MetalFraming",0.65,0.25,0.3,0.2,0.4,0.5]
    viewFenestrationRules << ["3","MetalFraming",0.60,0.25,0.3,0.2,0.4,0.5]
    viewFenestrationRules << ["4","MetalFraming",0.39,0.38,0.3,0.2,0.4,0.5]
    viewFenestrationRules << ["5","MetalFraming",0.39,0.38,0.3,0.2,0.4,0.5]
    viewFenestrationRules << ["6","MetalFraming",0.39,0.38,0.3,0.2,0.4,0.0,0]
    viewFenestrationRules << ["7","MetalFraming",0.34,0.40,0.3,0.2,0.4,0.0]
    viewFenestrationRules << ["8","MetalFraming",0.34,0.40,0.3,0.2,0.4,0.0]
    #make rule hash for cleaner code
    viewFenestrationRulesHash = {}
    viewFenestrationRules.each do |rule|
      viewFenestrationRulesHash["#{rule[0]} #{rule[1]}"] = {"uFactor" => rule[2],"sHGC" => rule[3],"vT" => rule[4],"WWR-min" => rule[5],"WWR-max" => rule[6],"overhang" => rule[7]}
    end

    # setup rules daylighting fenestration and skylights (from Table 5-5)
    daylightFenestrationRules = [] # climate zone, Ufactor(ip), SHGC-NS, VT-NS, EA-daylight
    daylightFenestrationRules << ["1","LightShelf",0.97,0.58,0.7,0.08]
    daylightFenestrationRules << ["2","LightShelf",0.97,0.58,0.7,0.08]
    daylightFenestrationRules << ["3","LightShelf",0.97,0.58,0.7,0.08]
    daylightFenestrationRules << ["4","LightShelf",0.97,0.58,0.7,0.12]
    daylightFenestrationRules << ["5","LightShelf",0.97,0.58,0.7,0.12]
    daylightFenestrationRules << ["6","LightShelf",0.97,0.58,0.7,0.12]
    daylightFenestrationRules << ["7","LightShelf",0.97,0.58,0.7,0.12]
    daylightFenestrationRules << ["8","LightShelf",0.97,0.58,0.7,0.12]
    daylightFenestrationRules << ["1","NorthHigh",0.97,0.58,0.7,0.08]
    daylightFenestrationRules << ["2","NorthHigh",0.97,0.58,0.7,0.08]
    daylightFenestrationRules << ["3","NorthHigh",0.97,0.58,0.7,0.08]
    daylightFenestrationRules << ["4","NorthHigh",0.97,0.58,0.7,0.12]
    daylightFenestrationRules << ["5","NorthHigh",0.97,0.58,0.7,0.12]
    daylightFenestrationRules << ["6","NorthHigh",0.97,0.58,0.7,0.12]
    daylightFenestrationRules << ["7","NorthHigh",0.97,0.58,0.7,0.12]
    daylightFenestrationRules << ["8","NorthHigh",0.97,0.58,0.7,0.12]

    #make rule hash for cleaner code
    daylightFenestrationRulesHash = {}
    daylightFenestrationRules.each do |rule|
      daylightFenestrationRulesHash["#{rule[0]} #{rule[1]}"] = {"uFactor" => rule[2],"sHGC" => rule[3],"vT" => rule[4],"EA-daylight" => rule[5]}
    end

    # general notes
    # no skylights for office recommended, but I'll keep the code in here in case we want to ad in the future
    # no shading controls on east and west
    # Office AEDG and TSD doesn't specifically define angles for NS vs. EW, so I'll use the values below used for K12 AEDG

    # misc variables (some could become user arguments)
    southRangeStart = 150.0
    southRangeEnd = 210.0
    northRangeStart = 330.0
    northRangeEnd = 30.0
    sill = OpenStudio::convert(2.5,"ft","m").get
    header = OpenStudio::convert(1.0,"ft","m").get
    shadingProjectionFactor = 0.5
    lightShelfProjectionFactor = 1.0
    skylightSize = OpenStudio::convert(6.0,"ft","m").get
    daylightSensorHeight = OpenStudio::convert(3.0,"ft","m").get
    daylightMinOppositeWallClearance = OpenStudio::convert(2.0,"ft","m").get
    targetFcGeneralInstruction = OpenStudio::convert(46.45,"fc","lux").get # this value came out of the TSD models
    viewWindowFramingType = "MetalFraming"
    daylightingControlType = "Continuous"
    expected_life = 25
    years_until_costs_start = 0
    uFactorIpToSiConversion = OpenStudio::convert(1.0,"Btu/ft^2*h*R","W/m^2*K").get

    # create new constructions
    options = {"constructionName" => "AEDG-SmMdOff View Glazing North",
               "materialName" => "AEDG-SmMdOff View Glazing North-mat",
               "uFactor" => viewFenestrationRulesHash["#{climateZoneNumber} #{viewWindowFramingType}"]["uFactor"]*uFactorIpToSiConversion,
               "solarHeatGainCoef" => viewFenestrationRulesHash["#{climateZoneNumber} #{viewWindowFramingType}"]["sHGC"],
               "visibleTransmittance" => viewFenestrationRulesHash["#{climateZoneNumber} #{viewWindowFramingType}"]["vT"],}
    viewConstructionNorth = OsLib_Constructions.createConstructionWithSimpleGlazing(model, runner, options)

    options = {"constructionName" => "AEDG-SmMdOff View Glazing South",
               "materialName" => "AEDG-SmMdOff View Glazing South-mat",
               "uFactor" => viewFenestrationRulesHash["#{climateZoneNumber} #{viewWindowFramingType}"]["uFactor"]*uFactorIpToSiConversion,
               "solarHeatGainCoef" => viewFenestrationRulesHash["#{climateZoneNumber} #{viewWindowFramingType}"]["sHGC"],
               "visibleTransmittance" => viewFenestrationRulesHash["#{climateZoneNumber} #{viewWindowFramingType}"]["vT"]}
    viewConstructionSouth = OsLib_Constructions.createConstructionWithSimpleGlazing(model, runner, options)

    options = {"constructionName" => "AEDG-SmMdOff View Glazing EastWest",
               "materialName" => "AEDG-SmMdOff View Glazing EastWest-mat",
               "uFactor" => viewFenestrationRulesHash["#{climateZoneNumber} #{viewWindowFramingType}"]["uFactor"]*uFactorIpToSiConversion,
               "solarHeatGainCoef" => viewFenestrationRulesHash["#{climateZoneNumber} #{viewWindowFramingType}"]["sHGC"],
               "visibleTransmittance" => viewFenestrationRulesHash["#{climateZoneNumber} #{viewWindowFramingType}"]["vT"]}
    viewConstructionEastWest = OsLib_Constructions.createConstructionWithSimpleGlazing(model, runner, options)

    options = {"constructionName" => "AEDG-SmMdOff Daylight Glazing South",
               "materialName" => "AEDG-SmMdOff Daylight Glazing South-mat",
               "uFactor" => daylightFenestrationRulesHash["#{climateZoneNumber} LightShelf"]["uFactor"]*uFactorIpToSiConversion,
               "solarHeatGainCoef" => daylightFenestrationRulesHash["#{climateZoneNumber} LightShelf"]["sHGC"],
               "visibleTransmittance" => daylightFenestrationRulesHash["#{climateZoneNumber} LightShelf"]["vT"]}
    daylightConstructionSouth = OsLib_Constructions.createConstructionWithSimpleGlazing(model, runner, options)

    options = {"constructionName" => "AEDG-SmMdOff Daylight Glazing North",
               "materialName" => "AEDG-SmMdOff Daylight Glazing North-mat",
               "uFactor" => daylightFenestrationRulesHash["#{climateZoneNumber} NorthHigh"]["uFactor"]*uFactorIpToSiConversion,
               "solarHeatGainCoef" => daylightFenestrationRulesHash["#{climateZoneNumber} NorthHigh"]["sHGC"],
               "visibleTransmittance" => daylightFenestrationRulesHash["#{climateZoneNumber} NorthHigh"]["vT"]}
    daylightConstructionNorth = OsLib_Constructions.createConstructionWithSimpleGlazing(model, runner, options)

    #options = {"constructionName" => "AEDG-SmMdOff Skylight",
    #           "materialName" => "AEDG-SmMdOff Daylight Skylight-mat",
    #           "uFactor" => daylightFenestrationRulesHash["#{climateZoneNumber} Skylight"]["uFactor"]*uFactorIpToSiConversion,
    #           "solarHeatGainCoef" => daylightFenestrationRulesHash["#{climateZoneNumber} Skylight"]["sHGC"],
    #           "visibleTransmittance" => daylightFenestrationRulesHash["#{climateZoneNumber} Skylight"]["vT"]}
    #skylightConstruction = OsLib_Constructions.createConstructionWithSimpleGlazing(model, runner, options)

    # light shelf construction
    lightShelfMaterial = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    lightShelfMaterial.setName("AEDG-SmMdOff LightShelf-mat")
    lightShelfMaterial.setThermalAbsorptance(0.4)
    lightShelfMaterial.setSolarAbsorptance(0.4)
    lightShelfMaterial.setVisibleAbsorptance(0.3)
    lightShelfMaterial.setRoughness("MediumSmooth")
    lightShelfMaterial.setSpecificHeat(100.0)
    lightShelfConstruction = OpenStudio::Model::Construction.new(model)
    lightShelfConstruction.setName("AEDG-SmMdOff LightShelf")
    lightShelfConstruction.insertLayer(0,lightShelfMaterial)
    runner.registerInfo("Created #{lightShelfConstruction.name} construction for light shelves. Visible absorptance is #{lightShelfMaterial.visibleAbsorptance}.")

    # exterior shading surface construction
    exteriorShadeMaterial = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    exteriorShadeMaterial.setName("AEDG-SmMdOff ExteriorShade-mat")
    exteriorShadeMaterial.setSpecificHeat(100.0)
    exteriorShadeConstruction = OpenStudio::Model::Construction.new(model)
    exteriorShadeConstruction.setName("AEDG-SmMdOff ExteriorShade")
    exteriorShadeConstruction.insertLayer(0,exteriorShadeMaterial)
    runner.registerInfo("Created #{exteriorShadeConstruction.name} construction for exterior shading surfaces.")

    # add cost to new constructions
    lcc_mat_view_north = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat - #{viewConstructionNorth.name}", viewConstructionNorth, OpenStudio::convert(cost_view_glazing,"ft^2","m^2").get, "CostPerArea", "Construction", expected_life, years_until_costs_start)
    lcc_mat_view_south = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat - #{viewConstructionSouth.name}", viewConstructionSouth, OpenStudio::convert(cost_view_glazing,"ft^2","m^2").get, "CostPerArea", "Construction", expected_life, years_until_costs_start)
    lcc_mat_view_eastWest = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat - #{viewConstructionEastWest.name}", viewConstructionEastWest, OpenStudio::convert(cost_view_glazing,"ft^2","m^2").get, "CostPerArea", "Construction", expected_life, years_until_costs_start)
    lcc_mat_daylight_glazing_north = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat - #{daylightConstructionNorth.name}", daylightConstructionNorth, OpenStudio::convert(cost_daylight_glazing,"ft^2","m^2").get, "CostPerArea", "Construction", expected_life, years_until_costs_start)
    lcc_mat_daylight_glazing_south = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat - #{daylightConstructionSouth.name}", daylightConstructionSouth, OpenStudio::convert(cost_daylight_glazing,"ft^2","m^2").get, "CostPerArea", "Construction", expected_life, years_until_costs_start)
    # lcc_mat_skylight = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat - #{skylightConstruction.name}", skylightConstruction, OpenStudio::convert(cost_skylight,"ft^2","m^2").get, "CostPerArea", "Construction", expected_life, years_until_costs_start)

    # create blind material
    shadingMaterial = OpenStudio::Model::Blind.new(model)

    # create shading control object
    shadingControl = OpenStudio::Model::ShadingControl.new(shadingMaterial)
    runner.registerInfo("Adding shading control object to connect to east and west view windows.")

    # get window to wall ratio for initial condition
    initialGrossWWR = OsLib_Geometry.getExteriorWindowToWallRatio(model.getSpaces)
    spacesPartOfFloorArea = []
    model.getSpaces.each do |space|
      if space.partofTotalFloorArea
        spacesPartOfFloorArea << space
      end
    end
    initialNetWWR = OsLib_Geometry.getExteriorWindowToWallRatio(spacesPartOfFloorArea)

    # store original cost of construction objects for use in final condition.
    initialEnvelopeCost = OsLib_Constructions.getTotalCostOfSelectedConstructions(model.getConstructions)

    # initial condition of model
    if spacesPartOfFloorArea.size < model.getSpaces.size
      runner.registerInitialCondition("The building started with a gross window to wall ratio of #{OpenStudio::toNeatString(initialGrossWWR,2,true)}, and a net window to wall ratio (including only spaces counted in building area) of  #{OpenStudio::toNeatString(initialNetWWR,2,true)}.")
    else
      runner.registerInitialCondition("The building started with a  window to wall ratio of #{OpenStudio::toNeatString(initialGrossWWR,2,true)}.")
    end

    # remove all fenestration in the model except for opaque doors
    runner.registerInfo("Removing existing translucent exterior surfaces.")
    model.getSubSurfaces.each do |subSurface|
      unless subSurface.subSurfaceType == "Door" or subSurface.subSurfaceType == "OverheadDoor"
        next if not subSurface.outsideBoundaryCondition == "Outdoors" #don't need to mess with interior fenestration
        subSurface.remove
      end
    end

    # remove existing daylight control objects
    if model.getDaylightingControls.size > 0
      runner.registerInfo("Removing #{model.getDaylightingControls.size} existing daylight control objects.")
      model.getDaylightingControls.each do |daylightingControl|
        daylightingControl.remove
      end
    end

    # split doors to their own base surfaces
    model.getSurfaces.each do |surface|
      subSurfaces = surface.splitSurfaceForSubSurfaces
    end

    # put cap on wwr to prevent odd windows at deep spaces with little exterior exposure.
    wwrCapValue = 0.45
    wwrCapFlag = 0

    # info messages
    runner.registerInfo("Adding new fenestration.")
    runner.registerInfo("Adding new daylighting control objects.")

    # loop through spaces adding appropriate fenestration
    # this will contain a sub loop through surfaces. in that sub loop test for non full height walls, add only daylight windows there.
    model.getThermalZones.each do |thermalZone|

      # hash of spaces with data necessary to place daylighting control points and to. [floor area, north exterior wall area, south exterior wall area, north daylight wwr, south daylight wwr, skylight ratio]
      zoneSpacesHash = {}

      thermalZone.spaces.each do |space|

        # only add any fenestration if space is part of floor area
        next if not space.partofTotalFloorArea

        # create array of z values for floor
        floorArray = []
        space.surfaces.each do |surface|
          next unless surface.surfaceType == "Floor"
          floorArray << surface
        end

        # run helper method to get array of z values for floors
        floorSurfacesZValueArray = OsLib_Geometry.getSurfaceZValues(floorArray)

        # create array of z values for floor
        ceilingArray = []
        space.surfaces.each do |surface|
          next unless surface.surfaceType == "RoofCeiling"
          ceilingArray << surface
        end

        # run helper method to get array of z values for ceilings
        ceilingSurfacesZValueArray = OsLib_Geometry.getSurfaceZValues(ceilingArray)

        # misc space counters and
        floorArea = space.floorArea
        exteriorWallAreaEW = 0 # exterior walls that only get view windows
        exteriorWallAreaNSView = 0 # exterior walls view only
        exteriorWallAreaNDaylight = 0 # exterior walls that receive daylighting
        exteriorWallAreaSDaylight = 0 # exterior walls that receive daylighting

        # flag for skylights
        addSkylights = false

        # first of two loops through space surfaces. This one is just to get floor and north or south exterior wall area.
        space.surfaces.each do |surface|

          # stop of not exterior wall
          next if not surface.surfaceType == "Wall"
          next if not surface.outsideBoundaryCondition == "Outdoors"

          # get the absoluteAzimuth for the surface so we can categorize it
          absoluteAzimuth =  OpenStudio::convert(surface.azimuth,"rad","deg").get + surface.space.get.directionofRelativeNorth + model.getBuilding.northAxis
          until absoluteAzimuth < 360.0
            absoluteAzimuth = absoluteAzimuth - 360.0
          end

          # flag to see if surface not to ground
          surfaceToFloor = false
          surfaceToCeiling = false

          # check if surface goes to floor or ceiling (if false then don't add view windows)
          minSurfaceZValue = OsLib_Geometry.getSurfaceZValues([surface]).sort.first # this expects an array of surfaces
          if floorSurfacesZValueArray.include? minSurfaceZValue # not sure if will hit rounding issue
            surfaceToFloor = true
          end
          maxSurfaceZValue = OsLib_Geometry.getSurfaceZValues([surface]).sort.last # this expects an array of surfaces
          if ceilingSurfacesZValueArray.include? maxSurfaceZValue # not sure if will hit rounding issue
            surfaceToCeiling = true
          end

          # add to exterior wall counter if north or south
          if northRangeEnd < absoluteAzimuth and absoluteAzimuth < southRangeStart  # East exterior walls
            if surfaceToFloor then exteriorWallAreaEW += surface.grossArea end
          elsif southRangeStart <= absoluteAzimuth and absoluteAzimuth <= southRangeEnd # South exterior walls
            if surfaceToFloor then exteriorWallAreaNSView += surface.grossArea end
            if surfaceToCeiling then exteriorWallAreaSDaylight += surface.grossArea end
          elsif southRangeEnd < absoluteAzimuth and absoluteAzimuth < northRangeStart # West exterior walls
            if surfaceToFloor then  exteriorWallAreaEW += surface.grossArea end
          else # North exterior walls
            if surfaceToFloor then exteriorWallAreaNSView += surface.grossArea end
            if surfaceToCeiling then exteriorWallAreaNDaylight += surface.grossArea end
          end

        end # end of initial space.surfaces.each do

        # get effective aperture values from rules
        eaNorth = (daylightFenestrationRulesHash["#{climateZoneNumber} NorthHigh"]["EA-daylight"])
        eaSouth = (daylightFenestrationRulesHash["#{climateZoneNumber} LightShelf"]["EA-daylight"])

        # add north and south dayilght areas together
        exteriorWallAreaNSDaylight = exteriorWallAreaNDaylight + exteriorWallAreaSDaylight

        # calculate target WWR rations needed to meet rules for FFR and DFR from rules
        if exteriorWallAreaEW > 0.0 then viewWwrEW = viewFenestrationRulesHash["#{climateZoneNumber} #{viewWindowFramingType}"]["WWR-min"] else viewWwrEW = 0.0 end
        if exteriorWallAreaNSView > 0.0 then viewWwrNS = viewFenestrationRulesHash["#{climateZoneNumber} #{viewWindowFramingType}"]["WWR-min"] else viewWwrNS = 0.0 end
        if exteriorWallAreaNSDaylight > 0.0 then daylightWwrN = floorArea*eaNorth/exteriorWallAreaNSDaylight*daylightFenestrationRulesHash["#{climateZoneNumber} NorthHigh"]["vT"] else daylightWwrN = 0.0 end
        if exteriorWallAreaNSDaylight > 0.0 then daylightWwrS = floorArea*eaSouth/exteriorWallAreaNSDaylight*daylightFenestrationRulesHash["#{climateZoneNumber} LightShelf"]["vT"] else daylightWwrS = 0.0 end

        if exteriorWallAreaNSView == 0.0 and exteriorWallAreaEW > 0.0 # only add east and west view windows when no south or north options exist
          if viewWwrEW > wwrCapValue
            viewWwrEW = wwrCapValue
            wwrCapFlag += 1
          end
        else
          viewWwrEW = 0.0
        end
        if viewWwrNS > wwrCapValue
          viewWwrNS = wwrCapValue
          wwrCapFlag += 1
        end
        if daylightWwrN > wwrCapValue
          daylightWwrN = wwrCapValue
          wwrCapFlag += 1
        end
        if daylightWwrS > wwrCapValue
          daylightWwrS = wwrCapValue
          wwrCapFlag += 1
        end

        #hash to hold daylight windows for use in placing sensor
        daylightNorthHash = {}
        daylightSouthHash = {}

        # second loop through surfaces to create fenestration
        space.surfaces.each do |surface|

          # only care about exterior surfaces
          next if not surface.outsideBoundaryCondition == "Outdoors"

          if surface.surfaceType == "Wall"

            # flag to see if surface not to ground
            surfaceToFloor = false
            surfaceToCeiling = false

            # check if surface goes to floor or ceiling (if false then don't add view windows)
            minSurfaceZValue = OsLib_Geometry.getSurfaceZValues([surface]).sort.first # this expects an array of surfaces
            if floorSurfacesZValueArray.include? minSurfaceZValue # not sure if will hit rounding issue
              surfaceToFloor = true
            end
            maxSurfaceZValue = OsLib_Geometry.getSurfaceZValues([surface]).sort.last # this expects an array of surfaces
            if ceilingSurfacesZValueArray.include? maxSurfaceZValue # not sure if will hit rounding issue
              surfaceToCeiling = true
            end

            # don't add any windows if this surface doesn't touch floor or ceiling
            #next if surfaceToFloor == false and surfaceToCeiling == false

            # get the absoluteAzimuth for the surface so we can categorize it
            absoluteAzimuth = OpenStudio::convert(surface.azimuth,"rad","deg").get + surface.space.get.directionofRelativeNorth + model.getBuilding.northAxis

            # flags to add view or daylight glazing. This is affected by the space type or the surface properties
            addViewGlazing = true
            addDaylightGlazing = true

            # geometry based tests
            if surfaceToFloor == false
              addViewGlazing = false
            end
            if surfaceToCeiling == false
              addDaylightGlazing = false
            end

            # adjust method variables based on flags
            if addViewGlazing == false
              viewWwrEW_s = 0.0
              viewWwrNS_s = 0.0
            else
              viewWwrEW_s = viewWwrEW
              viewWwrNS_s = viewWwrNS
            end
            if addDaylightGlazing == false
              daylightWwrS_s = 0.0
              daylightWwrN_s = 0.0
            else
              daylightWwrS_s = daylightWwrS
              daylightWwrN_s = daylightWwrN
            end

            # see if surface has any subSurfaces. this is to elimenate warning on surface with door, as those have been split and a window isn't expected
            noDoorInSurface = true
            if surface.subSurfaces.size > 0 then noDoorInSurface = false end

            # apply wwr based on surface orientation category and other inputs
            # applyViewAndDaylightingGlassRatios(viewGlassToWallRatio,daylightingGlassToWallRatio,desiredViewGlassSillHeight,desiredDaylightingGlassHeaderHeight,exteriorShadingProjectionFactor,interiorShelfProjectionFactor,viewGlassConstruction,daylightingGlassConstruction)
            if northRangeEnd < absoluteAzimuth and absoluteAzimuth < southRangeStart  # East exterior walls
              vector = surface.applyViewAndDaylightingGlassRatios(viewWwrEW_s,0.0,sill,header,shadingProjectionFactor,0.0,viewConstructionEastWest.to_ConstructionBase,OpenStudio::Model::OptionalConstructionBase.new)  # use OpenStudio::Model::OptionalConstructionBase.new  when you don't want to pass in a construction
              if not vector[0].nil?
                vector[0].setShadingControl(shadingControl)
              elsif viewWwrEW_s > 0 and  noDoorInSurface
                runner.registerWarning("The requested view window to wall ratio of #{OpenStudio::toNeatString(viewWwrEW_s,2,true)} could not be set for #{surface.name}.")
              end
              vector.each do |subSurface|
                if subSurface.construction.get == viewConstructionEastWest
                  subSurface.shadingSurfaceGroups[0].shadingSurfaces[0].setConstruction(exteriorShadeConstruction) # setting shading surface construction
                end
              end
            elsif southRangeStart <= absoluteAzimuth and absoluteAzimuth <= southRangeEnd # South exterior walls
              vector = surface.applyViewAndDaylightingGlassRatios(viewWwrNS_s,daylightWwrS_s,sill,header,shadingProjectionFactor,lightShelfProjectionFactor,viewConstructionSouth.to_ConstructionBase,daylightConstructionSouth.to_ConstructionBase)
              if vector[0].nil? and noDoorInSurface and (viewWwrNS_s > 0 or daylightWwrS_s > 0)
                runner.registerWarning("The requested view and daylight window to wall ratio of #{OpenStudio::toNeatString(viewWwrNS_s,2,true)} and #{OpenStudio::toNeatString(daylightWwrS_s,2,true)} could not be set for #{surface.name}.")
              end
              vector.each do |subSurface|
                if subSurface.construction.get == viewConstructionSouth
                  subSurface.shadingSurfaceGroups[0].shadingSurfaces[0].setConstruction(exteriorShadeConstruction) # setting shading surface construction
                elsif subSurface.construction.get == daylightConstructionSouth
                  subSurface.daylightingDeviceShelf.get.insideShelf.get.setConstruction(lightShelfConstruction) # setting light shelf construction
                  daylightSouthHash[vector.last] = vector.last.grossArea # push the daylight window to array for use later on
                end
              end
            elsif southRangeEnd < absoluteAzimuth and absoluteAzimuth < northRangeStart # West exterior walls
              vector = surface.applyViewAndDaylightingGlassRatios(viewWwrEW_s,0.0,sill,header,shadingProjectionFactor,0.0,viewConstructionEastWest.to_ConstructionBase,OpenStudio::Model::OptionalConstructionBase.new)  # use OpenStudio::Model::OptionalConstructionBase.new  when you don't want to pass in a construction
              if not vector[0].nil?
                vector[0].setShadingControl(shadingControl)
              elsif viewWwrEW_s > 0 and noDoorInSurface
                runner.registerWarning("The requested view window to wall ratio of #{OpenStudio::toNeatString(viewWwrEW_s,2,true)} could not be set for #{surface.name}.")
              end
              vector.each do |subSurface|
                if subSurface.construction.get == viewConstructionEastWest
                  subSurface.shadingSurfaceGroups[0].shadingSurfaces[0].setConstruction(exteriorShadeConstruction) # setting shading surface construction
                end
              end
            else # North exterior walls
              vector = surface.applyViewAndDaylightingGlassRatios(viewWwrNS_s,daylightWwrN_s,sill,header,0.0,0.0,viewConstructionNorth.to_ConstructionBase,daylightConstructionNorth.to_ConstructionBase)
              if vector[0].nil? and  noDoorInSurface and (viewWwrNS_s > 0 or daylightWwrS_s > 0)
                runner.registerWarning("The requested view and daylight window to wall ratio of #{OpenStudio::toNeatString(viewWwrNS_s,2,true)} and #{OpenStudio::toNeatString(daylightWwrS_s,2,true)} could not be set for #{surface.name}.")
              end
              vector.each do |subSurface|
                if subSurface.construction.get == daylightConstructionNorth
                  daylightNorthHash[vector.last] = vector.last.grossArea # push the daylight window to array for use later on
                end
              end
            end # end if northRangeEnd < absoluteAzimuth and absoluteAzimuth < southRangeStart

           elsif surface.surfaceType == "RoofCeiling"

          else
            # no more action required for this surface
          end # end of if surface.surfaceType

        end # end of space.surfaces.each do

        # add skylights if required
        if addSkylights

          # making vector to create pattern
          spaces = OpenStudio::Model::SpaceVector.new
          spaces << space

          # making pattern
          ratio = daylightFenestrationRulesHash["#{climateZoneNumber} Skylight"]["dFRmin"]
          pattern = OpenStudio::Model::generateSkylightPattern(spaces,spaces[0].directionofRelativeNorth,ratio, skylightSize, skylightSize) # ratio, x value, y value

          # applying skylight pattern
          skylights = OpenStudio::Model::applySkylightPattern(pattern, spaces, OpenStudio::Model::OptionalConstructionBase.new)
          runner.registerInfo("Adding #{skylights.size} skylights to #{space.name}")

          # create construction set for space if it doesn't exist, and add skylight construction.
          defaultSubSurfaceConstructions = OpenStudio::Model::DefaultSubSurfaceConstructions.new(model)
          defaultSubSurfaceConstructions.setSkylightConstruction(skylightConstruction)
          if space.defaultConstructionSet.empty?
            defaultConstructionSet = OpenStudio::Model::DefaultConstructionSet.new(model)
            defaultConstructionSet.setDefaultExteriorSubSurfaceConstructions(defaultSubSurfaceConstructions)
            space.setDefaultConstructionSet(defaultConstructionSet)
          else
            defaultConstructionSet = space.defaultConstructionSet.get
            defaultConstructionSet.setDefaultExteriorSubSurfaceConstructions(defaultSubSurfaceConstructions)
          end

        end # end of addSkylights

        # dont' add to hash if no daylighting in space
        next if addSkylights == false and exteriorWallAreaNDaylight == 0 and exteriorWallAreaSDaylight == 0

        # go back and get north and south interior walls for spaces that also have exterior walls with daylight windows
        # this is specifically to address internal clerestory spaces like hallways
        space.surfaces.each do |surface|

          next if not surface.surfaceType == "Wall"
          next if surface.outsideBoundaryCondition == "Outdoors" #these have already been counted

          # get the absoluteAzimuth for the surface so we can categorize it
          absoluteAzimuth =  OpenStudio::convert(surface.azimuth,"rad","deg").get + surface.space.get.directionofRelativeNorth + model.getBuilding.northAxis
          until absoluteAzimuth < 360.0
            absoluteAzimuth = absoluteAzimuth - 360.0
          end

          # add to proper are if necessary
          if northRangeEnd < absoluteAzimuth and absoluteAzimuth < southRangeStart  # East exterior walls
            # do nothing
          elsif southRangeStart <= absoluteAzimuth and absoluteAzimuth <= southRangeEnd # South exterior walls
            if exteriorWallAreaSDaylight > 0 # only add interior surfaces if the starting value is greater than 0
              exteriorWallAreaSDaylight += surface.grossArea
            end
          elsif southRangeEnd < absoluteAzimuth and absoluteAzimuth < northRangeStart # West exterior walls
            # do nothing
          else # North exterior walls
            if exteriorWallAreaNDaylight > 0 # only add interior surfaces if the starting value is greater than 0
              exteriorWallAreaNDaylight += surface.grossArea
            end
          end # end if northRangeEnd < absoluteAzimuth and absoluteAzimuth < southRangeStart

        end # end of space.surfaces.each

        # populate space hash, and then
        spaceHash = {}
        spaceHash["floorArea"] = floorArea
        spaceHash["exteriorWallAreaNDaylight"] = exteriorWallAreaNDaylight
        spaceHash["exteriorWallAreaSDaylight"] = exteriorWallAreaSDaylight
        spaceHash["skylight"] = addSkylights # bool for this space if skylights should be added. Is only true if right space and if there is exterior roof
        spaceHash["thermalZone"] = space.thermalZone.get  # thermal zone not nil, because spaces are in a loop of thermal zones
        spaceHash["lightingPower"] = space.lightingPower # (W) not sure if it has luminaires, but I would expect it would
        spaceHash["daylightNorthHash"] = daylightNorthHash
        spaceHash["daylightSouthHash"] = daylightSouthHash
        spaceHash["spaceHeight"] = ceilingSurfacesZValueArray.max - floorSurfacesZValueArray.min

        # add spaceHash to zoneSpacesHash with space object as key
        zoneSpacesHash[space] = spaceHash

      end # end of thermalZone.getSpaces.each do

      zoneFloorArea = 0
      zoneDaylightWallArea = 0
      zoneSpaceDaylightFractionHash = {}
      zoneSkylightHash = {}

      # loop through space hash
      zoneSpacesHash.each do |space, hash|

        # populate sensor method default hash
        defaults = {
            "name" => "#{space.name} sensor",
            "space" => space,
            "position" => nil,
            "phiRotationAroundZAxis" => nil,
            "illuminanceSetpoint" => targetFcGeneralInstruction,
            "lightingControlType" => "1", # 1 = Continuous
            "minInputPowerFractionContinuous" => nil,
            "minOutputPowerFractionContinuous" => nil,
        }

        #calculate sensor position
        if hash["skylight"]
          # find center of space and add sensor
          position = OsLib_Geometry.createPointAtCenterOfFloor(model,space,daylightSensorHeight)

          # customize default sensor values as needed
          options = defaults
          options["position"] = position

          # add sensor
          if not position.nil?
            pri_light_sensor = OsLib_LightingAndEquipment.addDaylightSensor(model,options)
          else
            runner.registerWarning("Couldn't find good Sensor Location for #{space.name}. Did not add daylight sensor.")
          end
        else
          # grab a floor surface to use in createPointInFromSubSurfaceAtSpecifiedHeight. (doesn't address sloped or stepped floor)
          referenceFloor = nil
          space.surfaces.each do |surface|
            if surface.surfaceType == "Floor"
              referenceFloor = surface # just grabbing the first floor I find. Just want it to use as a plane.
            end
          end

          # add sensor for largest south window if it exists
          if hash["daylightSouthHash"].size > 0
            referenceWindow = hash["daylightSouthHash"].sort{|a,b| a[1] <=> b[1]}.last

            # check for spaces taller than wide and adjust inputs as necessary
            estimatedRoomLength = hash["exteriorWallAreaSDaylight"]/hash["spaceHeight"]
            estimatedRoomWidth = hash["floorArea"]/estimatedRoomLength
            if hash["spaceHeight"] > estimatedRoomWidth
              distanceFromWindow = estimatedRoomWidth - daylightMinOppositeWallClearance
            else
              if hash["spaceHeight"] < estimatedRoomWidth - daylightMinOppositeWallClearance
                distanceFromWindow = hash["spaceHeight"]
              else
                distanceFromWindow = estimatedRoomWidth - daylightMinOppositeWallClearance
              end
            end

            position = OsLib_Geometry.createPointInFromSubSurfaceAtSpecifiedHeight(model,referenceWindow[0],referenceFloor,distanceFromWindow,daylightSensorHeight)

            # customize default sensor values as needed
            options = defaults
            options["position"] = position
            options["phiRotationAroundZAxis"] = OpenStudio::convert(referenceWindow[0].azimuth,"rad","deg").get

            # add sensor
            if not position.nil?
              pri_light_sensor = OsLib_LightingAndEquipment.addDaylightSensor(model,options)
            else
              runner.registerWarning("Couldn't find good Sensor Location for #{space.name}. Did not add daylight sensor.")
            end

          end

          # add sensor for largest north window if it exists
          if hash["daylightNorthHash"].size > 0
            referenceWindow = hash["daylightNorthHash"].sort{|a,b| a[1] <=> b[1]}.last

            # check for spaces taller than wide and adjust inputs as necessary
            estimatedRoomLength = hash["exteriorWallAreaNDaylight"]/hash["spaceHeight"]
            estimatedRoomWidth = hash["floorArea"]/estimatedRoomLength
            if hash["spaceHeight"] > estimatedRoomWidth
              distanceFromWindow = estimatedRoomWidth - daylightMinOppositeWallClearance
            else
              if hash["spaceHeight"] < estimatedRoomWidth - daylightMinOppositeWallClearance
                distanceFromWindow = hash["spaceHeight"]
              else
                distanceFromWindow = estimatedRoomWidth - daylightMinOppositeWallClearance
              end
            end

            position = OsLib_Geometry.createPointInFromSubSurfaceAtSpecifiedHeight(model,referenceWindow[0],referenceFloor,distanceFromWindow,daylightSensorHeight)

            # customize default sensor values as needed
            options = defaults
            options["position"] = position
            options["phiRotationAroundZAxis"] = OpenStudio::convert(referenceWindow[0].azimuth,"rad","deg").get

            # add sensor
            if not position.nil?
              pri_light_sensor = OsLib_LightingAndEquipment.addDaylightSensor(model,options)
            else
              runner.registerWarning("Couldn't find good Sensor Location for #{space.name}. Did not add daylight sensor.")
            end

          end

        end # end of if hash["skylight"]

        # update floor area and wall area numbers
        zoneFloorArea += hash["floorArea"]
        if hash["skylight"]
          zoneDaylightWallArea_space = hash["floorArea"] # if the space has skylights then included the full floor area in daylit area
        else
           if hash["exteriorWallAreaNDaylight"] + hash["exteriorWallAreaSDaylight"] < hash["floorArea"]
             zoneDaylightWallArea_space = hash["exteriorWallAreaNDaylight"] + hash["exteriorWallAreaSDaylight"]
           else
             zoneDaylightWallArea_space = hash["floorArea"] # don't add more than floor area. This would occur on small room with tall wall, or with both north and south exposure
           end
        end

        # add space zone wall area to zone counter
        zoneDaylightWallArea += zoneDaylightWallArea_space

        # push each spaces fraction daylight to hash. This is to look for outliers. May also want to check for mixed side and top lighting
        zoneSpaceDaylightFractionHash[space] = zoneDaylightWallArea_space/hash["floorArea"]
        zoneSkylightHash[space] = hash["skylight"]

      end # end of zoneSpacesHash.each do

      # identify which space to hook sensors to zone from
      maxLightingPower = 0
      spaceToHookToZone = nil
      zoneSpacesHash.each do |space,hash|
        if maxLightingPower < hash["lightingPower"]
          maxLightingPower = hash["lightingPower"]
          spaceToHookToZone = space
        end
      end

      if not spaceToHookToZone.nil?

        # get fractional value
        zoneDaylightFraction = zoneDaylightWallArea/zoneFloorArea

        # connect daylighting controls
        if spaceToHookToZone.daylightingControls.size > 1
          thermalZone.setPrimaryDaylightingControl(spaceToHookToZone.daylightingControls[0])
          thermalZone.setSecondaryDaylightingControl(spaceToHookToZone.daylightingControls[1])
          thermalZone.setFractionofZoneControlledbyPrimaryDaylightingControl(0.5*zoneDaylightFraction)
          thermalZone.setFractionofZoneControlledbySecondaryDaylightingControl(0.5*zoneDaylightFraction)
        elsif spaceToHookToZone.daylightingControls.size > 0
          thermalZone.setPrimaryDaylightingControl(spaceToHookToZone.daylightingControls[0])
          thermalZone.setFractionofZoneControlledbyPrimaryDaylightingControl(zoneDaylightFraction)
        end
      end

    end # end of  model.getThermalZones.each do

    # issue a info if cap has to be set manually above
    if wwrCapFlag > 0
      runner.registerInfo("#{wwrCapFlag} surfaces had the window to wall ratio capped at #{wwrCapValue}. This may be due to a deep space limited exterior exposure.")
    end

    # warn user if any spaces were not in thermal zones. Those spaces are not looked at by this measure.
    orphanSpaces = false
    model.getSpaces.each do |space|
      if space.thermalZone.empty?
        runner.registerInfo("One or more spaces in the model are not associated with thermal zones. Existing translucent exterior fenestration was removed, but no new fenestration was added. Note that until you add these spaces to thermal zones they will not be part of the simulation and may create boundary condition issues in adjacent spaces.")
        orphanSpaces == true
        break
      end
    end

    # populate AEDG tip keys
    aedgTips = []

    #batch push envelope tips 23 through 34
    counter = 23
    until counter == 34
      if counter < 10
        aedgTips.push("EN0#{counter}")
      else
        aedgTips.push("EN#{counter}")
      end
      counter += 1
    end
    #batch push daylighting tips 1 through 20

    counter = 1
    until counter == 20
      if counter < 10
        aedgTips.push("DL0#{counter}")
      else
        aedgTips.push("DL#{counter}")
      end
      counter += 1
    end

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips("SmMdOff",aedgTips.uniq,runner) #removed sort, which was used in other AEDG measures
    if not aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    # get window to wall ratio for initial condition
    finalGrossWWR = OsLib_Geometry.getExteriorWindowToWallRatio(model.getSpaces)
    finalNetWWR = OsLib_Geometry.getExteriorWindowToWallRatio(spacesPartOfFloorArea)

    # store original cost of construction objects for use in final condition.
    finalEnvelopeCost = OsLib_Constructions.getTotalCostOfSelectedConstructions(model.getConstructions)

    # reporting final condition of model
    if spacesPartOfFloorArea.size < model.getSpaces.size
      runner.registerFinalCondition("The building has a final gross window to wall ratio of #{OpenStudio::toNeatString(finalGrossWWR,2,true)} and a final net window to wall ratio of #{OpenStudio::toNeatString(finalNetWWR,2,true)}. Cost increase due to this measure is $#{OpenStudio::toNeatString(finalEnvelopeCost - initialEnvelopeCost,0,true)}. #{aedgTipsLong}")
    else
      runner.registerFinalCondition("The building has a final  window to wall ratio of #{OpenStudio::toNeatString(finalGrossWWR,2,true)}. Cost increase due to this measure is $#{OpenStudio::toNeatString(finalEnvelopeCost - initialEnvelopeCost,0,true)}. #{aedgTipsLong}")
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AedgSmallToMediumOfficeFenestrationAndDaylightingControls.new.registerWithApplication