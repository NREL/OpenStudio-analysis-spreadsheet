require 'json'

module OsLib_Reporting

  # setup - get model, sql, and setup web assets path
  def self.setup(runner)
    results = {}

    # get the last model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get

    # get the last idf
    workspace = runner.lastEnergyPlusWorkspace
    if workspace.empty?
      runner.registerError('Cannot find last idf file.')
      return false
    end
    workspace = workspace.get

    # get the last sql file
    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError('Cannot find last sql file.')
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    # populate hash to pass to measure
    results[:model] = model
    # results[:workspace] = workspace
    results[:sqlFile] = sqlFile
    results[:web_asset_path] = OpenStudio.getSharedResourcesPath / OpenStudio::Path.new('web_assets')

    return results
  end

  # developer notes
  # - Other thant the 'setup' section above this file should contain methods (def) that create sections and or tables.
  # - Any method that has 'section' in the name will be assumed to define a report section and will automatically be
  # added to the table of contents in the report.
  # - Any section method should have a 'name_only' argument and should stop the method if this is false after the
  # section is defined.
  # - Generally methods that make tables should end with '_table' however this isn't critical. What is important is that
  # it doesn't contain 'section' in the name if it doesn't return a section to the measure.
  # - The data below would typically come from the model or simulation results, but can also come from elsewhere or be
  # defeined in the method as was done with these examples.
  # - You can loop through objects to make a table for each item of that type, such as air loops

  # create template section
  def self.template_section(model, sqlFile, runner, name_only = false)
    # array to hold tables
    template_tables = []

    # gather data for section
    @template_section = {}
    @template_section[:title] = 'Tasty Treats'
    @template_section[:tables] = template_tables

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      return @template_section
    end

    # create table
    template_table_01 = {}
    template_table_01[:title] = 'Fruit'
    template_table_01[:header] = ['Type','Quantity']
    template_table_01[:units] = ['', 'lbs']
    template_table_01[:data] = []

    # add rows to table
    template_table_01[:data] << ['Banana', 100]
    template_table_01[:data] << ['Apple', 250]
    template_table_01[:data] << ['Orange', 175]

    # create chart
    template_table_01[:chart_type] = 'simple_pie'
    template_table_01[:chart] = []
    template_table_01[:data].each do |row|
      template_table_01[:chart] << JSON.generate(label: row[0], value: row[1])
    end

    # add table to array of tables
    template_tables << template_table_01

    # use helper method that generates additional table for section
    template_tables << OsLib_Reporting.template_table(model, sqlFile, runner)

    return @template_section
  end

  # create template section
  def self.template_table(model, sqlFile, runner)
    # create a second table
    template_table = {}
    template_table[:title] = 'Ice Cream'
    template_table[:header] = ['Type', 'Base Flavor', 'Toppings', 'Value']
    template_table[:units] = ['', '', '', 'scoop']
    template_table[:data] = []

    # add rows to table
    template_table[:data] << ['Vanilla', 'Vanilla', 'NA', 1.5]
    template_table[:data] << ['Rocky Road', 'Chocolate', 'Nuts', 1.5]
    template_table[:data] << ['Mint Chip', 'Mint', 'Chocolate Chips', 1.5]

    return template_table
  end

  # section for sample material properties
  def self.mat_prop_section(model, sqlFile, runner, name_only = false)
    # array to hold tables
    tables = []

    # gather data for section
    @mat_prop = {}
    @mat_prop[:title] = 'Material Properties'
    @mat_prop[:tables] = tables

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      return @mat_prop
    end

    # using helper method that generates table for second example
    tables << OsLib_Reporting.mat_prop_table(model, sqlFile, runner)

    return @mat_prop
  end

  # sample material property table using scatter plot
  def self.mat_prop_table(model, sqlFile, runner)

    # create table
    mat_prop_table = {}
    mat_prop_table[:title] = 'Metals'
    mat_prop_table[:header] = ['Material',"Notes/Index",'Density','Tension']
    mat_prop_table[:units] = ['','','Kg/m^3',"MPa"]
    mat_prop_table[:data] = []

    # create chart
    mat_prop_table[:chart_type] = 'scatter'
    mat_prop_table[:chart_attributes] = { label_x: mat_prop_table[:header][2], label_y: mat_prop_table[:header][3] }
    mat_prop_table[:chart] = []

    # add data to table and chart
    source_data = []
    source_data << ['Steel','Structural', 7860.0,400.0]
    source_data << ['Steel','High-strength-low-allow', 7860.0,480.0]
    source_data << ['Steel','Quenched and tempered alloy', 7860.0,825.0]
    source_data << ['Steel','Cold-rolled', 7920.0,860.0]
    source_data << ['Steel','Annealed', 7920.0,620.0]
    source_data << ['Cast Iron','', 7200.0,170.0]
    source_data << ['Aluminum','', 2710.0,110.0]
    source_data << ['Brass','', 8470.0,540.0]
    source_data << ['Titanium','', 4460.0,900.0]
    source_data.each do |mat|
      mat_prop_table[:data] << [mat[0],mat[1],mat[2],mat[3]]
      mat_prop_table[:chart] << JSON.generate(label: mat[0], index: mat[1], label_x: mat[2], label_y: mat[3])
    end

    return mat_prop_table
  end

  # section for general building information
  def self.general_building_information_section(model, sqlFile, runner, name_only = false)
    # array to hold tables
    tables = []

    # gather data for section
    @mat_prop = {}
    @mat_prop[:title] = 'General Building Information'
    @mat_prop[:tables] = tables

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      return @mat_prop
    end

    # using helper method that generates table for second example
    tables << OsLib_Reporting.general_building_information_table(model, sqlFile, runner)

    return @mat_prop
  end

  # create table with general building information
  # this table shows how to pull information out of the model and the sql file
  def self.general_building_information_table(model, sqlFile, runner)
    # general building information type data output
    general_building_information = {}
    general_building_information[:title] = 'Building Summary' # name will be with section
    general_building_information[:header] = %w(Information Value Units)
    general_building_information[:units] = [] # won't populate for this table since each row has different units.
    general_building_information[:data] = []

    # structure ID / building name
    display = 'Building Name'
    target_units = 'building_name'
    value = model.getBuilding.name.to_s
    general_building_information[:data] << [display, value, target_units]
    runner.registerValue(display.downcase.gsub(" ","_"), value, target_units)

    # net site energy
    display = 'Net Site Energy'
    source_units = 'GJ'
    target_units = 'kBtu'
    value = OpenStudio.convert(sqlFile.netSiteEnergy.get, source_units, target_units).get
    value_neat = OpenStudio.toNeatString(value, 0, true)
    general_building_information[:data] << [display, value_neat, target_units]
    runner.registerValue(display.downcase.gsub(" ","_"), value, target_units)

    # total building area
    query = 'SELECT Value FROM tabulardatawithstrings WHERE '
    query << "ReportName='AnnualBuildingUtilityPerformanceSummary' and "
    query << "ReportForString='Entire Facility' and "
    query << "TableName='Building Area' and "
    query << "RowName='Total Building Area' and "
    query << "ColumnName='Area' and "
    query << "Units='m2';"
    query_results = sqlFile.execAndReturnFirstDouble(query)
    if query_results.empty?
      runner.registerWarning('Did not find value for total building area.')
      return false
    else
      display = 'Total Building Area'
      source_units = 'm^2'
      target_units = 'ft^2'
      value = OpenStudio.convert(query_results.get, source_units, target_units).get
      value_neat = OpenStudio.toNeatString(value, 0, true)
      general_building_information[:data] << [display, value_neat, target_units]
      runner.registerValue(display.downcase.gsub(" ","_"), value, target_units)
    end

    # temp code to check OS vs. E+ area
    energy_plus_area = query_results.get
    open_studio_area = model.getBuilding.floorArea
    if not energy_plus_area == open_studio_area
      runner.registerWarning("EnergyPlus reported area is #{query_results.get} (m^2). OpenStudio reported area is #{model.getBuilding.floorArea} (m^2).")
    end

    # EUI
    eui =  sqlFile.netSiteEnergy.get / query_results.get
    display = 'EUI'
    source_units = 'GJ/m^2'
    target_units = 'kBtu/ft^2'
    if query_results.get > 0.0 # don't calculate EUI if building doesn't have any area
      value = OpenStudio.convert(eui, source_units, target_units).get
      value_neat = OpenStudio.toNeatString(value, 2, true)
      runner.registerValue(display.downcase.gsub(" ","_"), value, target_units) # is it ok not to calc EUI if no area in model
    else
      value_neat = "can't calculate EUI."
    end
    general_building_information[:data] << ["#{display} (Based on Net Site Energy and Total Building Area)", value_neat, target_units]

    return general_building_information
  end

end
