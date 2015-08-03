#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ReportModelChanges < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ReportModelChanges"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for your name
    compare_model_path = OpenStudio::Ruleset::OSArgument::makeStringArgument("compare_model_path",true)
    compare_model_path.setDisplayName("Path to model for comparison")
    args << compare_model_path

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    compare_model_path = runner.getStringArgumentValue("compare_model_path",user_arguments)

    # load the model
    vt = OpenStudio::OSVersion::VersionTranslator.new
    compare_model = vt.loadModel(compare_model_path)
    if compare_model.empty?
      runner.registerError("Cannot load model from #{compare_model_path} for comparison.")
      return false
    end
    compare_model = compare_model.get
    
    only_model = []
    only_compare = []
    both = []
    diffs = []
    num_ignored = 0
    
    # loop through model and find objects in this model only or in both
    model.getModelObjects.each do |object|
    
      # TODO: compare these some other way
      if not object.iddObject.hasNameField
        num_ignored += 1
        next
      end

      compare_object = compare_model.getObjectByTypeAndName(object.iddObject.type, object.name.to_s)
      if compare_object.empty?
        only_model << object
      else 
        both << [object, compare_object.get]
      end
    end 
    
    # loop through model and find objects in comparison model only
    compare_model.getModelObjects.each do |compare_object|
    
      # TODO: compare these some other way
      if not compare_object.iddObject.hasNameField
        num_ignored += 1
        next
      end
      
      object = model.getObjectByTypeAndName(compare_object.iddObject.type, compare_object.name.to_s)
      if object.empty?
        only_compare << compare_object
      end
    end 
    
    # loop through and perform the diffs 
    both.each do |b|
      object = b[0]
      compare_object = b[1]
      idd_object = object.iddObject
      
      object_num_fields = object.numFields
      compare_num_fields = compare_object.numFields
      
      diff = "<table border='1'>\n"
      diff += "<tr style='font-weight:bold'><td>#{object.iddObject.name}</td><td/><td/></tr>\n"
      diff += "<tr style='font-weight:bold'><td>Model Object</td><td>Comparison Object</td><td>Field Name</td></tr>\n"
      
      # loop over fields skipping handle
      same = true
      (1...[object_num_fields, compare_num_fields].max).each do |i|
      
        field_name = idd_object.getField(i).get.name
        
        object_value = ""
        if i < object_num_fields
          object_value = object.getString(i).to_s
        end
        object_value = "-" if object_value.empty?
        
        compare_value = ""
        if i < compare_num_fields
          compare_value = compare_object.getString(i).to_s
        end
        compare_value = "-" if compare_value.empty?
        
        row_color = "green"
        if object_value != compare_value
          same = false
          row_color = "red"
        end
        
        diff += "<tr><td style='color:#{row_color}'>#{object_value}</td><td style='color:#{row_color}'>#{compare_value}</td><td>#{field_name}</td></tr>\n"
        
      end
      diff += "</table><p/><p/>\n"
      
      if not same
        diffs << diff
      end

    end
      
    # path for reports
    report_path = Dir.pwd + "/report.html"
    
    # write the report
    File.open(report_path, 'w') do |file|  
      file << "<section>\n<h1>Objects Only In Model</h1>\n"
      file << "<table border='1'>\n"
      only_model.each do |object|
        file << "<tr><td style='white-space:pre'>#{object.to_s}</td></tr>\n"
      end
      file << "</table>\n"
      file << "</section>\n"
      
      file << "<section>\n<h1>Objects Only In Comparison Model</h1>\n"
      file << "<table border='1'>\n"
      only_compare.each do |object|
        file << "<tr><td style='white-space:pre'>#{object.to_s}</td></tr>\n"
      end
      file << "</table>\n"
      file << "</section>\n"
    
      file << "<section>\n<h1>Objects In Both Models With Differences</h1>\n"
      diffs.each do |diff|
        file << diff
      end
      file << "</section>\n"
    end
    runner.registerInfo("Report generated at: <a href='file:///#{report_path}'>#{report_path}</a>")
    
    runner.registerWarning("#{num_ignored} objects did not have names and were not compared")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ReportModelChanges.new.registerWithApplication