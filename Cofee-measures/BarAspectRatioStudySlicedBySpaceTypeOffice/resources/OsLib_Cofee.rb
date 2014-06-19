module OsLib_Cofee

  # create def to use later to make bar
  def OsLib_Cofee.createBar(model, spaceTypeHash,lengthXTarget,lengthYTarget,totalFloorArea,numStories,midFloorMultiplier,xmin,ymin,lengthX,lengthY,zmin,zmax,endZones)

    # floor to floor height
    floor_to_floor_height = (zmax-zmin)/numStories

    # perimeter depth
    perimeterDepth = OpenStudio::convert(12,"ft","m").get
    perimeterBufferFactor = 1.5 # this is a margin below which I won't bother splitting the two largest spaces

    # create an array to control sort order of spaces in bar
    customSpaceTypeBar = []
    counter = 0
    spaceTypeHash.sort_by {|key, value| value}.reverse.each do |k,v|
      next if v == 0 # this line adds support for fractional values of 0
      if counter == 1
        if lengthXTarget*(v/totalFloorArea) > perimeterDepth * perimeterBufferFactor and endZones
          customSpaceTypeBar << [k,totalFloorArea * (perimeterDepth/lengthXTarget)]
          customSpaceTypeBar << [k,v - (totalFloorArea * (perimeterDepth/lengthXTarget))]
        else
          customSpaceTypeBar << [k,v]
        end
      elsif counter > 1
        customSpaceTypeBar << [k,v]
      end
      counter += 1
    end

    # add the largest space type to the end
    counter = 0
    spaceTypeHash.sort_by {|key, value| value}.reverse.each do |k,v|
      if counter == 0
        # if width is greater than 1.5x perimeter depth then split in half
        if lengthXTarget*(v/totalFloorArea) > perimeterDepth * perimeterBufferFactor and endZones
          customSpaceTypeBar << [k,v - (totalFloorArea * (perimeterDepth/lengthXTarget))]
          customSpaceTypeBar << [k,totalFloorArea * (perimeterDepth/lengthXTarget)]
        else
          customSpaceTypeBar << [k,v]
        end
      end
      break
    end

    # starting z level
    z = zmin
    storyCounter = 0
    barSpaceArray = []

    # create new stories and then add spaces
    [numStories,3].min.times do # no more than tree loops through this
      story = OpenStudio::Model::BuildingStory.new(model)
      story.setNominalFloortoFloorHeight(floor_to_floor_height)
      story.setNominalZCoordinate(z)

      # starting position for first space
      x = (lengthX - lengthXTarget)*0.5 + xmin
      y = (lengthY - lengthYTarget)*0.5 + ymin

      # temp array of spaces (this is to change floor boundary when there is mid floor multiplier)
      tempSpaceArray = []

      # loop through space types making diagram and spaces.
      #spaceTypeHash.sort_by {|key, value| value}.reverse.each do |k,v|
      customSpaceTypeBar.each do |object|

        # get values from what was hash
        k = object[0]
        v = object[1]

        # get proper zone multiplier value
        if storyCounter == 1 and midFloorMultiplier > 1
          thermalZoneMultiplier = midFloorMultiplier
        else
          thermalZoneMultiplier = 1
        end

        options = {
            "name" => nil,
            "spaceType" => k,
            "story" => story,
            "makeThermalZone" => true,
            "thermalZone" => nil,
            "thermalZoneMultiplier" => thermalZoneMultiplier,
            "floor_to_floor_height" => floor_to_floor_height,
        }

        # three paths for spaces depending upon building depth (3, 2 or one cross slices)
        if lengthYTarget > perimeterDepth * 3  # slice into core and perimeter

          # perimeter polygon a
          perim_polygon_a = OpenStudio::Point3dVector.new
          perim_origin_a = OpenStudio::Point3d.new(x,y,z)
          perim_polygon_a << perim_origin_a
          perim_polygon_a << OpenStudio::Point3d.new(x,y + perimeterDepth,z)
          perim_polygon_a << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + perimeterDepth,z)
          perim_polygon_a << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y,z)

          # create core polygon
          core_polygon = OpenStudio::Point3dVector.new
          core_origin = OpenStudio::Point3d.new(x,y + perimeterDepth,z)
          core_polygon << core_origin
          core_polygon << OpenStudio::Point3d.new(x,y + lengthYTarget - perimeterDepth,z)
          core_polygon << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget - perimeterDepth,z)
          core_polygon << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + perimeterDepth,z)

          # perimeter polygon b                              w
          perim_polygon_b = OpenStudio::Point3dVector.new
          perim_origin_b = OpenStudio::Point3d.new(x,y + lengthYTarget - perimeterDepth,z)
          perim_polygon_b << perim_origin_b
          perim_polygon_b << OpenStudio::Point3d.new(x,y + lengthYTarget,z)
          perim_polygon_b << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget,z)
          perim_polygon_b << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget - perimeterDepth,z)

          # run method to make spaces
          tempSpaceArray << OsLib_Geometry.makeSpaceFromPolygon(model,perim_origin_a,perim_polygon_a,options) # model, origin, polygon, options
          tempSpaceArray << OsLib_Geometry.makeSpaceFromPolygon(model,core_origin,core_polygon,options) # model, origin, polygon, options
          tempSpaceArray << OsLib_Geometry.makeSpaceFromPolygon(model,perim_origin_b,perim_polygon_b,options) # model, origin, polygon, options

        elsif lengthYTarget > perimeterDepth * 2  # slice into two peremeter zones but no core

          # perimeter polygon a
          perim_polygon_a = OpenStudio::Point3dVector.new
          perim_origin_a = OpenStudio::Point3d.new(x,y,z)
          perim_polygon_a << perim_origin_a
          perim_polygon_a << OpenStudio::Point3d.new(x,y + lengthYTarget/2,z)
          perim_polygon_a << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget/2,z)
          perim_polygon_a << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y,z)

          # perimeter polygon b
          perim_polygon_b = OpenStudio::Point3dVector.new
          perim_origin_b = OpenStudio::Point3d.new(x,y + lengthYTarget/2,z)
          perim_polygon_b << perim_origin_b
          perim_polygon_b << OpenStudio::Point3d.new(x,y + lengthYTarget,z)
          perim_polygon_b << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget,z)
          perim_polygon_b << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget/2,z)

          # run method to make spaces
          tempSpaceArray << OsLib_Geometry.makeSpaceFromPolygon(model,perim_origin_a,perim_polygon_a,options) # model, origin, polygon, options
          tempSpaceArray << OsLib_Geometry.makeSpaceFromPolygon(model,perim_origin_b,perim_polygon_b,options) # model, origin, polygon, options

        else # don't slice into core and perimeter

          # create polygon
          core_polygon = OpenStudio::Point3dVector.new
          core_origin = OpenStudio::Point3d.new(x,y,z)
          core_polygon << core_origin
          core_polygon << OpenStudio::Point3d.new(x,y + lengthYTarget,z)
          core_polygon << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget,z)
          core_polygon << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y,z)

          # run method to make space
          tempSpaceArray << OsLib_Geometry.makeSpaceFromPolygon(model,core_origin,core_polygon,options) # model, origin, polygon, options

        end

        # update points for next run
        x += lengthXTarget*(v/totalFloorArea)

      end # end of spaceTypeHash loop

      # set flags for adiabatic surfaces
      floorAdiabatic = false
      ceilingAdiabatic = false

      # update z
      if midFloorMultiplier == 1
        z += floor_to_floor_height
      else
        z += floor_to_floor_height * midFloorMultiplier - floor_to_floor_height

        if storyCounter == 0
          ceilingAdiabatic = true
        elsif storyCounter == 1
          floorAdiabatic = true
          ceilingAdiabatic = true
        else
          floorAdiabatic = true
        end

        # alter surfaces boundary conditions and constructions as described above
        tempSpaceArray.each do |space|
          space.surfaces.each do |surface|
            if surface.surfaceType == "RoofCeiling" and ceilingAdiabatic
              construction = surface.construction # todo - this isn't really the construction I want since it wasn't an interior one, but will work for now
              surface.setOutsideBoundaryCondition("Adiabatic")
              if not construction.empty?
                surface.setConstruction(construction.get)
              end
            end
            if surface.surfaceType == "Floor" and floorAdiabatic
              construction = surface.construction # todo - this isn't really the construction I want since it wasn't an interior one, but will work for now
              surface.setOutsideBoundaryCondition("Adiabatic")
              if not construction.empty?
                surface.setConstruction(construction.get)
              end
            end
          end
        end

        # populate bar space array from temp array
        barSpaceArray << tempSpaceArray

      end # end if midFloorMultiplier == 1

      # update storyCounter
      storyCounter += 1

    end # end of numStories.times.do

    # surface matching (seems more complex than necessary)
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end
    OpenStudio::Model.matchSurfaces(spaces)

    result = barSpaceArray
    return result

  end # end of def createBar()

end