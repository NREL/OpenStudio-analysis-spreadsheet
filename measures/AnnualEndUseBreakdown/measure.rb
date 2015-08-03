require 'erb'

require "#{File.dirname(__FILE__)}/resources/os_lib_reporting"
require "#{File.dirname(__FILE__)}/resources/os_lib_schedules"

#start the measure
class AnnualEndUseBreakdown < OpenStudio::Ruleset::ReportingUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Annual End Use Breakdown"
  end
  
  #define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # todo - add bool arguments to decide what tables to generate, default all to true.

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # get sql, model, and web assets
    setup = OsLib_Reporting.setup(runner)
    model = setup[:model]
    sqlFile = setup[:sqlFile]
    web_asset_path = setup[:web_asset_path]

    # create an array of tables to loop through in erb file
    @tables = []

    # get general building information
    @tables <<  OsLib_Reporting.general_building_information_table(model,sqlFile,runner)

    # get space type breakdown table and pie chart
    @tables << OsLib_Reporting.output_data_space_type_breakdown_table(model,sqlFile,runner)

    # get end use table and pie chart
    @tables << OsLib_Reporting.output_data_end_use_table_pie_data(model,sqlFile,runner)

    # get end use by electricity table and pie chart
    @tables << OsLib_Reporting.output_data_end_use_electricity_table_pie_data(model,sqlFile,runner)

    # get end use by gas table and pie chart
    @tables << OsLib_Reporting.output_data_end_use_gas_table_pie_data(model,sqlFile,runner)

    # get end use table and pie chart
    @tables << OsLib_Reporting.output_data_energy_use_table_pie_data(model,sqlFile,runner)

    # get advisory messages table
    @tables << OsLib_Reporting.advisory_messages_table(model,sqlFile,runner)

    # get space type detail table
    @tables << OsLib_Reporting.output_data_space_type_details_table(model,sqlFile,runner)

    # todo - could be nice to add story summary, area per story, count of zones and spaces. Should list air loops on that story, or should air loop list stories it is used on

    # air loop summary
    @tables << OsLib_Reporting.output_data_air_loops_table(model,sqlFile,runner)

    # plant loop summary
    @tables << OsLib_Reporting.output_data_plant_loops_table(model,sqlFile,runner)

    # zone equipment summary
    @tables << OsLib_Reporting.output_data_zone_equipment_table(model,sqlFile,runner)

    # get fenestration data table
    @tables << OsLib_Reporting.fenestration_data_table(model,sqlFile,runner)

    # summary of exterior constructions used in the model for base surfaces
    @tables << OsLib_Reporting.surface_data_table(model,sqlFile,runner)

    # summary of exterior constructions used in the model for sub surfaces
    @tables << OsLib_Reporting.sub_surface_data_table(model,sqlFile,runner)

    # create table for service water heating
    @tables << OsLib_Reporting.water_use_data_table(model,sqlFile,runner)

    # todo - update this to be custom load table, ad user arg with default string of "Elev"
    # elevators from model
    #@tables << OsLib_Reporting.elevator_data_table(model,sqlFile,runner)

    # create table for exterior lights
    @tables << OsLib_Reporting.exterior_light_data_table(model,sqlFile,runner)

    #reporting final condition
    runner.registerInitialCondition("Gathering data from EnergyPlus SQL file and OSM model.")

    # create excel file (todo - turn back on once support gem)
    #book = OsLib_Reporting.create_xls()
    #@tables.each do |table|
    #  my_data = OsLib_Reporting.write_xls(table,book)
    #end
    #file = OsLib_Reporting.save_xls(book)

    # read in template
    html_in_path = "#{File.dirname(__FILE__)}/resources/report.html.erb"
    if File.exist?(html_in_path)
      html_in_path = html_in_path
    else
      html_in_path = "#{File.dirname(__FILE__)}/report.html.erb"
    end
    html_in = ""
    File.open(html_in_path, 'r') do |file|
      html_in = file.read
    end

    # configure template with variable values
    renderer = ERB.new(html_in)
    html_out = renderer.result(binding)

    # write html file
    html_out_path = "./report.html"
    File.open(html_out_path, 'w') do |file|
      file << html_out
      # make sure data is written to the disk one way or the other
      begin
        file.fsync
      rescue
        file.flush
      end
    end

    #closing the sql file
    sqlFile.close()

    #reporting final condition
    runner.registerFinalCondition("Generated #{html_out_path}.")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AnnualEndUseBreakdown.new.registerWithApplication