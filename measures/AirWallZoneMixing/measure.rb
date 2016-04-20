# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/os_lib_geometry"

# start the measure
class AirWallZoneMixing < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Air Wall Zone Mixing"
  end

  # human readable description
  def description
    return "This measure replaces conductive heat transfer with zone mixing wherever air walls are used on matched surfaces or sub-surfaces for walls. A user argument is exposed for a coefficient that represents a target air changes per hour (ACH) for a room where the zone volume/the air wall surface area is the same as its zone height. As the room gets deeper the additional airflow per unit of depth decreases. If two zones have different mixing estimates, the lower will be used. If a smaller portion of an inter-zone wall is an air wall, that will also decrease zone mixing airflow.

A construction will be hard assigned to the matched surfaces using the air wall, and the then boundary condition will be changed to adiabatic. This will avoid including both air mixing and conductive transfer across zones. Zone mixing objects will also be made for sub-surface air walls, but they can't be made adiabatic unless their base surface also is. A warning will be issued if that happens"
  end

  # human readable description of modeling approach
  def modeler_description
    return "The formula used to determine the design flow rate is the zone mixing coefficient * zone volume/sqrt(zone volume / (air wall area * zone height).

Zone mixing will only be added where there is an air wall and where the matched surfaces belong to spaces in different thermal zones and the base surface type is a wall. Currently floors are not addressed by this measure. Air walls in spaces that are part of the same thermal zone will be left alone. The intended use case is a single base surface that spans the room or one or more sub-surface that spans a portion of it. If you have multiple air wall base surfaces matched between the same zones you may get higher than expected zone mixing.

Example 1: two 10' high by 40' wide by 10' deep rooms with a zone mixing coefficient of 1.0 would have a design flow rate of 66.67 CFM (equiv to 1.0 ACH)
Example 2: two 10' high by 40' wide by 40' deep rooms with a zone mixing coefficient of 1.0 would have a design flow rate of 133.33 CFM (equiv to 0.5 ACH)
Example 3: two 40' high by 10' wide by 10' deep rooms with a zone mixing coefficient of 1.0 would have a design flow rate of 66.67 CFM (equiv to 1.0 ACH)"
  end
  # todo - update it to look at all matched surfaces between two zones at the same time and make a single zone mixing object. This will better handle split walls where part is open and part is solid.

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # the name of the space to add to the model
    zone_mixing_coef = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("zone_mixing_coef", true)
    zone_mixing_coef.setDisplayName("Cross Mixing Coefficient")
    zone_mixing_coef.setDescription("Cross Mixing flow rate = zone mixing coefficient * zone volume/sqrt(thermal zone volume/(air wall area*zone height))")
    zone_mixing_coef.setDefaultValue(1.0)
    args << zone_mixing_coef

    # the name of the space to add to the model
    add_zone_mixing_variables = OpenStudio::Ruleset::OSArgument.makeBoolArgument("add_zone_mixing_variables", true)
    add_zone_mixing_variables.setDisplayName("Add Zone Mixing Output Variable Requests")
    add_zone_mixing_variables.setDefaultValue(true)
    args << add_zone_mixing_variables

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    zone_mixing_coef = runner.getDoubleArgumentValue("zone_mixing_coef", user_arguments)
    add_zone_mixing_variables = runner.getBoolArgumentValue("add_zone_mixing_variables", user_arguments)

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getZoneMixings.size} Zone Mixing Objects.")

    # array of surfaces and sub-surfaces already processed
    processed_surfaces = []
    processed_sub_surfaces = []

    # populate a hash of zone volumes ahead of time
    zone_volumes = {}
    zone_heights = {}
    model.getThermalZones.sort.each do |zone|
      volume_counter = 0
      max_space_height = 0
      zone.spaces.each do |space|
        volume_counter += space.volume
        min_space_zvalue = OsLib_Geometry.getSurfaceZValues(space.surfaces).sort.first # this expects an array of surfaces
        max_space_zvalue = OsLib_Geometry.getSurfaceZValues(space.surfaces).sort.last # this expects an array of surfaces
        if max_space_zvalue - min_space_zvalue > max_space_height
          max_space_height = max_space_zvalue - min_space_zvalue
        end
      end
      zone_volumes[zone] = volume_counter
      zone_heights[zone] = max_space_height
      puts "volume of #{zone.name} is #{volume_counter}"
    end

    model.getThermalZones.sort.each do |zone|
      zone.spaces.each do |space|
        space.surfaces.each do |surface|
          next if processed_surfaces.include? (surface)
          next if surface.surfaceType != "Wall"
          next if surface.adjacentSurface.is_initialized != true
          adiabatic = false
          boundary_surface = surface.adjacentSurface.get
          processed_surfaces << surface
          processed_surfaces << boundary_surface
          if boundary_surface.space.is_initialized and boundary_surface.space.get.thermalZone.is_initialized
            boundary_object_zone = boundary_surface.space.get.thermalZone.get
            if zone.multiplier != boundary_object_zone.multiplier
              runner.registerWarning("#{zone.name} and #{boundary_object_zone.name} don't have the same multiplier. Won't alter surfaces or add zone mixing for this pair of zones")
              next
            end
            if boundary_object_zone != zone
              # check surface constructions
              if surface.isAirWall
                air_wall_area = surface.grossArea
                zone_a_volume = zone_volumes[zone]
                zone_a_height = zone_heights[zone]
                zone_b_volume = zone_volumes[boundary_object_zone]
                zone_b_height = zone_heights[boundary_object_zone]
                if zone_a_volume <= zone_b_volume
                  zone_volume = zone_a_volume
                  zone_height = zone_a_height
                else
                  zone_volume = zone_b_volume
                  zone_height = zone_b_height
                end

                # calculate target zone mixing values
                # zone_mixing_coef * zone_volume m^3 / (Math.sqrt(zone_volume m^3/ air_wall_area m^2 * zone_height m))
                target_zone_mixing_hour_si = zone_mixing_coef*zone_volume/(Math.sqrt(zone_volume/(air_wall_area * zone_height)))
                target_zone_mixing_si = target_zone_mixing_hour_si/3600.0
                zone_mixing_a = OpenStudio::Model::ZoneMixing.new(zone)
                zone_mixing_a.setSourceZone(boundary_object_zone)
                zone_mixing_a.setDesignFlowRate(target_zone_mixing_si)
                zone_mixing_a.setDeltaTemperature(0.0)
                zone_mixing_b = OpenStudio::Model::ZoneMixing.new(boundary_object_zone)
                zone_mixing_b.setSourceZone(zone)
                zone_mixing_b.setDesignFlowRate(target_zone_mixing_si)
                zone_mixing_b.setDeltaTemperature(0.0)
                target_zone_mixing_ip = OpenStudio.convert(target_zone_mixing_si,'m^3/s','cfm').get
                runner.registerInfo("Add zone mixing between #{zone.name} and #{boundary_object_zone.name} with flowrate of #{target_zone_mixing_ip.round(2)} cfm")
                adiabatic = true
              end
              # check sub_surfaces constructions
              surface.subSurfaces.each do |sub_surface|
                next if sub_surface.adjacentSubSurface.is_initialized != true
                boundary_sub_surface = sub_surface.adjacentSubSurface.get
                processed_sub_surfaces << sub_surface
                processed_sub_surfaces << boundary_sub_surface
                if sub_surface.isAirWall
                  air_wall_area = surface.grossArea
                  zone_a_volume = zone_volumes[zone]
                  zone_a_height = zone_heights[zone]
                  zone_b_volume = zone_volumes[boundary_object_zone]
                  zone_b_height = zone_heights[boundary_object_zone]
                  if zone_a_volume <= zone_b_volume
                    zone_volume = zone_a_volume
                    zone_height = zone_a_height
                  else
                    zone_volume = zone_b_volume
                    zone_height = zone_b_height
                  end

                  # calculate target zone mixing values
                  # zone_mixing_coef * zone_volume m^3 / (Math.sqrt(zone_volume m^3/ air_wall_area m^2 * zone_height m))
                  target_zone_mixing_hour_si = zone_mixing_coef*zone_volume/(Math.sqrt(zone_volume/(air_wall_area * zone_height)))
                  target_adjusted_sub_surface_fraction = target_zone_mixing_hour_si*sub_surface.grossArea/surface.grossArea
                  target_zone_mixing_si = target_adjusted_sub_surface_fraction/3600.0
                  zone_mixing_a = OpenStudio::Model::ZoneMixing.new(zone)
                  zone_mixing_a.setSourceZone(boundary_object_zone)
                  zone_mixing_a.setDesignFlowRate(target_zone_mixing_si)
                  zone_mixing_a.setDeltaTemperature(0.0)
                  zone_mixing_b = OpenStudio::Model::ZoneMixing.new(boundary_object_zone)
                  zone_mixing_b.setSourceZone(zone)
                  zone_mixing_b.setDesignFlowRate(target_zone_mixing_si)
                  zone_mixing_b.setDeltaTemperature(0.0)
                  target_zone_mixing_ip = OpenStudio.convert(target_zone_mixing_si,'m^3/s','cfm').get
                  runner.registerInfo("Add zone mixing between #{zone.name} and #{boundary_object_zone.name} with flowrate of #{target_zone_mixing_ip.round(2)} cfm")
                  sub_surface.setConstruction(sub_surface.construction.get) # is there an easier way to set to air wall
                  boundary_sub_surface.setConstruction(boundary_sub_surface.construction.get) # is there an easier way to set to air wall
                  if not surface.isAirWall
                    runner.registerWarning("Sub-surfaces shared with #{zone.name} and #{boundary_object_zone.name} can't be made adiabatic. Conductive heat transfer will remain in the model for these sub-surfaces.")
                  end
                end
              end
              if adiabatic # moved this later to handle air wall sub-surface hosted by air wall base surface
                surface.setConstruction(surface.construction.get) # is there an easier way to set to air wall
                boundary_surface.setConstruction(boundary_surface.construction.get) # is there an easier way to set to air wall
                surface.setOutsideBoundaryCondition("Adiabatic")
                boundary_surface.setOutsideBoundaryCondition("Adiabatic")
              end
            end
          else
            runner.registerWarning("didn't find thermal zone for #{boundary_surface.name}")
          end
        end
      end
    end

    # add output reports
    if add_zone_mixing_variables
      OpenStudio::Model::OutputVariable.new("Zone Mixing Volume", model)
      OpenStudio::Model::OutputVariable.new("Zone Mixing Current Density Air Volume Flow Rate", model)
      OpenStudio::Model::OutputVariable.new("Zone Mixing Standard Density Air Volume Flow Rate", model)
      OpenStudio::Model::OutputVariable.new("Zone Mixing Mass Flow Rate", model)
      OpenStudio::Model::OutputVariable.new("Zone Mixing Receiving Air Mass Flow Rate", model)
      OpenStudio::Model::OutputVariable.new("Zone Mixing Source Air Mass Flow Rate", model)
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getZoneMixings.size} Zone Mixing Objects.")

    return true

  end
  
end

# register the measure to be used by the application
AirWallZoneMixing.new.registerWithApplication
