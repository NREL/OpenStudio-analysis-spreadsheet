#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"
require "#{File.dirname(__FILE__)}/resources/OsLib_HelperMethods"
require 'fileutils' # need this to access files

#start the measure
class AedgSmallToMediumOfficeSlabAndBasement < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AedgSmallToMediumOfficeSlabAndBasement"
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    # add argument for target (baseline is 90.1 2004)
    choices = OpenStudio::StringVector.new
    choices << "ASHRAE 90.1 2004"
    choices << "AEDG Small To Medium Office - Target"
    target = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("target", choices)
    target.setDisplayName("Slab and Basement Insulation Performance")
    target.setDefaultValue("AEDG Small To Medium Office - Target")
    args << target

    # add argument for slab or basement (set default to slab, although could try and infer from model)
    choices = OpenStudio::StringVector.new
    choices << "Slab"
    choices << "Basement (choose this if you have below grade walls)"
    slabOrBasement = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("slabOrBasement", choices)
    slabOrBasement.setDisplayName("Model Ground Condition.")
    slabOrBasement.setDefaultValue("Slab")
    args << slabOrBasement

    # add argument for slab or basement (set default to slab, although could try and infer from model)
    heatedSlab = OpenStudio::Ruleset::OSArgument::makeBoolArgument("heatedSlab",true)
    heatedSlab.setDisplayName("Heated Slab? (Check this if you plan to add a Radiant System)")
    heatedSlab.setDefaultValue(false)
    args << heatedSlab

    # add argument for climate zone (normally we get this from the model, but can't for E+ measure)
    choices = OpenStudio::StringVector.new
    choices << "1"
    choices << "2"
    choices << "3"
    choices << "4"
    choices << "5"
    choices << "6"
    choices << "7"
    choices << "8"
    climateZone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("climateZone", choices)
    climateZone.setDisplayName("ASHRAE Climate Zone")
    args << climateZone

    # add argument for building area to perimeter ratio for slab (in the future could get this from the model)
    apRatio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("apRatio",true)
    apRatio.setDisplayName("Slab area to perimeter ratio (ft^2/ft).Range is 5.0 ft to 72.0 ft.")
    apRatio.setDefaultValue(32.5)
    args << apRatio

    # add arguments for cost for cost for slab and basement insulation (total dollar amount just added to building?)
    costTotalSlabBasementInsulation = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("costTotalSlabBasementInsulation",true)
    costTotalSlabBasementInsulation.setDisplayName("Total cost related to slab and basement insulation ($).")
    costTotalSlabBasementInsulation.setDefaultValue(0.0)
    args << costTotalSlabBasementInsulation
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # setup arguments
    target = runner.getStringArgumentValue("target",user_arguments)
    if target == "ASHRAE 90.1 2004"
      target = "Baseline"
    else
      target = "Target"
    end
    climateZone = runner.getStringArgumentValue("climateZone",user_arguments)
    slabOrBasement = runner.getStringArgumentValue("slabOrBasement",user_arguments)
    heatedSlab = runner.getBoolArgumentValue("heatedSlab",user_arguments)
    apRatio = OpenStudio::convert(runner.getDoubleArgumentValue("apRatio",user_arguments),"ft","m").get
    costTotalSlabBasementInsulation = runner.getDoubleArgumentValue("costTotalSlabBasementInsulation",user_arguments)

    # test arguments
    OsLib_HelperMethods.checkDoubleArguments(runner,1.5, 22.0,{"Area to Perimeter Ratio" => apRatio})

    # rules (from chapter 4)
    rules = [] #(climate zone, useCase, target, verticalRValue(ip), verticalDepth(inches), horizBelowSlabRValue(ip))

    # baseline
    rules << ["1","BelowGradeWall","Baseline",0,0,0]
    rules << ["1","SlabUnheated","Baseline",0,0,0]
    rules << ["1","SlabHeated","Baseline",7.5,12,0]
    rules << ["2","BelowGradeWall","Baseline",0,0,0]
    rules << ["2","SlabUnheated","Baseline",0,0,0]
    rules << ["2","SlabHeated","Baseline",7.5,12,0]
    rules << ["3","BelowGradeWall","Baseline",0,0,0]
    rules << ["3","SlabUnheated","Baseline",0,0,0]
    rules << ["3","SlabHeated","Baseline",7.5,12,0]
    rules << ["4","BelowGradeWall","Baseline",0,0,0]
    rules << ["4","SlabUnheated","Baseline",0,0,0]
    rules << ["4","SlabHeated","Baseline",7.5,24,0]
    rules << ["5","BelowGradeWall","Baseline",0,0,0]
    rules << ["5","SlabUnheated","Baseline",0,0,0]
    rules << ["5","SlabHeated","Baseline",10,36,0]
    rules << ["6","BelowGradeWall","Baseline",0,0,0]
    rules << ["6","SlabUnheated","Baseline",0,0,0]
    rules << ["6","SlabHeated","Baseline",10,36,0]
    rules << ["7","BelowGradeWall","Baseline",7.5,0,0]
    rules << ["7","SlabUnheated","Baseline",0,0,0]
    rules << ["7","SlabHeated","Baseline",10,36,0]
    rules << ["8","BelowGradeWall","Baseline",7.5,0,0]
    rules << ["8","SlabUnheated","Baseline",10,24,0]
    rules << ["8","SlabHeated","Baseline",10,48,0]

    # target
    rules << ["1","BelowGradeWall","Target",0,0,0]
    rules << ["1","SlabUnheated","Target",0,0,0]
    rules << ["1","SlabHeated","Target",10,24,0] # improved beyond baseline
    rules << ["2","BelowGradeWall","Target",0,0,0]
    rules << ["2","SlabUnheated","Target",0,0,0]
    rules << ["2","SlabHeated","Target",10,24,0] # improved beyond baseline
    rules << ["3","BelowGradeWall","Target",7.5,0,0] # improved beyond baseline
    rules << ["3","SlabUnheated","Target",0,0,0]
    rules << ["3","SlabHeated","Target",15,24,0] # improved beyond baseline
    rules << ["4","BelowGradeWall","Target",7.5,0,0] # improved beyond baseline
    rules << ["4","SlabUnheated","Target",15,24,0] # improved beyond baseline
    rules << ["4","SlabHeated","Target",20,24,0] # improved beyond baseline
    rules << ["5","BelowGradeWall","Target",7.5,0,0] # improved beyond baseline
    rules << ["5","SlabUnheated","Target",15,24,0] # improved beyond baseline
    rules << ["5","SlabHeated","Target",20,24,0] # improved beyond baseline
    rules << ["6","BelowGradeWall","Target",10,0,0] # improved beyond baseline
    rules << ["6","SlabUnheated","Target",20,24,0] # improved beyond baseline
    rules << ["6","SlabHeated","Target",20,48,0] # improved beyond baseline
    rules << ["7","BelowGradeWall","Target",15,0,0] # improved beyond baseline
    rules << ["7","SlabUnheated","Target",20,24,0] # improved beyond baseline
    rules << ["7","SlabHeated","Target",25,48,0] # improved beyond baseline
    rules << ["8","BelowGradeWall","Target",15,0,0] # improved beyond baseline
    rules << ["8","SlabUnheated","Target",20,48,0] # improved beyond baseline
    rules << ["8","SlabHeated","Target",25,48,20] # improved beyond baseline (I used the vertical value of climate zone 7 plus the full slab insulation listed for climate zone 8)

    #make rule hash for cleaner code
    rulesHash = {}
    rules.each do |rule|
      rulesHash["#{rule[0]} #{rule[1]} #{rule[2]}"] = {"verticalRValue_ip" => rule[3], "verticalDepthInches" => rule[4], "horizBelowSlabRValue_ip" => rule[5]}
    end

    # initial condition (return current state of groundHeatTransfer)
    groundHeatTransferControl = workspace.getObjectsByType("GroundHeatTransfer:Control".to_IddObjectType)[0]
    if not groundHeatTransferControl.nil?
      if groundHeatTransferControl.getString(1) == "no" then slabRun = false else slabRun = true end
      if groundHeatTransferControl.getString(2) == "no" then basementRun = false else basementRun = true end
      if slabRun and basementRun
        runner.registerInitialCondition("The initial IDF is configured to run slab and basement.")
      elsif slabRun
        runner.registerInitialCondition("The initial IDF is configured to run slab.")
      elsif basementRun
        runner.registerInitialCondition("The initial IDF is configured to run basement.")
      else
        runner.registerInitialCondition("The initial IDF isn't configured to run slab or basement.")
      end
    else
      runner.registerInitialCondition("The initial IDF isn't configured to run slab or basement.")
    end

    # general variables
    if slabOrBasement == "Slab"
      runBasementPreprocessor = false
    else
      runBasementPreprocessor = true
    end

    # temp hard coded value for wall and slab thickness
    hardCodedThicknessWall = OpenStudio::convert(0.67,"ft","m").get
    hardCodedThicknessFloor = OpenStudio::convert(0.33,"ft","m").get
    hardCodedBasementDepth = OpenStudio::convert(10.0,"ft","m").get
    hardCodedBuildingHeight = OpenStudio::convert(20.0,"ft","m").get

    # slabBldgProps variables
    buildingHeight = hardCodedBuildingHeight # in the future can infer this form the model
    typicalTin = 22.0 # once this is in OSM we can extract schedules
    if heatedSlab
      slabType = "SlabHeated"
    else
      slabType = "SlabUnheated"

    end

    # slabInsulation variables
    rins = OpenStudio::convert(rulesHash["#{climateZone} #{slabType} #{target}"]["horizBelowSlabRValue_ip"],"ft^2*h*R/Btu","m^2*K/W").get # R value of under slab insulation
    if rins > 0
      dins = 30 # todo - do some parametric studies to test if making this too large is an issue.
    else
      dins = 0
    end
    rvins = OpenStudio::convert(rulesHash["#{climateZone} #{slabType} #{target}"]["verticalRValue_ip"],"ft^2*h*R/Btu","m^2*K/W").get # R value of vertical insulation
    zvinsRaw = OpenStudio::convert(rulesHash["#{climateZone} #{slabType} #{target}"]["verticalDepthInches"]/12,"ft","m").get # depth of vertical insulation
    possibleZvinValus = [0.2,0.4,0.6,0.8,1.0,1,5,2.0,2.5,3.0] # this is from slab documentation as possible values
    lowestAbs = nil
    zvins = nil
    if zvinsRaw > 0
      possibleZvinValus.each do |value|
        if lowestAbs
          if lowestAbs > (value-zvinsRaw).abs
            lowestAbs = (value-zvinsRaw).abs
            zvins = value
          end
        else
          lowestAbs = (value-zvinsRaw).abs
          zvins = value
        end
      end
    else
      zvins = 0
    end

    if zvins > 0
      ivins = 1
    else
      ivins = 0
    end

    # slabEquivalentSlab variables
    apRatio = OpenStudio::convert(apRatio,"ft","m").get  # the area to perimeter ratio for this slab (try to infer this)
    slabDepth = hardCodedThicknessFloor # get this from construction (should not exceed 0.25 meters)

    # basementInsulation variables
    rext = OpenStudio::convert(rulesHash["#{climateZone} BelowGradeWall #{target}"]["verticalRValue_ip"],"ft^2*h*R/Btu","m^2*K/W").get # R value of any exterior insulation
    insfull = true # fully insulated walls = "TRUE" half insulated walls = "FALSE"

    # basementBldgData variables
    wallThickness = hardCodedThicknessWall # get this from construction
    # use slabDepth input from slab here

    # apRatio is needed for basementEquivSlap but is defined above for slab

    # basementEquivAutoGrid
    # slabDepth is needed for basementEquivAutoGrid but is defined above for slab
    basementDepth = hardCodedBasementDepth # get this from model

    # monthly avg basement temp  is needed for basementComBldg but is defined above for slab as typicalTin

    # run length variables
    iyrsSlab = 5
    iyrsBasement = 5

    # add NA of model has no ground exposed surfaces
    noGroundExposure = true
    surfaces = workspace.getObjectsByType("BuildingSurface:Detailed".to_IddObjectType)
    surfaces.each do |surface|
      boundaryCondition = surface.getString(4).to_s
      if (boundaryCondition == "OtherSideCoefficients" or boundaryCondition == "Ground")
        noGroundExposure = false
        next
      end
    end
    if noGroundExposure
      runner.registerAsNotApplicable("This model does not appear to have any surfaces with ground exposure.")
      return true
    end

    # check for epw file
    lastEpwFilePath = nil
    if not runner.lastEpwFilePath.empty?
      lastEpwFilePath = runner.lastEpwFilePath.get
      runner.registerInfo("Using lastEpwFilePath specified by runner")
    elsif File.exists?("#{File.dirname(__FILE__)}/in.epw")
      lastEpwFilePath = OpenStudio::Path.new("#{File.dirname(__FILE__)}/in.epw")
      runner.registerInfo("Using EpwFile found in directory")
    else
      runner.registerError("Cannot locate EPW file to use for calculating ground temperatures")
      return false
    end

    # if slab loop
    if not runBasementPreprocessor # then just run slab

      # load the slab objects
      slabIdfPath  = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources/slab.idf")
      slabIdf = OpenStudio::Workspace::load(slabIdfPath).get

      workspace.addObjects(slabIdf.objects)

      # customize arguments based on user inputs
      slabBldgProps = workspace.getObjectsByType("GroundHeatTransfer:Slab:BldgProps".to_IddObjectType)[0]
      slabBldgProps.setString(0,iyrsSlab.to_s)
      slabBldgProps.setString(2,buildingHeight.to_s)

      slabInsulation = workspace.getObjectsByType("GroundHeatTransfer:Slab:Insulation".to_IddObjectType)[0]
      slabInsulation.setString(0,rins.to_s)
      slabInsulation.setString(1,dins.to_s)
      slabInsulation.setString(2,rvins.to_s)
      slabInsulation.setString(3,zvins.to_s)
      slabInsulation.setString(4,ivins.to_s)

      slabEquivalentSlab = workspace.getObjectsByType("GroundHeatTransfer:Slab:EquivalentSlab".to_IddObjectType)[0]
      slabEquivalentSlab.setString(0,apRatio.to_s)
      slabEquivalentSlab.setString(1,slabDepth.to_s)

      # run expand objects
      runDir = OpenStudio::Path.new("#{File.dirname(__FILE__)}/run/")
      idfPath = OpenStudio::Path.new("#{File.dirname(__FILE__)}/run/in.idf")

      runner.registerInfo("Running expandobjects and slab in #{runDir}. This may take a few minutes.")

      if File.exists?(runDir.to_s)
        FileUtils.rm_rf(runDir.to_s)
      end
      FileUtils.mkdir_p(runDir.to_s)
      workspace.save(idfPath, true)

      co = OpenStudio::Runmanager::ConfigOptions.new(true)
      co.findTools(false, true, false, true)
      wf = OpenStudio::Runmanager::Workflow.new("expandobjects->slab")
      wf.add(co.getTools())
      puts "slab: runDir: #{runDir}, idfPath: #{idfPath}, lastEpwFilePath: #{lastEpwFilePath}"
      job = wf.create(runDir, idfPath, lastEpwFilePath)

      rm = OpenStudio::Runmanager::RunManager.new
      rm.enqueue(job, true)
      rm.waitForFinished

      begin
        slabMergedIdfPath = job.treeOutputFiles().getLastByFilename("slabmerged.idf").fullPath
        runner.registerInfo("Found ground temperatures calculated by slab program at #{slabMergedIdfPath}")

        slabMergedIdf = OpenStudio::IdfFile::load(slabMergedIdfPath).get
        runner.registerInfo("Loaded file #{slabMergedIdfPath}")

        # DLM: the following line is not working because the slabmerged.idf file has bad references in it
        #workspace.swap(slabMergedIdf)

        handles = OpenStudio::UUIDVector.new
        workspace.objects.each {|obj| handles << obj.handle}
        workspace.removeObjects(handles)
        runner.registerInfo("Removed all objects in previous file")

        workspace.addObjects(slabMergedIdf.objects)

        # give info about slab inputs that come from rules
        if rins > 0
          runner.registerInfo("Adding insulation with R-value of #{OpenStudio::toNeatString(OpenStudio::convert(zvins,"m^2*K/W","ft^2*h*R/Btu").get,2,true)} (ft^2*h*R/Btu) below the slab.")
        else
          runner.registerInfo("No insulation added below the slab.")
        end
        if rvins > 0
          runner.registerInfo("Adding vertical insulation at slab perimeter with R-value of #{OpenStudio::toNeatString(OpenStudio::convert(rvins,"m^2*K/W","ft^2*h*R/Btu").get,2,true)} (ft^2*h*R/Btu) to a depth of #{OpenStudio::toNeatString(OpenStudio::convert(zvins,"m","ft").get,2,true)} (ft).")
        else
          runner.registerInfo("No vertical insulation added at the slab perimeter.")
        end

      rescue
        runner.registerError("Cannot locate ground temperatures calculated by slab program")
        return false
      end

      runner.registerInfo("Updating ground exposed surface boundary conditions.")

      # this loop is a work around only needed in the GUI. Once bug related to this is fixed this can go away.
      surfaces = workspace.getObjectsByType("BuildingSurface:Detailed".to_IddObjectType)
      surfaces.each do |surface|
        boundaryCondition = surface.getString(4).to_s
        boundaryConditionObject = surface.getString(5).to_s
        if (boundaryCondition == "OtherSideCoefficients" or boundaryCondition == "Ground") and boundaryConditionObject == ""
          surface.setString(4,"OtherSideCoefficients")
          surface.setString(5,"surfPropOthSdCoefSlabAverage")
        end
      end

    else # run basement

      # load the slab objects
      basementIdfPath  = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources/basement.idf")
      basementIdf = OpenStudio::Workspace::load(basementIdfPath).get

      workspace.addObjects(basementIdf.objects)

      # customize arguments based on user inputs
      basementSimParameters = workspace.getObjectsByType("GroundHeatTransfer:Basement:SimParameters".to_IddObjectType)[0]
      basementSimParameters.setString(1,iyrsBasement.to_s)

      basementInsulation = workspace.getObjectsByType("GroundHeatTransfer:Basement:Insulation".to_IddObjectType)[0]
      basementInsulation.setString(0,rext.to_s)

      basementBldgData = workspace.getObjectsByType("GroundHeatTransfer:Basement:BldgData".to_IddObjectType)[0]
      basementBldgData.setString(0,wallThickness.to_s)
      basementBldgData.setString(1,slabDepth.to_s)

      basementBldgData = workspace.getObjectsByType("GroundHeatTransfer:Basement:BldgData".to_IddObjectType)[0]
      basementBldgData.setString(0,wallThickness.to_s)
      basementBldgData.setString(1,slabDepth.to_s)

      basementEquivSlab = workspace.getObjectsByType("GroundHeatTransfer:Basement:EquivSlab".to_IddObjectType)[0]
      basementEquivSlab.setString(0,apRatio.to_s)

      basementEquivAutoGrid = workspace.getObjectsByType("GroundHeatTransfer:Basement:EquivAutoGrid".to_IddObjectType)[0]
      basementEquivAutoGrid.setString(1,slabDepth.to_s)
      basementEquivAutoGrid.setString(1,basementDepth.to_s)

      # todo - see if I can control slab insulation in basement tool. Does it have to insulate everything, or can I also run slab. I thought they woudl interact too much to run both of them.

      # run expand objects
      runDir = OpenStudio::Path.new("#{File.dirname(__FILE__)}/run/")
      idfPath = OpenStudio::Path.new("#{File.dirname(__FILE__)}/run/in.idf")

      runner.registerInfo("Running expandobjects and basement in #{runDir}. This may take a few minutes.")

      if File.exists?(runDir.to_s)
        FileUtils.rm_rf(runDir.to_s)
      end
      FileUtils.mkdir_p(runDir.to_s)
      workspace.save(idfPath, true)

      co = OpenStudio::Runmanager::ConfigOptions.new(true)
      co.findTools(false, true, false, true)
      wf = OpenStudio::Runmanager::Workflow.new("expandobjects->basement")
      wf.add(co.getTools())
      puts "basement: runDir: #{runDir}, idfPath: #{idfPath}, lastEpwFilePath: #{lastEpwFilePath}"
      job = wf.create(runDir, idfPath, lastEpwFilePath)

      rm = OpenStudio::Runmanager::RunManager.new
      rm.enqueue(job, true)
      rm.waitForFinished

      begin
        basementMergedIdfPath = job.treeOutputFiles().getLastByFilename("basementmerged.idf").fullPath
        runner.registerInfo("Found ground temperatures calculated by basement program at #{basementMergedIdfPath}")

        basementMergedIdf = OpenStudio::IdfFile::load(basementMergedIdfPath).get
        runner.registerInfo("Loaded file #{basementMergedIdfPath}")

        # DLM: the following line is not working because the basementmerged.idf file has bad references in it
        #workspace.swap(basementMergedIdf)

        handles = OpenStudio::UUIDVector.new
        workspace.objects.each {|obj| handles << obj.handle}
        workspace.removeObjects(handles)
        runner.registerInfo("Removed all objects in previous file")

        workspace.addObjects(basementMergedIdf.objects)

        # give info about slab inputs that come from rules
        if rext > 0
          runner.registerInfo("Adding insulation with R-value of #{OpenStudio::toNeatString(OpenStudio::convert(rext,"m^2*K/W","ft^2*h*R/Btu").get,2,true)} (ft^2*h*R/Btu) to below grade walls.")
        else
          runner.registerInfo("No below grade wall insulation added.")
        end

      rescue
        runner.registerError("Cannot locate ground temperatures calculated by basement program")
        return false
      end

      runner.registerInfo("Updating ground exposed surface boundary conditions.")

      # need to find surfaces with outside boundary condition of "OtherSideCoefficients boundary condition but that do not have a boundary object. Then pick either avg wall or floor depending on surface type.
      #get all BuildingSurface:Detailed objects in model
      surfaces = workspace.getObjectsByType("BuildingSurface:Detailed".to_IddObjectType)

      surfaces.each do |surface|
        boundaryCondition = surface.getString(4).to_s
        boundaryConditionObject = surface.getString(5).to_s
        if (boundaryCondition == "OtherSideCoefficients" or boundaryCondition == "Ground") and boundaryConditionObject == ""
          surface.setString(4,"OtherSideCoefficients") # for some reason this seems necessary in GUI, but not in ruby test.
          surfaceType = surface.getString(1)
          if surfaceType.to_s == "Floor"
            surface.setString(5,"surfPropOthSdCoefBasementAvgFloor")
          elsif surfaceType.to_s == "Wall"
            surface.setString(5,"surfPropOthSdCoefBasementAvgWall")
          else # should be Ceiling
            surface.setString(5,"surfPropOthSdCoefBasementAvgCeiling") # I don't know for sure that ths is right. My test model doesn't make this
          end
        end
      end

    end

    # populate AEDG tip keys
    aedgTips = []
    aedgTips.push("EN09","EN12","EN13","EN14","EN17","EN19","EN21","EN22")

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips("SmMdOff",aedgTips.uniq.sort,runner)
    if not aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    #add mat cost
    if costTotalSlabBasementInsulation > 0
      lcc_mat_string = "
        LifeCycleCost:RecurringCosts,
          LCC_Mat - slab and basement insulation, !- Name
          Replacement,                            !- Category
          #{costTotalSlabBasementInsulation},                       !- Cost
          ServicePeriod,                          !- Start of Costs
          0,                                      !- Years from Start
          ,                                       !- Months from Start
          ;                                       !- Repeat Period Years
          "
      idfObject = OpenStudio::IdfObject::load(lcc_mat_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      lcc_mat = wsObject.get
      finalCost = lcc_mat.getString(2)
    else
      finalCost = 0
    end

    # final condition
    if runBasementPreprocessor
      runner.registerFinalCondition("The basement pre-processor was run for #{OpenStudio::toNeatString(iyrsBasement,0,true)} years at a cost of $#{finalCost}. aedgTipsLong")
    else
      runner.registerFinalCondition("The slab pre-processor was run for #{OpenStudio::toNeatString(iyrsSlab,0,true)} years at a cost of $#{finalCost}. aedgTipsLong")
    end


    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AedgSmallToMediumOfficeSlabAndBasement.new.registerWithApplication