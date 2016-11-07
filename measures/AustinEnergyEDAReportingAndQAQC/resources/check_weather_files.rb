module OsLib_QAQC

  # include any general notes about QAQC method here

  #checks the number of unmet hours in the model
  def check_weather_files(category,options)

    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "Weather Files")
    check_elems << OpenStudio::Attribute.new("category", category)
    check_elems << OpenStudio::Attribute.new("description", "Check weather file, design days, and climate zone against #{@utility_name} list of allowable options.")

    begin

      # get weather file
      model_epw = nil
      if @model.getWeatherFile.url.is_initialized
        raw_epw = @model.getWeatherFile.url.get
        end_path_index = raw_epw.rindex('/')
        model_epw = raw_epw.slice!(end_path_index+1,raw_epw.length) # everything right of last forward slash
      end

      # check design days (model must have one or more of the required summer and winter design days)
      # get design days names from model
      model_summer_dd_names = []
      model_winter_dd_names = []
      @model.getDesignDays.each do |design_day|
        if design_day.dayType == "SummerDesignDay"
          model_summer_dd_names << design_day.name.to_s
        elsif design_day.dayType == "WinterDesignDay"
          model_winter_dd_names << design_day.name.to_s
        else
          puts "unexpected day type of #{design_day.dayType} wont' be included in check"
        end
      end

      # find matching weather file from options, as well as design days and climate zone
      if options.has_key?(model_epw)
        required_summer_dd = options[model_epw]['summer']
        required_winter_dd = options[model_epw]['winter']
        valid_climate_zones = [options[model_epw]['climate_zone']]

        # check for intersection betwen model valid design days
        summer_intersection = (required_summer_dd & model_summer_dd_names)
        winter_intersection = (required_winter_dd & model_winter_dd_names)
        if summer_intersection.size == 0 and required_summer_dd.size > 0
          check_elems << OpenStudio::Attribute.new("flag", "Didn't find any of the expected summer design days for #{model_epw}")
        end
        if winter_intersection.size == 0 and required_winter_dd.size > 0
          check_elems << OpenStudio::Attribute.new("flag", "Didn't find any of the expected winter design days for #{model_epw}")
        end

      else
        check_elems << OpenStudio::Attribute.new("flag", "#{model_epw} is not a an expected weather file.")
        check_elems << OpenStudio::Attribute.new("flag", "Model doesn't have expected epw file, as a result can't validate design days.")
        valid_climate_zones = []
        options.each do |lookup_epw,value|
          valid_climate_zones << value['climate_zone']
        end
      end

      # get ashrae climate zone from model
      model_climate_zone = nil
      climateZones = @model.getClimateZones
      climateZones.climateZones.each do |climateZone|
        if climateZone.institution == "ASHRAE"
          model_climate_zone = climateZone.value
          next
        end
      end
      if model_climate_zone == ""
        check_elems << OpenStudio::Attribute.new("flag", "The model's ASHRAE climate zone has not been defined. Expected climate zone was #{valid_climate_zones.uniq.join(',')}.")
      elsif not valid_climate_zones.include?(model_climate_zone)
        check_elems << OpenStudio::Attribute.new("flag", "The model's ASHRAE climate zone was #{model_climate_zone}. Expected climate zone was #{valid_climate_zones.uniq.join(',')}.")
      end

    rescue => e
      # brief description of ruby error
      check_elems << OpenStudio::Attribute.new("flag", "Error prevented QAQC check from running (#{e}).")

      # backtrace of ruby error for diagnostic use
      #check_elems << OpenStudio::Attribute.new("flag", "#{e.backtrace.join("\n")}")
    end

    # add check_elms to new attribute
    check_elem = OpenStudio::Attribute.new("check", check_elems)

    return check_elem
    # note: registerWarning and registerValue will be added for checks downstream using os_lib_reporting_qaqc.rb

  end

end  