class XcelEDAReportingandQAQC < OpenStudio::Ruleset::ReportingUserScript

  #can we use E+'s metric directly?  E+ will only use conditioned area
  #we need to incorporate building type into the range checking - ASHRAE Standard 100
  #how many hours did the @model run for? - make sure 8760 - get from html file

  #checks the EUI for the whole building
  def eui_check
    
    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "EUI Check")
    check_elems << OpenStudio::Attribute.new("category", "General")
    check_elems << OpenStudio::Attribute.new("description", "Check that the EUI of the building is reasonable")
    
    building = @model.getBuilding
    
    #make sure all required data are available
    if @sql.totalSiteEnergy.empty?
      check_elems << OpenStudio::Attribute.new("flag", "Site energy data unavailable; check not run")
      @runner.registerWarning("Site energy data unavailable; check not run")
    end
    
    total_site_energy_kBtu = OpenStudio::convert(@sql.totalSiteEnergy.get, "GJ", "kBtu").get
    if total_site_energy_kBtu == 0
      check_elems << OpenStudio::Attribute.new("flag", "Model site energy use = 0; likely a problem with the model")
      @runner.registerWarning("Model site energy use = 0; likely a problem with the model")
    end
  
    floor_area_ft2 = OpenStudio::convert(building.floorArea, "m^2", "ft^2").get
    if floor_area_ft2 == 0
      check_elems << OpenStudio::Attribute.new("flag", "The building has 0 floor area")
      @runner.registerWarning("The building has 0 floor area")
    end
    
    site_EUI = total_site_energy_kBtu / floor_area_ft2
    if site_EUI > 200
      check_elems << OpenStudio::Attribute.new("flag", "Site EUI of #{site_EUI} looks high.  A hospital or lab (high energy buildings) are around 200 kBtu/ft^2")
      @runner.registerWarning("Site EUI of #{site_EUI} looks high.  A hospital or lab (high energy buildings) are around 200 kBtu/ft^2")
    end
    if site_EUI < 30
      check_elems << OpenStudio::Attribute.new("flag", "Site EUI of #{site_EUI} looks low.  A high efficiency office building is around 50 kBtu/ft^2")
      @runner.registerWarning("Site EUI of #{site_EUI} looks low.  A high efficiency office building is around 50 kBtu/ft^2")
    end
    
    check_elem = OpenStudio::Attribute.new("check", check_elems)
 
    return check_elem
    
  end    
  
 end 