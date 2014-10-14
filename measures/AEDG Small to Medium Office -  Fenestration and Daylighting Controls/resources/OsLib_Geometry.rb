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


end