#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_Geometry"
require "#{File.dirname(__FILE__)}/resources/OsLib_HelperMethods"
require "#{File.dirname(__FILE__)}/resources/OsLib_Cofee"

#start the measure
class LPDtoLamps < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "LPDtoLamps"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make choice argument economizer control type
    lpd_to_lamps = OpenStudio::Ruleset::OSArgument::makeBoolArgument("lpd_to_lamps", true)
    lpd_to_lamps.setDisplayName("Replace LPD with Lamps")
    args << lpd_to_lamps
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Assign the user inputs to variables
    lpd_to_lamps = runner.getBoolArgumentValue("lpd_to_lamps",user_arguments)    
    
    # Note if lpd_to_lamps == NoChange
    # and register as N/A
    if lpd_to_lamps == false
      runner.registerAsNotApplicable("N/A - User requested no change in lighting representation.")
      return true
    end     
    
    # Define lighting technology lookup table by space type
    ltg_tech_lookup = []
    ltg_tech_lookup << ['Office','BreakRoom',0.219,0.73,1.2,1.89,2.28]
    ltg_tech_lookup << ['Office','ClosedOffice',0.333,1.11,1.1,1.73,2.28]
    ltg_tech_lookup << ['Office','Conference',0.369,1.23,1.3,1.84,2.09]
    ltg_tech_lookup << ['Office','Corridor',0.198,0.66,0.5,0.78,2.47]
    ltg_tech_lookup << ['Office','Elec/MechRoom',0.285,0.95,1.5,2.36,2.85]
    ltg_tech_lookup << ['Office','IT_Room',0.333,1.11,1.1,1.55,2.09]
    ltg_tech_lookup << ['Office','Lobby',0.27,0.9,1.3,2.04,2.47]
    ltg_tech_lookup << ['Office','OpenOffice',0.294,0.98,1.1,1.73,2.09]
    ltg_tech_lookup << ['Office','PrintRoom',0.333,1.11,1.1,1.55,1.88]
    ltg_tech_lookup << ['Office','Restroom',0.294,0.98,0.9,1.41,1.71]
    ltg_tech_lookup << ['Office','Stair',0.207,0.69,0.6,0.94,1.14]
    ltg_tech_lookup << ['Office','Storage',0.189,0.63,0.8,1.27,1.54]
    ltg_tech_lookup << ['Office','Vending',0.198,0.66,0.5,1.57,0.95]
    
    # Put lighting technology lookup into hash
    ltg_tech_hash = {}
    ltg_tech_lookup.each do |rule|
      ltg_tech_hash["#{rule[0]} #{rule[1]}"] = [rule[2],rule[3],rule[4],rule[5],rule[6]] 
    end

    # Report initial condition of model
    startingLightingPower =  OpenStudio::toNeatString(model.getBuilding.lightingPower,0,true)# double,decimals, show commas
    runner.registerInitialCondition("The building started with a lighting power of #{startingLightingPower} watts.")

    lights_defs = model.getLightsDefinitions
    if lights_defs.size == 0
      runner.registerAsNotApplicable("Nothing to do,this model doesn't have lights.")
      return true
    end

    # Loop through light defs
    lights_defs.sort.each do |lights_def|

      # Skip if no instance use this lights definition
      next if lights_def.instances.to_a.size == 0

      # Get LPD currently specified by this lights definition
      lpd_w_per_m2 = lights_def.wattsperSpaceFloorArea.get
      lpd_w_per_ft2 = OpenStudio::convert(lpd_w_per_m2,"W/m^2","W/ft^2").get

      # Define a "typical" fixture for each technology
      num_lamps = nil
      lamp_wattage = nil
      num_ballasts = nil
      ballast_factor = nil
      ballast_type = nil
      technology = nil
      fixture_wattage = nil
      fixture_name = nil

      # Loop through all space types and replace lights def specified as LPD with
      # actual light fixtures
      model.getSpaceTypes.sort.each do |space_type|

        # next if there are no spaces using this space type
        next if space_type.spaces.size == 0

        # stop here if this space type doesn't use the lights_def
        # todo - make this more robust to handle multiple light instances using same def in a model
        usesDefFlag = false
        lights = space_type.lights
        lights.each do |light|
          if light.lightsDefinition == lights_def
            usesDefFlag = true
          end
        end

        next if usesDefFlag == false

        # get standards info and looking techMultiplier
        space_typeStandards = OsLib_HelperMethods.getSpaceTypeStandardsInformation([space_type])
        ltg_tech_types = ltg_tech_hash["#{space_typeStandards[space_type][0]} #{space_typeStandards[space_type][1]}"]

        # Catchall for a space type not found in the lookup
        if ltg_tech_types.nil?
          runner.registerWarning("Couldn't find lighting technology lookup for #{space_typeStandards[space_type][0]} #{space_typeStandards[space_type][1]}.")
          next
        end

        # Infer lighting technology based on building type, space type, and LPD
        closest_ltg_type = nil
        min_error = 999999
        for i in 0..ltg_tech_types.size - 1
          ltg_type_lpd = ltg_tech_types[i].to_f
          error = (lpd_w_per_ft2 - ltg_type_lpd).abs
          if error <= min_error
            closest_ltg_type = i
            min_error = error
          end
        end
         
        # Define a "typical" fixture for each technology
        # Naming convention for light fixtures
        # which is expected by EE Measures downstream (so don't modify it!)
        # (2) 40W A19 Standard Incandescent (1) 0.8BF HID Electronic Ballast
        case closest_ltg_type
        when 0
          ltg_tech_inferred = 'led'
          num_lamps = 2
          lamp_wattage = 21
          technology = "Linear LED"
          fixture_wattage = num_lamps*lamp_wattage
          fixture_name = "(#{num_lamps}) #{lamp_wattage}W #{technology}"
        when 1 
          ltg_tech_inferred = 'high_eff_t8'
          num_lamps = 2
          lamp_wattage = 25
          num_ballasts = 1
          ballast_factor = 0.88
          ballast_type = 'Electronic'
          technology = 'T8 Linear Fluorescent'
          fixture_wattage = num_lamps*lamp_wattage*ballast_factor
          fixture_name = "(#{num_lamps}) #{lamp_wattage}W #{technology} (#{num_ballasts}) #{ballast_factor}BF #{ballast_type}"         
        when 2 
          ltg_tech_inferred = 'high_eff_t8'
          num_lamps = 2
          lamp_wattage = 32
          num_ballasts = 1
          ballast_factor = 1.0
          ballast_type = 'Electronic'
          technology = 'T8 Linear Fluorescent'
          fixture_wattage = num_lamps*lamp_wattage*ballast_factor
          fixture_name = "(#{num_lamps}) #{lamp_wattage}W #{technology} (#{num_ballasts}) #{ballast_factor}BF #{ballast_type}"
        when 3 
          ltg_tech_inferred = 't12_magnetic'
          num_lamps = 4
          lamp_wattage = 40
          num_ballasts = 1
          ballast_factor = 1.2
          ballast_type = 'Magnetic'
          technology = 'T12 Linear Fluorescent'
          fixture_wattage = num_lamps*lamp_wattage*ballast_factor
          fixture_name = "(#{num_lamps}) #{lamp_wattage}W #{technology} (#{num_ballasts}) #{ballast_factor}BF #{ballast_type}"
        when 4 
          ltg_tech_inferred = 'incandescent'
          num_lamps = 4
          lamp_wattage = 60
          technology = 'Incandescent'
          fixture_wattage = num_lamps*lamp_wattage
          fixture_name = "(#{num_lamps}) #{lamp_wattage}W #{technology}"
        end
        
        # Report out the inference
        runner.registerInfo("Inferred that '#{space_type.name}' with LPD of #{lpd_w_per_ft2.round(2)}W/ft^2 has #{ltg_tech_inferred} lights based on an LPD closest to #{ltg_tech_types[closest_ltg_type]}W/ft^2.")
          
        space_type.spaces.sort.each do |space|

          # todo check and see if there were any space lights to start with

          # for now I'm not going to deal with schedules, I'll let schedule sets pick it up but not very robust.

          # get area of lights.
          floor_area_m2 = space.floorArea # don't want to add space.multiplier to area because zone multiplier will already pick this up.
          floor_area_display = OsLib_HelperMethods.neatConvertWithUnitDisplay(floor_area_m2,"m^2","ft^2",0)

          # Find total power wattage for this instance
          total_lighting_power_w = lpd_w_per_m2*floor_area_m2  # TODO should confirm that original light instance multiplier is 1

          # Calculate number of fixtures needed to hit calibrated LPD
          num_fixtures = (total_lighting_power_w/fixture_wattage).round # Don't want partial fixtures
          # todo - confirm with Nick and Brian if they want rounding. I think they want accurate wattage and are ok with fractional number of fixtures.

          # Add a new light fixture to replace LPD 
          new_light_inst = OpenStudio::Model::Lights.new(lights_def)
          new_light_inst.setMultiplier(num_fixtures)
          new_light_inst.setSpace(space)
          
          # TODO QAQC area per lamp against typical fixture densities
          # https://www1.eere.energy.gov/femp/pdfs/economics_eel.pdf
          # Open office
          # 2x4' (4) T12 Magnetic - 8'x8' centers - 16ft^2/T12 lamp
          # (2) T8 Electronic - 8'x8' centers - 32ft^2/T8 lamp
          # (2) T8 Electronic - 8'x10' centers - 40ft^2/T8 lamp
          # (3) T8 Electronic - 10'x10' centers - 33ft^2/T8 lamp
          # Closed office
          # 2x4 (4) T12 Magnetic - 8'x12' office - 23ft^2/T12 lamp
          # (2) T8 Electronic - 8'x12' office - 48ft^2/T8 lamp
          # (3) T8 Electronic - 8'x12' office - 32ft^2/T8 lamp
          # Density ranges for QAQC
          # T8 - 48ft^2/lamp to 32ft^2/lamp
          # T12 - 23ft^2/lamp to 16ft^2/lamp

        end # end of space_type.spaces each do
        
        # Remove old lights instances using LPD from space type
        lights.each do |light|
          if light.lightsDefinition == lights_def
            light.remove
          end
        end

      end # end of space_types.sort.each do

      # Replace the lights def specified as LPD
      # with actual fixtures
      if fixture_name and fixture_wattage # not sure why this is needed but for some reason a full nulls are passed in
        lights_def.setName(fixture_name)
        lights_def.setLightingLevel(fixture_wattage)
      else
        runner.registerInfo("Skipping #{lights_def.name} because there are no spaces affected by it's instances. It may be used for an unassigned space type.")
      end
      
    end # end of lights_defs.sort.each do

    # Report final condition of model
    final_lighting_power_w =  OpenStudio::toNeatString(model.getBuilding.lightingPower,0,true)# double,decimals, show commas
    runner.registerFinalCondition("The building finished with a lighting power of #{final_lighting_power_w} watts.")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
LPDtoLamps.new.registerWithApplication