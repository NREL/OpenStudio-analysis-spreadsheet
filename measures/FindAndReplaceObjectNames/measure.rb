#start the measure
class FindAndReplaceObjectNames < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see
  def name
    return "Find and Replace Object Names in the Model"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for your name
    orig_string = OpenStudio::Ruleset::OSArgument::makeStringArgument("orig_string",true)
    orig_string.setDisplayName("Type the text you want search for in object names")
    orig_string.setDefaultValue("replace this text")
    args << orig_string

    #make an argument to add new space true/false
    new_string = OpenStudio::Ruleset::OSArgument::makeStringArgument("new_string",true)
    new_string.setDisplayName("Type the text you want to add in place of the found text")
    new_string.setDefaultValue("with this text")
    args << new_string
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    orig_string = runner.getStringArgumentValue("orig_string",user_arguments)
    new_string = runner.getStringArgumentValue("new_string",user_arguments)
    
    #check the orig_string for reasonableness
    puts orig_string
    if orig_string == ""
      runner.registerError("No search string was entered.")
      return false
    end

    #reporting initial condition of model
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("The model has #{model.objects.size} objects.")
    
    #array for objects with names
    named_objects = []

    #loop through model objects and rename if the object has a name
    model.objects.each do |obj|
      if not obj.name.empty?
        old_name = obj.name.get
        new_name = obj.setName(old_name.gsub(orig_string,new_string))
        if not old_name == new_name
          named_objects << new_name
        end
      end
    end
    
    #reporting final condition of model
    runner.registerFinalCondition("#{named_objects.size} objects were renamed.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
FindAndReplaceObjectNames.new.registerWithApplication









