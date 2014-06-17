module OsLib_Geometry

  # lower z value of vertices with starting value above x to new value of y
  def OsLib_Geometry.lowerSurfaceZvalue(surfaceArray, zValueTarget)

    counter = 0

    # loop over all surfaces
    surfaceArray.each do |surface|

      # create a new set of vertices
      newVertices = OpenStudio::Point3dVector.new

      # get the existing vertices for this interior partition
      vertices = surface.vertices
      flag = false
      vertices.each do |vertex|

        # initialize new vertex to old vertex
        x = vertex.x
        y = vertex.y
        z = vertex.z

        # if this z vertex is not on the z = 0 plane
        if z > zValueTarget
          z = zValueTarget
          flag = true
        end

        # add point to new vertices
        newVertices << OpenStudio::Point3d.new(x,y,z)
      end

      # set vertices to new vertices
      surface.setVertices(newVertices) #todo check if this was made, and issue warning if it was not. Could happen if resulting surface not planer.

      if flag then counter += 1 end

    end #end of surfaceArray.each do

    result = counter
    return result

  end

  # return an array of z values for surfaces passed in. The values will be relative to the parent origin. This was intended for spaces.
  def OsLib_Geometry.getSurfaceZValues(surfaceArray)

    zValueArray = []

    # loop over all surfaces
    surfaceArray.each do |surface|
      # get the existing vertices
      vertices = surface.vertices
      vertices.each do |vertex|
        # push z value to array
        zValueArray << vertex.z
      end
    end #end of surfaceArray.each do

    result = zValueArray
    return result

  end

  def OsLib_Geometry.createPointAtCenterOfFloor(model,space,zOffset)

    #find floors
    floors = []
    space.surfaces.each do |surface|
      next if not surface.surfaceType == "Floor"
      floors << surface
    end

    #this method only works for flat (non-inclined) floors
    boundingBox = OpenStudio::BoundingBox.new
    floors.each do |floor|
      boundingBox.addPoints(floor.vertices)
    end
    xmin = boundingBox.minX.get
    ymin = boundingBox.minY.get
    zmin = boundingBox.minZ.get
    xmax = boundingBox.maxX.get
    ymax = boundingBox.maxY.get

    x_pos = (xmin + xmax) / 2
    y_pos = (ymin + ymax) / 2
    z_pos = zmin + zOffset

    floorSurfacesInSpace = []
    space.surfaces.each do |surface|
      if surface.surfaceType == "Floor"
        floorSurfacesInSpace << surface
      end
    end

    pointIsOnFloor = OsLib_Geometry.checkIfPointIsOnSurfaceInArray(OpenStudio::Point3d.new(x_pos, y_pos, zmin),floorSurfacesInSpace)

    if pointIsOnFloor
      new_point = OpenStudio::Point3d.new(x_pos, y_pos, z_pos)
    else
      # don't make point, it doesn't appear to be inside of the space
      new_point = nil
    end

    result = new_point
    return result

  end

  def OsLib_Geometry.createPointInFromSubSurfaceAtSpecifiedHeight(model,subSurface,referenceFloor,distanceInFromWindow,heightAboveBottomOfSubSurface)

    window_outward_normal = subSurface.outwardNormal
    window_centroid = OpenStudio::getCentroid(subSurface.vertices).get
    window_outward_normal.setLength(distanceInFromWindow)
    vertex = window_centroid + window_outward_normal.reverseVector
    vertex_on_floorplane = referenceFloor.plane.project(vertex)
    floor_outward_normal = referenceFloor.outwardNormal
    floor_outward_normal.setLength(heightAboveBottomOfSubSurface)

    floorSurfacesInSpace = []
    subSurface.space.get.surfaces.each do |surface|
      if surface.surfaceType == "Floor"
        floorSurfacesInSpace << surface
      end
    end

    pointIsOnFloor = OsLib_Geometry.checkIfPointIsOnSurfaceInArray(vertex_on_floorplane,floorSurfacesInSpace)

    if pointIsOnFloor
      new_point = vertex_on_floorplane + floor_outward_normal.reverseVector
    else
      # don't make point, it doesn't appear to be inside of the space
      new_point = vertex_on_floorplane + floor_outward_normal.reverseVector #nil
    end

    result = new_point
    return result

  end

  def OsLib_Geometry.checkIfPointIsOnSurfaceInArray(point,surfaceArray)

    onSurfacesFlag = false

    surfaceArray.each do |surface|
      # Check if sensor is on floor plane (I need to loop through all floors)
      plane = surface.plane
      point_on_plane = plane.project(point)

      faceTransform = OpenStudio::Transformation::alignFace(surface.vertices)
      faceVertices = faceTransform*surface.vertices
      facePointOnPlane = faceTransform*point_on_plane

      if OpenStudio::pointInPolygon(facePointOnPlane, faceVertices.reverse, 0.01)
        # initial_sensor location lands in this surface's polygon
        onSurfacesFlag = true
      end

    end # end of surfaceArray.each do

    if onSurfacesFlag
      result = true
    else
      result = false
    end

    return result
  end

  def OsLib_Geometry.getExteriorWindowToWallRatio(spaceArray)

    # counters
    total_gross_ext_wall_area = 0
    total_ext_window_area = 0

    spaceArray.each do |space|

      #get surface area adjusting for zone multiplier
      zone = space.thermalZone
      if not zone.empty?
        zone_multiplier = zone.get.multiplier
        if zone_multiplier > 1
        end
      else
        zone_multiplier = 1 #space is not in a thermal zone
      end

      space.surfaces.each do |s|
        next if not s.surfaceType == "Wall"
        next if not s.outsideBoundaryCondition == "Outdoors"

        surface_gross_area = s.grossArea * zone_multiplier

        #loop through sub surfaces and add area including multiplier
        ext_window_area = 0
        s.subSurfaces.each do |subSurface|
          ext_window_area = ext_window_area + subSurface.grossArea * subSurface.multiplier * zone_multiplier
        end

        total_gross_ext_wall_area += surface_gross_area
        total_ext_window_area += ext_window_area
      end #end of surfaces.each do
    end # end of space.each do


    result = total_ext_window_area/total_gross_ext_wall_area
    return result

  end

  # add def to create a space from input, optionally take a name, space type, story and thermal zone.
  def OsLib_Geometry.makeSpaceFromPolygon(model,spaceOrign,point3dVector,options = {})

    # set defaults to use if user inputs not passed in
    defaults = {
        "name" => nil,
        "spaceType" => nil,
        "story" => nil,
        "makeThermalZone" => nil,
        "thermalZone" => nil,
        "thermalZoneMultiplier" => 1,
        "floor_to_floor_height" => OpenStudio::convert(10,"ft","m").get,
    }

    # merge user inputs with defaults
    options = defaults.merge(options)

    # Identity matrix for setting space origins
    m = OpenStudio::Matrix.new(4,4,0)
    m[0,0] = 1
    m[1,1] = 1
    m[2,2] = 1
    m[3,3] = 1

    # make space for space
    core_space = OpenStudio::Model::Space::fromFloorPrint(point3dVector, options["floor_to_floor_height"], model)
    core_space = core_space.get
    m[0,3] = spaceOrign.x
    m[1,3] = spaceOrign.y
    m[2,3] = spaceOrign.z
    core_space.changeTransformation(OpenStudio::Transformation.new(m))
    core_space.setBuildingStory(options["story"])

    # assign space type
    core_space.setSpaceType(options["spaceType"])

    # create thermal zone if requested and assign
    if options["makeThermalZone"]
      new_zone = OpenStudio::Model::ThermalZone.new(model)
      new_zone.setMultiplier(options["thermalZoneMultiplier"])
      core_space.setThermalZone(new_zone)
    else
      if not options["thermalZone"].nil? then core_space.setThermalZone(options["thermalZone"]) end
    end

    result = core_space
    return result

  end

  def OsLib_Geometry.getExteriorWindowAndWllAreaByOrientation(model, spaceArray, options = {})

    # set defaults to use if user inputs not passed in
    defaults = {
        "northEast" => 45,
        "southEast" => 125,
        "southWest" => 225,
        "northWest" => 315,
    }

    # merge user inputs with defaults
    options = defaults.merge(options)

    # counters
    total_gross_ext_wall_area_North = 0
    total_gross_ext_wall_area_South = 0
    total_gross_ext_wall_area_East = 0
    total_gross_ext_wall_area_West = 0
    total_ext_window_area_North = 0
    total_ext_window_area_South = 0
    total_ext_window_area_East = 0
    total_ext_window_area_West = 0

    spaceArray.each do |space|

      #get surface area adjusting for zone multiplier
      zone = space.thermalZone
      if not zone.empty?
        zone_multiplier = zone.get.multiplier
        if zone_multiplier > 1
        end
      else
        zone_multiplier = 1 #space is not in a thermal zone
      end

      space.surfaces.each do |s|
        next if not s.surfaceType == "Wall"
        next if not s.outsideBoundaryCondition == "Outdoors"

        surface_gross_area = s.grossArea * zone_multiplier

        #loop through sub surfaces and add area including multiplier
        ext_window_area = 0
        s.subSurfaces.each do |subSurface|
          ext_window_area = ext_window_area + subSurface.grossArea * subSurface.multiplier * zone_multiplier
        end

        # get the absoluteAzimuth for the surface so we can categorize it
        absoluteAzimuth =  OpenStudio::convert(s.azimuth,"rad","deg").get - s.space.get.directionofRelativeNorth - model.getBuilding.northAxis

        # add to exterior wall counter if north or south
        if options["northEast"] <= absoluteAzimuth and absoluteAzimuth < options["southEast"]  # East exterior walls
          total_gross_ext_wall_area_East += surface_gross_area
          total_ext_window_area_East += ext_window_area
        elsif options["southEast"] <= absoluteAzimuth and absoluteAzimuth < options["southWest"] # South exterior walls
          total_gross_ext_wall_area_South += surface_gross_area
          total_ext_window_area_South += ext_window_area
        elsif options["southWest"] <= absoluteAzimuth and absoluteAzimuth < options["northWest"] # West exterior walls
          total_gross_ext_wall_area_West += surface_gross_area
          total_ext_window_area_West += ext_window_area
        else # North exterior walls
          total_gross_ext_wall_area_North += surface_gross_area
          total_ext_window_area_North += ext_window_area
        end

      end #end of surfaces.each do
    end # end of space.each do

    result = {"northWall"=> total_gross_ext_wall_area_North,
              "northWindow"=> total_ext_window_area_North,
              "southWall"=> total_gross_ext_wall_area_South,
              "southWindow"=> total_ext_window_area_South,
              "eastWall"=> total_gross_ext_wall_area_East,
              "eastWindow"=> total_ext_window_area_East,
              "westWall"=> total_gross_ext_wall_area_West,
              "westWindow"=> total_ext_window_area_West,
    }
    return result

  end

end