require 'json'

module OsLib_Reporting

  # setup - get model, sql, and setup web assets path
  def self.setup(runner)
    results = {}

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
  def self.life_cycle_cost_section(model, sqlFile, runner, name_only = false)
    # array to hold tables
    template_tables = []

    # gather data for section
    @template_section = {}
    @template_section[:title] = 'LifeCycle Costs'
    @template_section[:tables] = template_tables

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      return @template_section
    end

    array_header = ['Object','Object Type','Unit Type','Unit Cost','Total Cost','Frequency','Years From Start']
    array_units = ['','','','','$','Years','Years']

    # create table
    template_table_01 = {}
    template_table_01[:title] = 'Construction'
    template_table_01[:header] = array_header
    template_table_01[:units] = array_units
    template_table_01[:data] = []

    # create table
    template_table_02 = {}
    template_table_02[:title] = 'Maintainance'
    template_table_02[:header] = array_header
    template_table_02[:units] = array_units
    template_table_02[:data] = []

    # create table
    template_table_03 = {}
    template_table_03[:title] = 'Salvage'
    template_table_03[:header] = array_header
    template_table_03[:units] = array_units
    template_table_03[:data] = []

    # get lifecycle costs and add rows
    model.getLifeCycleCosts.sort.each do |lifecycle_cost|
      next if lifecycle_cost.totalCost == 0
      if lifecycle_cost.costUnits == "CostPerArea"
        neat_cost = "#{OpenStudio::toNeatString(OpenStudio::convert(lifecycle_cost.cost,"$/m^2","$/ft^2").get,2,true)} ($/ft^2)"
      else
        neat_cost = "#{OpenStudio::toNeatString(lifecycle_cost.cost,2,true)} ($)"
      end
      neat_total_cost = OpenStudio::toNeatString(lifecycle_cost.totalCost,2,true)
      array_data = [lifecycle_cost.item.name,lifecycle_cost.itemType,lifecycle_cost.costUnits,neat_cost,neat_total_cost,lifecycle_cost.repeatPeriodYears,lifecycle_cost.yearsFromStart]
      if lifecycle_cost.category == "Construction"
        template_table_01[:data] << array_data
      elsif lifecycle_cost.category == "Maintenance"
        template_table_02[:data] << array_data
      elsif lifecycle_cost.category == "Salvage"
        template_table_03[:data] << array_data
      else
        runner.registerWarning("Unexpected LifeCycle Cost Catetory of #{lifecycle_cost.category}")
      end
    end

    # add table to array of tables
    template_tables << template_table_01
    template_tables << template_table_02
    template_tables << template_table_03

    return @template_section
  end

  # create template section
  def self.life_cycle_parameters_section(model, sqlFile, runner, name_only = false)
    # array to hold tables
    template_tables = []

    # gather data for section
    @template_section = {}
    @template_section[:title] = 'LifeCycle Cost Parameters'
    @template_section[:tables] = template_tables

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      return @template_section
    end

    # create table
    template_table_01 = {}
    template_table_01[:header] = ['Description','Value']
    template_table_01[:data] = []

    # get lifecycle cost parameters
    lccp = model.getLifeCycleCostParameters

    # populate table
    template_table_01[:data] << ["Analysis Type",lccp.analysisType]
    template_table_01[:data] << ["Discounting Convention",lccp.discountingConvention]
    template_table_01[:data] << ["Inflation Approach",lccp.inflationApproach]
    template_table_01[:data] << ["Length Of Study Period In Years",lccp.lengthOfStudyPeriodInYears]
    template_table_01[:data] << ["Depreciation Method ",lccp.depreciationMethod ]
    template_table_01[:data] << ["Use NIST Fuel Escalation Rates",lccp.useNISTFuelEscalationRates]
    template_table_01[:data] << ["NIST Region",lccp.nistRegion ]
    template_table_01[:data] << ["NIST   Sector",lccp.nistSector]

    # add table to array of tables
    template_tables << template_table_01

    return @template_section
  end

end
