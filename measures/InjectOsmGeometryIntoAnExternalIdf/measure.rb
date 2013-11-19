#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#start the measure
class InjectOsmGeometryIntoAnExternalIdf < OpenStudio::Ruleset::WorkspaceUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "InjectOsmGeometryIntoAnExternalIdf"
  end

  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for your name
    source_idf_path = OpenStudio::Ruleset::OSArgument::makeStringArgument("source_idf_path",true)
    source_idf_path.setDisplayName("Path to Source IDF File to Use.")
    args << source_idf_path

    #make an argument to add new zone true/false
    merge_geometry_from_osm = OpenStudio::Ruleset::OSArgument::makeBoolArgument("merge_geometry_from_osm",true)
    merge_geometry_from_osm.setDisplayName("Merge Geometry From OpenStudio Model into Source IDF File?")
    merge_geometry_from_osm.setDefaultValue(true)
    args << merge_geometry_from_osm

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    #assign the user inputs to variables
    source_idf_path = runner.getStringArgumentValue("source_idf_path",user_arguments)
    merge_geometry_from_osm = runner.getBoolArgumentValue("merge_geometry_from_osm",user_arguments)

    #check the source_idf_path for reasonableness
    if source_idf_path == ""
      runner.registerError("No Source IDF File Path was Entered.")
      return false
    end

    #this is used to clone objects from generated idf to source idf
    def insert_object(object, map)
      if map[object.handle.to_s].nil?
        map[object.handle.to_s] = object
      end
    end

    #get the source idf model path and error if empty
    #source_idf_path = OpenStudio::Path.new(source_idf_path)
    if not File.exists?(source_idf_path)
      runner.registerError("File #{source_idf_path} does not exist.")
      return false
    end

    #get model from path and error if empty
    source_idf = OpenStudio::Workspace::load(OpenStudio::Path.new(source_idf_path))
    if source_idf.empty?
      runner.registerError("Cannot load #{source_idf_path}")
      return false
    end
    source_idf = source_idf.get

    #todo - use this to preserve links of source idf objects to zones and surfaces.
    #to preserve links I need to get an IdfFile from Workspace
    source_idfFile = source_idf.toIdfFile()

    #get source_idf surfaces
    source_idf_BuildingSurfaces = source_idfFile.getObjectsByType("BuildingSurface_Detailed".to_IddObjectType)

    #reporting initial condition of model
    runner.registerInitialCondition("The source IDF has #{source_idf_BuildingSurfaces.size} BuildingSurface_Detail objects.")

    if merge_geometry_from_osm == true

      #remove geometry objects supported by OpenStudio

      #todo - see if there is a way to preserve links in objects that refer to surfaces of same name that end up getting added back later
      source_idf_BuildingSurfaces.each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("FenestrationSurface_Detailed".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Shading_Zone_Detailed".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Shading_Building_Detailed".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Shading_Site_Detailed".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end

      #remove geometry not supported by OpenStudio that will have been converted to a supported type on forward
      source_idfFile.getObjectsByType("Wall_Detailed".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("RoofCeiling_Detailed".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Floor_Detailed".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Wall_Exterior".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Wall_Adiabatic".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Wall_Underground".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Wall_Interzone".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Roof".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Ceiling_Adiabatic".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Ceiling_Interzone".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Floor_GroundContact".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Floor_Adiabatic".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Floor_Interzone".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Window".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Door".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("GlazedDoor".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Window_Interzone".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Door_Interzone".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("GlazedDoor_Interzone".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Shading_Site".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Shading_Building".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Shading_Overhang".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Shading_Overhang_Projection".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Shading_Fin".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end
      source_idfFile.getObjectsByType("Shading_Fin_Projection".to_IddObjectType).each do |object|
        source_idfFile.removeObject(object);
      end

      #not removing internal mass objects because the user may want to keep these independent of the geometry.

      #rename thermal zones without " ThermalZone"
      #eventually it would be nice of reverse translation didn't rename the thermal zone. Then we can remove this
      workspace.getObjectsByType("Zone".to_IddObjectType).each do |object|
        thermalZoneName = object.getString(0).get
        thermalZoneName = thermalZoneName.gsub(' Thermal Zone', '')
        object.setString(0, thermalZoneName)
      end

      # map of handle to idf object that we want to add
      objectsToAdd = Hash.new

      #array of thermal zones in source_idf
      thermalZonesInSourceIdf = []
      source_idfFile.getObjectsByType("Zone".to_IddObjectType).each do |object|
        thermalZonesInSourceIdf << object.getString(0).get
      end

      #array of thermal zones in generated idf
      thermalZonesInGeneratedIdf = []
      workspace.getObjectsByType("Zone".to_IddObjectType).each do |object|
        thermalZonesInGeneratedIdf << object.getString(0).get
      end

      #remove all zones. Will be added from workspace with updated origin and rotation
      #using source_idfFile instead of source_idf (workspace)so objects don't loose link to zones
      source_idfFile.getObjectsByType("Zone".to_IddObjectType).each do |object|
        if not thermalZonesInGeneratedIdf.include? object.getString(0).get
          runner.registerInfo("Removing #{object.getString(0).get} from the idf. This zone was in the source idf but not the generated idf.")
          source_idfFile.removeObject(object);
        else
          source_idfFile.removeObject(object);
        end
      end

      #clone all zones geometry from generated idf into source idf
      #add any zones from generated idf into source idf
      workspace.getObjectsByType("Zone".to_IddObjectType).each do |object|
        if not thermalZonesInSourceIdf.include? object.getString(0).get
          insert_object(object, objectsToAdd)
          runner.registerInfo("Adding #{object.getString(0).get} to the idf. This zone was not in the source idf but was in the generated idf.")
        else
          insert_object(object, objectsToAdd)
        end
      end
      workspace.getObjectsByType("BuildingSurface_Detailed".to_IddObjectType).each do |object|
        insert_object(object, objectsToAdd)
      end
      workspace.getObjectsByType("FenestrationSurface_Detailed".to_IddObjectType).each do |object|
        insert_object(object, objectsToAdd)
      end
      workspace.getObjectsByType("Shading_Zone_Detailed".to_IddObjectType).each do |object|
        insert_object(object, objectsToAdd)
      end
      workspace.getObjectsByType("Shading_Building_Detailed".to_IddObjectType).each do |object|
        insert_object(object, objectsToAdd)
      end
      workspace.getObjectsByType("Shading_Site_Detailed".to_IddObjectType).each do |object|
        insert_object(object, objectsToAdd)
      end

      #not adding internal mass objects for now, but this could be added later.
      #If we do add this need to think about round trip workflow since we don't strip these objects out of the source_idf

      # create a list of objects to add
      objects = OpenStudio::IdfObjectVector.new
      objectsToAdd.values.each do |object|
        idfObject = object.idfObject()
        objects << idfObject
      end

      #add the objects to the source_idf
      source_idfFile.addObjects(objects)

      #store building rotation from generated model
      building = workspace.getObjectsByType("Building".to_IddObjectType)
      building_rotation = building[0].getString(1).get

      #apply rotation to source idf
      building = source_idfFile.getObjectsByType("Building".to_IddObjectType)
      building_rotation = building[0].setString(1,building_rotation)

    end #end of if merge_geometry_from_osm == true

    #removing everything from workspace
    workspace.objects.each do |object|
      object.remove
    end

    # map of handle to idf object that we want to add
    objectsToAddFromSourceIDF = Hash.new

    #make new workspace objects from source_idf
    source_idfFile.objects.each do |object|
      insert_object(object, objectsToAddFromSourceIDF)
    end

    #create a list of objects to add
    objects = OpenStudio::IdfObjectVector.new
    objectsToAddFromSourceIDF.values.each do |idfObject|
      #idfObject = object.idfObject()
      objects << idfObject
    end

    #add the objects to the final idf
    workspace.addObjects(objects)

    #get source_idf surfaces
    final_idf_BuildingSurfaces = workspace.getObjectsByType("BuildingSurface_Detailed".to_IddObjectType)

    #reporting final condition of model
    runner.registerFinalCondition("The resulting IDF has #{final_idf_BuildingSurfaces.size} BuildingSurface_Detail objects.")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
InjectOsmGeometryIntoAnExternalIdf.new.registerWithApplication