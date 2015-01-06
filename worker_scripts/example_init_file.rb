# This is an Example worker initilation file. The file has to follow general Ruby conventions.
#   File name must for the snake case (underscore case) of the class name. For example: WorkerInit = worker_init
#

class ExampleInitFile
  # Not required but can be used to initialize variables. No arguments can be passed to this method
  def initialize
    # do nothing in this example
  end

  # The run method is where all the work will be performed. This can have a variable length of arguments, which have
  # to match the cell from the Excel spreadsheet
  def run(arg_1, *args)
    puts args
    new_value = arg_1

    args
  end

  # this is optional. If it exists, the method will be called at the end. No arguments will be passed to this method.
  def finalize
    # do nothing
  end
end
