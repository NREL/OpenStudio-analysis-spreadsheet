require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'fileutils'

require 'test/unit'

class XcelEDAReportingandQAQC_Test < Test::Unit::TestCase
    
  # paths to expected test files, includes osm and eplusout.sql
  def modelPath
    return "#{File.dirname(__FILE__)}/0116_OfficeTest121_dev.osm" #while this seems un-necessary, the reporting measure will fail if it can't find the model.
  end

  def runDir
    return "#{File.dirname(__FILE__)}/0116_OfficeTest121_dev/"
  end

  def idfPath
    return "#{File.dirname(__FILE__)}/0116_OfficeTest121_dev/ModelToIdf/in.idf"
  end

  def epwPath
    return "#{File.dirname(__FILE__)}/0116_OfficeTest121_dev/Files/USA_CO_Golden-NREL.724666_TMY3.epw"
  end

  def resultsPath
    return "#{File.dirname(__FILE__)}/0116_OfficeTest121_dev/EnergyPlusPreProcess/"
  end

  def sqlPath
    return "#{File.dirname(__FILE__)}/0116_OfficeTest121_dev/EnergyPlusPreProcess/EnergyPlus-0/eplusout.sql"
  end
  
  def reportPath
    return "./report.xml"
  end

  def reportPath2
    return "#{File.dirname(__FILE__)}/report.xml"
  end

  # create test files if they do not exist
  def setup

    if File.exist?(reportPath())
      FileUtils.rm(reportPath())
    end

    assert(File.exist?(idfPath()))
    
    assert(File.exist?(runDir()))
    
    if not File.exist?(sqlPath())
      puts "Running EnergyPlus"
      
      co = OpenStudio::Runmanager::ConfigOptions.new(true)
      co.findTools(false, true, false, true)

      wf = OpenStudio::Runmanager::Workflow.new("energypluspreprocess->energyplus") #removed modeltoidf-> from the beginning so it works with idf source vs. osm.
      wf.add(co.getTools())
      job = wf.create(OpenStudio::Path.new(runDir()), OpenStudio::Path.new(idfPath()), OpenStudio::Path.new(epwPath()))    #added path to epw so E+ knows where to find weather file

      rm = OpenStudio::Runmanager::RunManager.new
      rm.enqueue(job, true)
      rm.waitForFinished
    end
  end

  # delete output files
  def teardown

    # comment this out if you don't want to rerun EnergyPlus each time
    if File.exist?(resultsPath())
      FileUtils.rm_r(resultsPath())
    end
    
    # comment this out if you want to see the resulting report
    if File.exist?(reportPath())
      #FileUtils.rm(reportPath())
    end
  end
  
  # the actual test
  def test_XcelEDAReportingandQAQC
     
    assert(File.exist?(modelPath()))
    assert(File.exist?(sqlPath()))
     
    # create an instance of the measure
    measure = XcelEDAReportingandQAQC.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments()
    assert_equal(0, arguments.size)
    
    # set up runner, this will happen automatically when measure is run in PAT
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(modelPath))
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sqlPath))
       
    # set argument values to good values and run the measure
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    measure.run(runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 0)
    #assert(result.info.size == 1)

    assert(File.exist?(reportPath()))
    #move report.html to measure test folder
    if File.exist?(reportPath())
      FileUtils.mv(reportPath(),reportPath2())
    end

  end  

end
