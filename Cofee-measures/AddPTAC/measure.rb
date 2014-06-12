#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddPTAC < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddPTAC"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    # Heating efficiency
    heating_efficiency = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("heating_efficiency",true)
    heating_efficiency.setDisplayName("Heating Efficiency")
    heating_efficiency.setDefaultValue(0.8)
    args << heating_efficiency

    # Heating fuel type
    heating_fuel_type_options = OpenStudio::StringVector.new
    heating_fuel_type_options << "Gas"
    heating_fuel_type_options << "Electric"
    heating_fuel_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('heating_fuel_type', heating_fuel_type_options, false)
    heating_fuel_type.setDefaultValue("Gas")
    heating_fuel_type.setDisplayName("Heating Fuel Type")
    args << heating_fuel_type

    # Cooling cop
    cooling_cop = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cooling_cop",true)
    cooling_cop.setDisplayName("Cooling COP")
    cooling_cop.setDefaultValue(3.0)
    args << cooling_cop
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    heating_efficiency = runner.getDoubleArgumentValue('heating_efficiency',user_arguments)
    heating_fuel_type = runner.getStringArgumentValue('heating_fuel_type',user_arguments)
    cooling_cop = runner.getDoubleArgumentValue('cooling_cop',user_arguments)

    # Get all ThermalZone objects
    zones = model.getThermalZones.select { |z| z.equipment.empty? }

    zones.each do |zone|

      availabilitySchedule = model.alwaysOnDiscreteSchedule()
        
      fan = OpenStudio::Model::FanConstantVolume.new(model,availabilitySchedule)
      fan.setPressureRise(500)

      heatingCoil = nil

      if( heating_fuel_type == "Gas" )
        heatingCoil = OpenStudio::Model::CoilHeatingGas.new(model,availabilitySchedule)
        heatingCoil.setGasBurnerEfficiency(heating_efficiency);
      else
        heatingCoil = OpenStudio::Model::CoilHeatingElectric.new(model,availabilitySchedule)
        heatingCoil.setEfficiency(heating_efficiency);
      end

      coolingCurveFofTemp = OpenStudio::Model::CurveBiquadratic.new(model)
      coolingCurveFofTemp.setCoefficient1Constant(0.942587793)
      coolingCurveFofTemp.setCoefficient2x(0.009543347)
      coolingCurveFofTemp.setCoefficient3xPOW2(0.000683770)
      coolingCurveFofTemp.setCoefficient4y(-0.011042676)
      coolingCurveFofTemp.setCoefficient5yPOW2(0.000005249)
      coolingCurveFofTemp.setCoefficient6xTIMESY(-0.000009720)
      coolingCurveFofTemp.setMinimumValueofx(17.0)
      coolingCurveFofTemp.setMaximumValueofx(22.0)
      coolingCurveFofTemp.setMinimumValueofy(13.0)
      coolingCurveFofTemp.setMaximumValueofy(46.0)

      coolingCurveFofFlow = OpenStudio::Model::CurveQuadratic.new(model)
      coolingCurveFofFlow.setCoefficient1Constant(0.8)
      coolingCurveFofFlow.setCoefficient2x(0.2)
      coolingCurveFofFlow.setCoefficient3xPOW2(0.0)
      coolingCurveFofFlow.setMinimumValueofx(0.5)
      coolingCurveFofFlow.setMaximumValueofx(1.5)

      energyInputRatioFofTemp = OpenStudio::Model::CurveBiquadratic.new(model)
      energyInputRatioFofTemp.setCoefficient1Constant(0.342414409)
      energyInputRatioFofTemp.setCoefficient2x(0.034885008)
      energyInputRatioFofTemp.setCoefficient3xPOW2(-0.000623700)
      energyInputRatioFofTemp.setCoefficient4y(0.004977216)
      energyInputRatioFofTemp.setCoefficient5yPOW2(0.000437951)
      energyInputRatioFofTemp.setCoefficient6xTIMESY(-0.000728028)
      energyInputRatioFofTemp.setMinimumValueofx(17.0)
      energyInputRatioFofTemp.setMaximumValueofx(22.0)
      energyInputRatioFofTemp.setMinimumValueofy(13.0)
      energyInputRatioFofTemp.setMaximumValueofy(46.0)

      energyInputRatioFofFlow = OpenStudio::Model::CurveQuadratic.new(model)
      energyInputRatioFofFlow.setCoefficient1Constant(1.1552)
      energyInputRatioFofFlow.setCoefficient2x(-0.1808)
      energyInputRatioFofFlow.setCoefficient3xPOW2(0.0256)
      energyInputRatioFofFlow.setMinimumValueofx(0.5)
      energyInputRatioFofFlow.setMaximumValueofx(1.5)

      partLoadFraction = OpenStudio::Model::CurveQuadratic.new(model)
      partLoadFraction.setCoefficient1Constant(0.85)
      partLoadFraction.setCoefficient2x(0.15)
      partLoadFraction.setCoefficient3xPOW2(0.0)
      partLoadFraction.setMinimumValueofx(0.0)
      partLoadFraction.setMaximumValueofx(1.0)

      coolingCoil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new( model,
                                                                     availabilitySchedule,
                                                                     coolingCurveFofTemp,
                                                                     coolingCurveFofFlow,
                                                                     energyInputRatioFofTemp,
                                                                     energyInputRatioFofFlow,
                                                                     partLoadFraction )
      coolingCoil.setRatedCOP(OpenStudio::OptionalDouble.new(cooling_cop));


      ptac = OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner.new( model,
                                                                            availabilitySchedule, 
                                                                            fan,
                                                                            heatingCoil,
                                                                            coolingCoil )

      ptac.addToThermalZone(zone)
      runner.registerInfo("Added PTAC to ThermalZone named: #{zone.name.get}")
    end

    return true
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddPTAC.new.registerWithApplication
