#see the URL below for information on how to write OpenStuido measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"

#start the measure
class TariffSelectionGeneric < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return " Tariff Selection-Generic"
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # possible tariffs
    meters = {}

    # todo list files in resources directory and bin by meter of tariff object
    tariff_files = Dir.entries("#{File.dirname(__FILE__)}/resources")
    tariff_files.each do |tar|

      next if not tar.include?(".idf")

      #load the idf file containing the electric tariff
      tar_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources/#{tar}")
      tar_file = OpenStudio::IdfFile::load(tar_path)

      #in OpenStudio PAT in 1.1.0 and earlier all resource files are moved up a directory.
      #below is a temporary workaround for this before issuing an error.
      if tar_file.empty?
        tar_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{tar}")
        tar_file = OpenStudio::IdfFile::load(tar_path)
      end

      if tar_file.empty?
        puts "Unable to find the file #{tar}"
      else
        tar_file = tar_file.get

        #get the tariff object and the requested meter
        tariff_object = tar_file.getObjectsByType("UtilityCost:Tariff".to_IddObjectType)
        if tariff_object.size > 1
          puts "0nly expected on tarif object in #{tar} but got #{tariff_object.size}"
        elsif tariff_object == 0
          puts "Expected on tarif object in #{tar} but got #{tariff_object.size}"
        else
          tariff_name = tariff_object[0].getString(0).get
          tariff_meter = tariff_object[0].getString(1).get
        end

        # populate hash with tariff object
        meters[tar.gsub(".idf","")] = tariff_meter

      end
    end

    # make an argument for each meter value found in the hash
    meters.values.uniq.each do |meter|
      choices = meters.select{|key, value| value == meter}

      # make a choice argument for tariff
      chs = []
      choices.each do |k,v|
        chs << k
      end
      # todo - these will need to be unique names
      tar = OpenStudio::Ruleset::OSArgument::makeChoiceArgument(meter, chs, true)
      tar.setDisplayName("Select a Tariff for #{meter}.")
      tar.setDefaultValue(chs[0])
      args << tar

    end
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    args  = OsLib_HelperMethods.createRunVariables(runner, workspace,user_arguments, arguments(workspace))
    if !args then return false end

    # reporting initial condition of model
    starting_tariffs = workspace.getObjectsByType("UtilityCost:Tariff".to_IddObjectType)
    runner.registerInitialCondition("The model started with #{starting_tariffs.size} tariff objects.")

    # loop though args to make tariff for each one
    args.each do |k,v|

      #load the idf file containing the electric tariff
      tar_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources/#{v}.idf")
      tar_file = OpenStudio::IdfFile::load(tar_path)

      #in OpenStudio PAT in 1.1.0 and earlier all resource files are moved up a directory.
      #below is a temporary workaround for this before issuing an error.
      if tar_file.empty?
        tar_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{v}.idf")
        tar_file = OpenStudio::IdfFile::load(tar_path)
      end

      if tar_file.empty?
        runner.registerError("Unable to find the file #{v}.idf")
        return false
      else
        tar_file = tar_file.get
      end

      # add everything from the file
      workspace.addObjects(tar_file.objects)

      #let the user know what happened
      runner.registerInfo("added a #{k} tariff from #{v}.idf")

    end
    
    #set the simulation timestep to 15min (4 per hour) to match the demand window of the tariffs
    if not workspace.getObjectsByType("Timestep".to_IddObjectType).empty?
      initial_timestep =  workspace.getObjectsByType("Timestep".to_IddObjectType)[0].getString(0)
      if not initial_timestep.to_s == "4"
        workspace.getObjectsByType("Timestep".to_IddObjectType)[0].setString(0,"4")
        runner.registerInfo("Changing the simulation timestep to 4 timesteps per hour from #{initial_timestep} per hour to match the demand window of the tariffs")
      end
    else
      # add a timestep object to the workspace
      new_object_string = "
      Timestep,
        4;                                      !- Number of Timesteps per Hour
        "
      idfObject = OpenStudio::IdfObject::load(new_object_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_object = wsObject.get
      runner.registerInfo("No timestep object found. Added a new timestep object set to 4 timesteps per hour")
    end

    # report final condition of model
    finishing_tariffs = workspace.getObjectsByType("UtilityCost:Tariff".to_IddObjectType)
    runner.registerFinalCondition("The model finished with #{finishing_tariffs.size} tariff objects.")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
TariffSelectionGeneric.new.registerWithApplication









