module OsLib_Schedules

  # create a ruleset schedule with a basic profile
  def OsLib_Schedules.createSimpleSchedule(model, options = {})

    defaults = {
        "name" => nil,
        "winterTimeValuePairs" => {24.0 => 0.0},
        "summerTimeValuePairs" => {24.0 => 1.0},
        "defaultTimeValuePairs" => {24.0 => 1.0},
    }


    # merge user inputs with defaults
    options = defaults.merge(options)

    #ScheduleRuleset
    sch_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
    if name
      sch_ruleset.setName(options["name"])
    end

    #Winter Design Day
    winter_dsn_day = OpenStudio::Model::ScheduleDay.new(model)
    sch_ruleset.setWinterDesignDaySchedule(winter_dsn_day)
    winter_dsn_day = sch_ruleset.winterDesignDaySchedule
    winter_dsn_day.setName("#{sch_ruleset.name} Winter Design Day")
    options["winterTimeValuePairs"].each do |k,v|
      hour = k.truncate
      min = ((k - hour)*60).to_i
      winter_dsn_day.addValue(OpenStudio::Time.new(0, hour, min, 0),v)
    end

    #Summer Design Day
    summer_dsn_day = OpenStudio::Model::ScheduleDay.new(model)
    sch_ruleset.setSummerDesignDaySchedule(summer_dsn_day)
    summer_dsn_day = sch_ruleset.summerDesignDaySchedule
    summer_dsn_day.setName("#{sch_ruleset.name} Summer Design Day")
    options["summerTimeValuePairs"].each do |k,v|
      hour = k.truncate
      min = ((k - hour)*60).to_i
      summer_dsn_day.addValue(OpenStudio::Time.new(0, hour, min, 0),v)
    end

    #All Days
    week_day = sch_ruleset.defaultDaySchedule
    week_day.setName("#{sch_ruleset.name} Schedule Week Day")
    options["defaultTimeValuePairs"].each do |k,v|
      hour = k.truncate
      min = ((k - hour)*60).to_i
      week_day.addValue(OpenStudio::Time.new(0, hour, min, 0),v)
    end

    result = sch_ruleset
    return result

  end #end of OsLib_Schedules.createSimpleSchedule

end