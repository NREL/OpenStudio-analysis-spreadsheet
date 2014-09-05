require 'erb'

#start the measure
class AnnualEndUseBreakdown < OpenStudio::Ruleset::ReportingUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AnnualEndUseBreakdown"
  end
  
  #define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # get the last model and sql file
    
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get
    
    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    web_asset_path = OpenStudio::getSharedResourcesPath() / OpenStudio::Path.new("web_assets")

    def neat_numbers(number, roundto = 2) #round to 0 or 2)
                                          # round to zero or two decimals
      if roundto == 2
        number = sprintf "%.2f", number
      else
        number = number.round
      end
      #regex to add commas
      number.to_s.reverse.gsub(%r{([0-9]{3}(?=([0-9])))}, "\\1,").reverse
    end #end def pretty_numbers

    # unit conversion flag
    # this measure assumes tabular data comes in as si units, and only needs to be converted if user wants si
    units = "ip"  #expected values are "si" or "ip"

    # output title
    output_gen = "\""
    output_gen << "<b>General Building Information </b><br>"

    # net site energy
    if units == "si"
      output_gen << "Net Site Energy = " << neat_numbers(OpenStudio::convert(sqlFile.netSiteEnergy.get,"GJ","MJ").get,0) << " (MJ)<br>" 
    else
      output_gen << "Net Site Energy = " << neat_numbers(OpenStudio::convert(sqlFile.netSiteEnergy.get,"GJ","kBtu").get,0) << " (kBtu)<br>" 
    end

    # total building area
    query = "SELECT Value FROM tabulardatawithstrings WHERE "
    query << "ReportName='AnnualBuildingUtilityPerformanceSummary' and " # Notice no space in SystemSummary
    query << "ReportForString='Entire Facility' and "
    query << "TableName='Building Area' and "
    query << "RowName='Total Building Area' and "
    query << "ColumnName='Area' and "
    query << "Units='m2';"
    query_results = sqlFile.execAndReturnFirstDouble(query)
    if query_results.empty?
      runner.registerError("Did not find value for total building area.")
      return false
    else
      if units == "si"
        output_gen << "Total Building Area: #{neat_numbers(query_results.get,0)}" << " (m2)<br>"
      else
        output_gen << "Total Building Area: #{neat_numbers(OpenStudio::convert(query_results.get,"m^2","ft^2").get,0)}" << " (ft2)<br>"
      end
    end

    #EUI
    eui =  sqlFile.netSiteEnergy.get / query_results.get
    if units == "si"
      output_gen << "EUI: #{neat_numbers(OpenStudio::convert(eui,"GJ/m^2","MJ/m^2").get)}" << " (MJ/m2)<br>"
      eui_final_con = "EUI: #{neat_numbers(OpenStudio::convert(eui,"GJ/m^2","MJ/m^2").get)}" << " (MJ/m2)<br>"
    else
      output_gen << "EUI: #{neat_numbers(OpenStudio::convert(eui,"GJ/m^2","kBtu/ft^2").get)}" << " (kBtu/ft2)<br>"
      eui_final_con = "EUI: #{neat_numbers(OpenStudio::convert(eui,"GJ/m^2","kBtu/ft^2").get)}" << " (kBtu/ft2)<br>"
    end

    # extra line break
    output_gen << "<br>"
    output_gen << "\""

    # output title
    output_spaceType = "\""
    output_spaceType << "<b>Space Type Breakdown</b><br>"

    # create array for space type graph data
    data_spaceType = []

    spaceTypes = model.getSpaceTypes

    spaceTypes.sort.each do |spaceType|
      if spaceType.floorArea > 0

        # get color
        color = spaceType.renderingColor
        if not color.empty?
          color = color.get
          red = color.renderingRedValue
          green = color.renderingGreenValue
          blue = color.renderingBlueValue
        else
          rgb = [20,20,20] #maybe do random or let d3 pick color instead of this?
        end

        if units == "si"
          output_spaceType << "#{spaceType.name.get}: #{neat_numbers(spaceType.floorArea,0)} (m2)<br>"
          temp_array = ['{"label":"',spaceType.name.get,'", "value":',spaceType.floorArea,', "red":"',red,'"',', "green":"',green,'"',', "blue":"',blue,'"','}']
        else
          output_spaceType << "#{spaceType.name.get}: #{neat_numbers(OpenStudio::convert(spaceType.floorArea,"m^2","ft^2").get,0)} (ft2)<br>"
          temp_array = ['{"label":"',spaceType.name.get,'", "value":',OpenStudio::convert(spaceType.floorArea,"m^2","ft^2"),', "red":"',red,'"',', "green":"',green,'"',', "blue":"',blue,'"','}']
        end
        data_spaceType << temp_array.join
      end
    end

    spaces = model.getSpaces

    #count area of spaces that have no space type
    noSpaceTypeAreaCounter = 0

    spaces.each do |space|
      if space.spaceType.empty?
        noSpaceTypeAreaCounter = noSpaceTypeAreaCounter + space.floorArea
      end
    end

    if noSpaceTypeAreaCounter > 0
      if units == "si"
        output_spaceType << "No SpaceType Assigned: #{neat_numbers(noSpaceTypeAreaCounter,0)} (m2) <br>"
        temp_array = ['{"label":"','No SpaceType Assigned','", "value":',noSpaceTypeAreaCounter,', "red": 240, "green": 240, "blue": 240}']
      else
        output_spaceType << "No SpaceType Assigned: #{neat_numbers(OpenStudio::convert(noSpaceTypeAreaCounter,"m^2","ft^2").get,0)} (ft2)<br>"
        temp_array = ['{"label":"','No SpaceType Assigned','", "value":',OpenStudio::convert(noSpaceTypeAreaCounter,"m^2","ft^2"),', "red": 240, "green": 240, "blue": 240}']
      end
      data_spaceType << temp_array.join
    end

    # extra line break
    output_spaceType << "<br>"
    output_spaceType << "\""
    data_spaceType_merge = data_spaceType.join(",")

    # output title
    output_endUse = "\""
    output_endUse << "<b>LEED Summary - EAp2-18. End Use Percentage</b><br>"

    # create array for end use graph data
    data_endUse = []

    # list of lead end uses
    endUseLeedCats = []
    endUseLeedCats << "Interior Lighting"
    endUseLeedCats << "Space Heating"
    endUseLeedCats << "Space Cooling"
    endUseLeedCats << "Fans-Interior"
    endUseLeedCats << "Service Water Heating"
    endUseLeedCats << "Receptacle Equipment"
    endUseLeedCats << "Miscellaneous"

    #list of colors per end uses matching standard report
    endUseLeedCatColors = []
    endUseLeedCatColors << "#F7DF10" # interior lighting
    endUseLeedCatColors << "#EF1C21" # heating
    endUseLeedCatColors << "#0071BD" # cooling
    endUseLeedCatColors << "#FF79AD" # fans
    endUseLeedCatColors << "#FFB239" # water systems
    endUseLeedCatColors << "#4A4D4A" # interior equipment
    endUseLeedCatColors << "#669933" # misc - not from standard report

    # loop through end uses from LEED end use percentage table
    endUseLeedCats.length.times do |i|
      # Retrieve end use percentages from LEED table
      query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='LEEDsummary' and RowName= '#{endUseLeedCats[i]}' and ColumnName='Percent' and Units='%';"
      endUseLeedValue = sqlFile.execAndReturnFirstDouble(query)
      if endUseLeedValue.empty?
        runner.registerError("Did not find value for #{endUseLeedCats[i]}.")
        return false
      else
        output_endUse << "#{endUseLeedCats[i]}: #{endUseLeedValue.get}" << " (%)<br>"
        if endUseLeedValue.get > 0
          temp_array = ['{"label":"',endUseLeedCats[i],'", "value":',endUseLeedValue.get,', "color":"',endUseLeedCatColors[i],'"}']
          data_endUse << temp_array.join
        end
      end
    end # endUseLeedCats.each do

    # extra line break
    output_endUse << "<br>"
    output_endUse << "\""
    data_endUse_merge = data_endUse.join(",")

    # output title
    output_energyUse = "\""
    output_energyUse << "<b>LEED Summary - EAp2-6. Energy Use Summary</b><br>"

    # create array for end use graph data
    data_energyUse = []

    # list of lead end uses
    energyUseLeedCats = []
    energyUseLeedCats << "Electricity"
    energyUseLeedCats << "Natural Gas"
    energyUseLeedCats << "Additional"
    #energyUseLeedCats << "Total"

    # loop through end uses from LEED end use percentage table
    energyUseLeedCats.each do |energyUseLeedCat|
      # Retrieve end use percentages from LEED table
      query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='LEEDsummary' and RowName= '#{energyUseLeedCat}' and ColumnName='Total Energy Use' and Units='GJ';"
      energyUseLeedValue = sqlFile.execAndReturnFirstDouble(query)
      if energyUseLeedValue.empty?
        runner.registerError("Did not find value for #{energyUseLeedCat}.")
        return false
      else
        if units == "si"
          output_energyUse << "#{energyUseLeedCat}: #{neat_numbers(OpenStudio::convert(energyUseLeedValue.get,"GJ","MJ").get,0)}" << " (MJ)<br>"
        else
          output_energyUse << "#{energyUseLeedCat}: #{neat_numbers(OpenStudio::convert(energyUseLeedValue.get,"GJ","kBtu").get,0)}" << " (kBtu)<br>"
        end
        if energyUseLeedValue.get > 0
          temp_array = ['{"label":"',energyUseLeedCat,'", "value":',energyUseLeedValue.get,'}']
          data_energyUse << temp_array.join
        end
      end
    end # energyUseLeedCats.each do

    # extra line break
    output_energyUse << "<br>"
    output_energyUse << "\""
    data_energyUse_merge = data_energyUse.join(",")

    # create strign for LEED advisories
    advisoriesLeed = []
    advisoriesLeed << "Number of hours heating loads not met"
    advisoriesLeed << "Number of hours cooling loads not met"
    advisoriesLeed << "Number of hours not met"

    # output title
    output_advisory = "\""
    output_advisory << "<b>LEED Summary - EAp2-2. Advisory Messages</b><br>"

    # loop through advisory messages
    advisoriesLeed.each do |advisoryLeed|
      # Retrieve end use percentages from LEED table
      query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='LEEDsummary' and RowName= '#{advisoryLeed}' and ColumnName='Data';"
      advisoryLeedValue = sqlFile.execAndReturnFirstDouble(query)
      if advisoryLeedValue.empty?
        runner.registerError("Did not find value for #{advisoryLeed}.")
        return false
      else
        output_advisory << "#{advisoryLeed}: #{neat_numbers(advisoryLeedValue.get,0)}" << " (hr)<br>"
      end
    end # advisoriesLeed.each do


    output_advisory << "<br>"
    output_advisory << "\""

    #reporting final condition
    runner.registerInitialCondition("Gathering data from EnergyPlus SQL file and OSM model.")

    # read in template
    html_in_path = "#{File.dirname(__FILE__)}/resources/report.html.in"
    if File.exist?(html_in_path)
        html_in_path = html_in_path
    else
        html_in_path = "#{File.dirname(__FILE__)}/report.html.in"
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
    runner.registerFinalCondition("Generated #{html_out_path}. #{eui_final_con}")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AnnualEndUseBreakdown.new.registerWithApplication