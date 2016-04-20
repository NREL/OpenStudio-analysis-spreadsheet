require 'erb'
require 'json'

require "#{File.dirname(__FILE__)}/resources/os_lib_reporting_custom"
require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"

# start the measure
class LifeCycleCostReport < OpenStudio::Ruleset::ModelUserScript
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "LifeCycle Cost Report"
  end

  # human readable description
  def description
    return "Lists all LifeCycle Cost objects in the model as well as the LifeCycle Cost Parameter object"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Separate tables are made for costs tagged as Construction, Maintainance, and Salvage."
  end

  def possible_sections

    # methods for sections in order that they will appear in report
    result = []

    # instead of hand populating, any methods with 'section' in the name will be added in the order they appear
    all_setions =  OsLib_Reporting.methods(false)
    all_setions.each do |section|
      next if not section.to_s.include? 'section'
      result << section.to_s
    end

    result
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # populate arguments
    possible_sections.each do |method_name|
      # get display name
      arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument(method_name, true)
      display_name = eval("OsLib_Reporting.#{method_name}(nil,nil,nil,true)[:title]")
      arg.setDisplayName(display_name)
      arg.setDefaultValue(true)
      args << arg
    end

    args
  end # end the arguments method

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    unless args
      return false
    end

    # get sql, model, and web assets
    setup = OsLib_Reporting.setup(runner)
    unless setup
      return false
    end
    web_asset_path = setup[:web_asset_path]

    # reporting final condition
    runner.registerInitialCondition('Gathering data from OSM model.')

    # pass measure display name to erb
    @name = name

    # create a array of sections to loop through in erb file
    @sections = []

    # generate data for requested sections
    sections_made = 0
    possible_sections.each do |method_name|

      begin
        next unless args[method_name]
        section = false
        eval("section = OsLib_Reporting.#{method_name}(model,nil,runner,false)")
        display_name = eval("OsLib_Reporting.#{method_name}(nil,nil,nil,true)[:title]")
        if section
          @sections << section
          sections_made += 1
          # look for emtpy tables and warn if skipped because returned empty
          section[:tables].each do |table|
            if not table
              runner.registerWarning("A table in #{display_name} section returned false and was skipped.")
              section[:messages] = ["One or more tables in #{display_name} section returned false and was skipped."]
            end
          end
        else
          runner.registerWarning("#{display_name} section returned false and was skipped.")
          section = {}
          section[:title] = "#{display_name}"
          section[:tables] = []
          section[:messages] = []
          section[:messages] << "#{display_name} section returned false and was skipped."
          @sections << section
        end
      rescue => e
        display_name = eval("OsLib_Reporting.#{method_name}(nil,nil,nil,true)[:title]")
        if display_name == nil then display_name == method_name end
        runner.registerWarning("#{display_name} section failed and was skipped because: #{e}. Detail on error follows.")
        runner.registerWarning("#{e.backtrace.join("\n")}")

        # add in section heading with message if section fails
        section = eval("OsLib_Reporting.#{method_name}(nil,nil,nil,true)")
        section[:messages] = []
        section[:messages] << "#{display_name} section failed and was skipped because: #{e}. Detail on error follows."
        section[:messages] << ["#{e.backtrace.join("\n")}"]
        @sections << section

      end

    end

    # read in template
    html_in_path = "#{File.dirname(__FILE__)}/resources/report.html.erb"
    if File.exist?(html_in_path)
      html_in_path = html_in_path
    else
      html_in_path = "#{File.dirname(__FILE__)}/report.html.erb"
    end
    html_in = ''
    File.open(html_in_path, 'r') do |file|
      html_in = file.read
    end

    # configure template with variable values
    renderer = ERB.new(html_in)
    html_out = renderer.result(binding)

    # write html file
    html_out_path = './report.html'
    File.open(html_out_path, 'w') do |file|
      file << html_out
      # make sure data is written to the disk one way or the other
      begin
        file.fsync
      rescue
        file.flush
      end
    end
    html_out_path = File.absolute_path(html_out_path)

    # reporting final condition
    runner.registerFinalCondition("Generated report with #{sections_made} sections to <a href='file:///#{html_out_path}'>report.html</a>.")

    true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
LifeCycleCostReport.new.registerWithApplication
