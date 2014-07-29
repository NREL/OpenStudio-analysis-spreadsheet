setwd('c:/gitRepositories/OpenStudio-analysis-spreadsheet/post_processing/preflight/multiOutput')
wd_base = '.'

# import building types
buildings = read.csv(paste(wd_base,"/resources/buildings.csv",sep=""))
buildings = buildings[order(buildings[,'building_name']),]

# include the list of variables from just one of the dataframes before going into building-by-building results
load(toString(buildings[1,'metadata_dataframe']))
variables_df = metadata

# Read each of the variables
pivots = subset(variables_df, type_of_variable=='pivot')
vs = subset(variables_df, type_of_variable=='variable')

#
unique_values_df = data.frame()
for(i in 1:length(vs$name)){
  unique_values_df[1,vs$name[i]] = NA
}
for(i in 1:nrow(buildings)){
  load(paste(buildings$results_dataframe[i]))
  for(j in 1:length(vs$name)){
    temp = unique(c(unique_values_df[,vs$name[j]],results[,vs$name[j]]))
    unique_values_df[1:length(temp),vs$name[j]] = temp
  }
}

missing_sim_df = data.frame()

for(i in 1:nrow(buildings)){
  load(paste(buildings$results_dataframe[i]))
  preflight_df = results
  load(paste(buildings$metadata_dataframe[i]))
  variables_df = metadata
  pivots = subset(variables_df, type_of_variable=='pivot')
  vs = subset(variables_df, type_of_variable=='variable')
  paramlist = NULL
  noPivot_flag = 0
  if(nrow(pivots)==0){
    
    pivotvalue = data.frame()
    pivotvalue[1,"Preflight"] = "Analysis"
    noPivot_flag = 1
  }else{
    for(p in 1:nrow(pivots)){
      paramlist = c(paramlist, length(unique(preflight_df[,pivots$name[p]])))
    }
    if(nrow(pivots)!=1){
      pivotlist=gen.factorial(paramlist,nVars=length(paramlist),center=FALSE)
    }else{
      pivotlist=gen.factorial(paramlist,nVars=1,center=FALSE)
    }
    
    #assign specific values to pivotlist for future query calls
    pivotvalue = data.frame()
    for(j in 1:length(pivotlist)){
      valuelist = unique(preflight_df[,pivots$name[j]])
      for(k in 1:nrow(pivotlist)){
        pivotvalue[k,pivots$name[j]] = valuelist[pivotlist[k,j]]
      }
    }
  }
  
  #itterate through full factorial design
  for(p in 1:nrow(pivotvalue)){
    # get list of all pivot variable values  
    pivot_names = pivotvalue[p,]
    
    # downselect to the correct pivot subset
    active_df = preflight_df
    if(noPivot_flag == 0){
      for(j in 1:nrow(pivots)){
        temp1 = pivots$name[j]
        temp2 = pivot_names[[j]]
        active_df = active_df[eval(parse(text=paste("active_df$",temp1," == ",quote(temp2),sep=""))),]
      }
    }
    
    #get static row from the active_df
    found_row = 0
    row_index = 1
    while((found_row == 0 && row_index <= nrow(active_df))){
      col_index = 1
      true_vector = active_df[row_index,vs[col_index,"name"]]==vs[col_index,"static_value"]
      while((all(true_vector) && col_index<nrow(vs))){
        col_index = col_index + 1
        true_vector = c(true_vector, active_df[row_index,vs[col_index,"name"]]==vs[col_index,"static_value"])
        if((col_index == nrow(vs) && all(true_vector))){
          found_row = 1
          static_row_index = row_index
        }
      }
      row_index = row_index + 1
    }
    static_row = active_df[static_row_index,]
    if(found_row==0){
      missing_row = nrow(missing_sim_df) + 1
      missing_sim_df[missing_row,'building_name'] = buildings$building_name[i]
      missing_sim_df[missing_row,'pivot_values'] = paste0(pivotvalue[p,],collapse=' - ')
      missing_sim_df[missing_row,'variable_name'] = 'static_row'
      missing_sim_df[missing_row,'variable_value'] = NA
    }
    
    #check for all non-static rows
    for(j in 1:length(vs$name)){
      if(is.na(results[1,vs$name[j]])){
      }else{
        if(!all(unique_values_df[!is.na(unique_values_df[,vs$name[j]]),vs$name[j]] %in% active_df[,vs$name[j]])){
          for(k in 1:length(unique_values_df[!is.na(unique_values_df[,vs$name[j]]),vs$name[j]])){
            if(!(unique_values_df[!is.na(unique_values_df[,vs$name[j]]),vs$name[j]][k] %in% active_df[,vs$name[j]])){
              missing_row = nrow(missing_sim_df) + 1
              missing_sim_df[missing_row,'building_name'] = buildings$building_name[i]
              missing_sim_df[missing_row,'pivot_values'] = paste0(pivotvalue[p,],collapse=' - ')
              missing_sim_df[missing_row,'variable_name'] = vs$name[j]
              missing_sim_df[missing_row,'variable_value'] = unique_values_df[!is.na(unique_values_df[,vs$name[j]]),vs$name[j]][k]
            }
          }
        }
      }
    }
  } 
}
print(missing_sim_df)
write.csv(missing_sim_df, file = 'failed_datapoints.csv')