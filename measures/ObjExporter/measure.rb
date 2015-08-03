# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# start the measure
class ObjExporter < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Obj Exporter"
  end

  # human readable description
  def description
    return "Exports the OpenStudio model in Wavefront OBJ format for viewing in common 3D engines.  One free viewer is available at http://www.open3mod.com/."
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end
  
  def getSurfaceID(surface)
    result = "#{surface.iddObject.name}-#{surface.name}-#{surface.handle}"
    return result.gsub(' ', '_').gsub(':', '_').gsub('{', '').gsub('}', '')
  end
  
  def getMaterial(surface)
    
    result = {}
    result[:surfaceID] = getSurfaceID(surface)
    
    surface_type_color = [255, 255, 255, 1.0]
    boundary_color = [255, 255, 255, 1.0]
    
    if surface.to_Surface.is_initialized
    
      surfaceType = surface.to_Surface.get.surfaceType
      if surfaceType == "Floor"
        surface_type_color = [128, 128, 128, 1.0]
      elsif surfaceType == "Wall"
        surface_type_color = [204, 178, 102, 1.0]
      elsif surfaceType == "RoofCeiling"
        surface_type_color = [153, 76, 76, 1.0]
      end
      
      outsideBoundaryCondition = surface.to_Surface.get.outsideBoundaryCondition
      sunExposure = surface.to_Surface.get.sunExposure
      windExposure = surface.to_Surface.get.windExposure
      if outsideBoundaryCondition == "Adiabatic"
        boundary_color = [255, 101, 178, 1.0]
      elsif outsideBoundaryCondition == "Surface"
        boundary_color = [0, 153, 0, 1.0]
      elsif outsideBoundaryCondition == "Outdoors"
        if sunExposure == "SunExposed" && windExposure == "WindExposed"
          boundary_color = [68, 119, 161, 1.0]
        elsif sunExposure == "SunExposed" 
          boundary_color = [40, 204, 204, 1.0]
        elsif windExposure == "WindExposed" 
          boundary_color = [9, 159, 162, 1.0]
        else
          boundary_color = [163, 204, 204, 1.0]
        end
      elsif outsideBoundaryCondition == "Ground"
        boundary_color = [204, 183, 122, 1.0]
      elsif outsideBoundaryCondition == "GroundFCfactorMethod"
        boundary_color = [153, 122, 30, 1.0]
      elsif outsideBoundaryCondition == "OtherSideCoefficients"
        boundary_color = [63, 63, 63, 1.0]
      elsif outsideBoundaryCondition == "OtherSideConditionsModel"
        boundary_color = [153, 0, 76, 1.0]
      elsif outsideBoundaryCondition == "GroundSlabPreprocessorAverage"
        boundary_color = [255, 191, 0, 1.0]
      elsif outsideBoundaryCondition == "GroundSlabPreprocessorCore"
        boundary_color = [255, 182, 50, 1.0]
      elsif outsideBoundaryCondition == "GroundSlabPreprocessorPerimeter"
        boundary_color = [255, 178, 101, 1.0]
      elsif outsideBoundaryCondition == "GroundBasementPreprocessorAverageWall"
        boundary_color = [204, 51, 0, 1.0]
      elsif outsideBoundaryCondition == "GroundBasementPreprocessorAverageFloor"
        boundary_color = [204, 81, 40, 1.0]
      elsif outsideBoundaryCondition == "GroundBasementPreprocessorUpperWall"
        boundary_color = [204, 112, 81, 1.0]
      elsif outsideBoundaryCondition == "GroundBasementPreprocessorLowerWall"
        boundary_color = [204, 173, 163, 1.0]
      end
      
    elsif surface.to_SubSurface.is_initialized
    
      subSurfaceType = surface.to_SubSurface.get.subSurfaceType
      if subSurfaceType == "Window" || subSurfaceType == "GlassDoor"
        surface_type_color = [102, 178, 204, 0.6]
      else
        surface_type_color = [153, 133, 76, 0.6]
      end
      
      if surface.to_SubSurface.get.adjacentSubSurface.is_initialized
        boundary_color = [111, 157, 194, 1.0]
      else
        boundary_color = [38, 216, 38, 1.0]
      end
      
    elsif surface.to_ShadingSurface.is_initialized
    
      shadingSurfaceType = ""
      if surface.to_ShadingSurface.get.shadingSurfaceGroup.is_initialized
        shadingSurfaceType = surface.to_ShadingSurface.get.shadingSurfaceGroup.get.shadingSurfaceType
      end
      
      if subSurfaceType == "Site" 
        surface_type_color = [75, 124, 149, 0.6]
      elsif subSurfaceType == "Building"
        surface_type_color = [113, 76, 153, 0.6]
      else
        surface_type_color = [76, 110, 178, 0.6]
      end
      boundary_color = [255, 255, 255, 1.0]
      
    elsif surface.to_InteriorPartitionSurface.is_initialized
    
      surface_type_color = [158, 188, 143, 0.6]
      boundary_color = [255, 255, 255, 1.0]
      
    end

    result[:surface_type_color] = surface_type_color
    result[:boundary_color] = boundary_color
    
    return result
  end
  
  def getVertexIndex(vertex, allVertices, tol = 0.001)
    allVertices.each_index do |i|
      if OpenStudio::getDistance(vertex, allVertices[i]) < tol
        return i + 1
      end
    end
    allVertices << vertex
    return (allVertices.length)
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    z = OpenStudio::Vector.new(3)
    z[0] = 0
    z[1] = 0
    z[2] = 1
    
    allVertices = []
    objVertices = ""
    objFaces = ""
    allMaterials = []

    # all planar surfaces
    model.getPlanarSurfaces.each do |surface|

      # handle sub surfaces later
      next if !surface.to_SubSurface.empty?
    
      surfaceID = getSurfaceID(surface)
      allMaterials << getMaterial(surface)
      
      surfaceVertices = surface.vertices
      t = OpenStudio::Transformation::alignFace(surfaceVertices)
      r = t.rotationMatrix
      tInv = t.inverse
      
      siteTransformation = OpenStudio::Transformation.new
      planarSurfaceGroup = surface.planarSurfaceGroup
      if not planarSurfaceGroup.empty?
        siteTransformation = planarSurfaceGroup.get.siteTransformation
      end
      
      surfaceVertices = tInv*surfaceVertices
      
      subSurfaces = []
      subSurfaceVertices = OpenStudio::Point3dVectorVector.new
      if !surface.to_Surface.empty?
        subSurfaces = surface.to_Surface.get.subSurfaces
        subSurfaces.each do |subSurface|
          subSurfaceVertices << tInv*subSurface.vertices
        end
      end

      triangles = OpenStudio::computeTriangulation(surfaceVertices, subSurfaceVertices)
      if triangles.empty?
        runner.registerWarning("Failed to triangulate #{surface.iddObject.name} #{surface.name} with #{subSurfaces.size} sub surfaces")
      end
      
      objFaces += "##{surface.name}\n"
      objFaces += "g #{surface.name}\n"
      objFaces += "usemtl #{surfaceID}\n"
      triangles.each do |vertices|
        vertices = siteTransformation*t*vertices
        normal = siteTransformation.rotationMatrix*r*z

        indices = []
        vertices.each do |vertex|
          indices << getVertexIndex(vertex, allVertices)
        end
        
        #objFaces += "  usemtl #{surfaceID}\n"
        objFaces += "  f #{indices.join(' ')}\n"
      end
      
      # now do subSurfaces
      subSurfaces.each do |subSurface|
      
        subSurfaceID = getSurfaceID(subSurface)
        allMaterials << getMaterial(subSurface)
        
        subSurfaceVertices = tInv*subSurface.vertices
        triangles = OpenStudio::computeTriangulation(subSurfaceVertices, OpenStudio::Point3dVectorVector.new)

        objFaces += "##{subSurface.name}\n"
        objFaces += "g #{subSurface.name}\n"
        objFaces += "usemtl #{subSurfaceID}\n"
        triangles.each do |vertices|
          vertices = siteTransformation*t*vertices
          normal = siteTransformation.rotationMatrix*r*z

          indices = []
          vertices.each do |vertex|
            indices << getVertexIndex(vertex, allVertices)  
          end    
          #objFaces += "  usemtl #{subSurfaceID}\n"
          objFaces += "  f #{indices.join(' ')}\n"
        end
      end
    end
   
    if objFaces.empty?
      runner.registerError("Model is empty, no output will be written")
      return false
    end

    # write object file
    obj_out_path = "./output.obj"
    File.open(obj_out_path, 'w') do |file|

      file << "# OpenStudio OBJ Export\n\n"
      file << "mtllib surface_type.mtl\n"
      file << "#mtllib boundary_color.mtl\n\n"
      file << "# Vertices\n"
      allVertices.each do |v|
        file << "v #{v.x} #{v.z} #{-v.y}\n"
      end
      file << "\n"
      file << "# Faces\n"
      file << objFaces
      
      # make sure data is written to the disk one way or the other      
      begin
        file.fsync
      rescue
        file.flush
      end
    end
    
    # write material files
    mtl_out_path = "./surface_type.mtl"
    File.open(mtl_out_path, 'w') do |file|

      file << "# OpenStudio Surface Type MTL Export\n"
      allMaterials.each do |material|
        r = material[:surface_type_color][0]/255.to_f
        g = material[:surface_type_color][1]/255.to_f
        b = material[:surface_type_color][2]/255.to_f
        a = material[:surface_type_color][3]
        file << "newmtl #{material[:surfaceID]}\n"
        file << "  Ka #{r} #{g} #{b}\n"
        file << "  Kd #{r} #{g} #{b}\n"
        file << "  Ks #{r} #{g} #{b}\n"
        file << "  Ns 0.0\n"
        file << "  d #{a}\n" # some implementations use 'd' others use 'Tr'
      end
      
      # make sure data is written to the disk one way or the other      
      begin
        file.fsync
      rescue
        file.flush
      end
    end
    
    mtl_out_path = "./boundary_color.mtl"
    File.open(mtl_out_path, 'w') do |file|

      file << "# OpenStudio Surface Type MTL Export\n"
      allMaterials.each do |material|
        r = material[:boundary_color][0]/255.to_f
        g = material[:boundary_color][1]/255.to_f
        b = material[:boundary_color][2]/255.to_f
        a = material[:boundary_color][3]
        file << "newmtl #{material[:surfaceID]}\n"
        file << "  Ka #{r} #{g} #{b}\n"
        file << "  Kd #{r} #{g} #{b}\n"
        file << "  Ks #{r} #{g} #{b}\n"
        file << "  Ns 0.0\n"
        file << "  d #{a}\n" # some implementations use 'd' others use 'Tr'
      end

      # make sure data is written to the disk one way or the other      
      begin
        file.fsync
      rescue
        file.flush
      end
    end
    
    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")

    return true

  end
  
end

# register the measure to be used by the application
ObjExporter.new.registerWithApplication
