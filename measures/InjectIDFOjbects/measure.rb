#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#start the measure
class InjectIDFOjbects < OpenStudio::Ruleset::WorkspaceUserScript

  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return " Inject IDF Ojbects"
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # make an argument for your name
    source_idf_path = OpenStudio::Ruleset::OSArgument::makeStringArgument("source_idf_path",true)
    source_idf_path.setDisplayName("Path to Source IDF File to Use.")
    args << source_idf_path

    return args
  end #end the arguments method

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # assign the user inputs to variables
    source_idf_path = runner.getStringArgumentValue("source_idf_path",user_arguments)

    # report initial condtion
    runner.registerInitialCondition("The initial IDF file had #{workspace.objects.size} objects.")

    # load the idf file
    if source_idf_path == ""
      runner.registerError("No Source IDF File Path was Entered.")
      return false
    elsif not File.exists?(source_idf_path)
      runner.registerError("File #{source_idf_path} does not exist.")
      return false
    elsif OpenStudio::IdfFile::load(OpenStudio::Path.new(source_idf_path)).empty?
      runner.registerError("Cannot load #{source_idf_path}")
      return false
    else
      # use OpenStudio::IdfFile instead of OpenStudio::Workspace so links to objects not in IDF will be maintained
      source_idf = OpenStudio::IdfFile::load(OpenStudio::Path.new(source_idf_path)).get
    end

    # add everything from the file
    workspace.addObjects(source_idf.objects)

    # report final condition
    runner.registerFinalCondition("The final IDF file had #{workspace.objects.size} objects.")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
InjectIDFOjbects.new.registerWithApplication