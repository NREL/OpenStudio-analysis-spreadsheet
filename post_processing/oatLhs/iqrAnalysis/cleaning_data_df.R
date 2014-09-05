#This really needs to be made relative to the call location!!!!!!!!!!!!!!!!!!!
setwd("C:/gitRepositories/OpenStudio-analysis-spreadsheet/post_processing/oatLhs/iqrAnalysis")
wd_base = "."
output_df = read.csv(paste(wd_base,"resources","reporting_outputs.csv",sep="/"))
data_for_analysis = read.csv(paste(wd_base,"resources","data.csv",sep="/"))

#Fix non machine-readable names here and resave the metadata dataframe
for(i in 1:nrow(data_for_analysis)){
  load(paste(wd_base,toString(data_for_analysis[i,"metadata_dataframe"]),sep="/"))
  to_fix = c('name','display_name')
  for(j in 1:length(to_fix)){
    if(!is.character(metadata[,to_fix[j]])){
      warning("FUNCTIONNAMESPACE was unable to execute as the input ",quote(df_in),
              " as it was found to be of class ",class(vec)," not class character")
    }
    for(k in 1:nrow(metadata)){
      temp = metadata[k,to_fix[j]]
      temp = gsub('&','-',temp)
      temp = gsub('\\(','_',temp)
      temp = gsub('\\)','_',temp)
      temp = gsub('%','_',temp)
      temp = gsub('/','_',temp)
      temp = gsub(':','_',temp)
      temp = gsub(';','_',temp)
      temp = gsub('\\+','_',temp)
      temp = gsub('!','_',temp)
      temp = gsub('\\[','_',temp)
      temp = gsub('\\]','_',temp)
      temp = gsub('\\{','_',temp)
      temp = gsub('\\}','_',temp)
      temp = gsub('@','_',temp)
      temp = gsub('<','_',temp)
      temp = gsub('>','_',temp)
      temp = gsub('\\|','_',temp)
      temp = gsub('~','_',temp)
      temp = gsub('\\?','_',temp)
      temp = gsub('=','_',temp)
      temp = gsub('"','_',temp)
      metadata[k,to_fix[j]] = temp
    }
  }
  save(metadata,file=paste(wd_base,toString(data_for_analysis[i,"metadata_dataframe"]),sep="/"))
}


#Fix non machine-readable names here and resave the results dataframe
for(i in 1:nrow(data_for_analysis)){
  load(paste(wd_base,toString(data_for_analysis[i,"results_dataframe"]),sep="/"))
  vec = colnames(results)
  for(j in 1:length(vec)){
    temp = vec
    temp = gsub('&','-',temp)
    temp = gsub('\\(','_',temp)
    temp = gsub('\\)','_',temp)
    temp = gsub('%','_',temp)
    temp = gsub('/','_',temp)
    temp = gsub(':','_',temp)
    temp = gsub(';','_',temp)
    temp = gsub('\\+','_',temp)
    temp = gsub('!','_',temp)
    temp = gsub('\\[','_',temp)
    temp = gsub('\\]','_',temp)
    temp = gsub('\\{','_',temp)
    temp = gsub('\\}','_',temp)
    temp = gsub('@','_',temp)
    temp = gsub('<','_',temp)
    temp = gsub('>','_',temp)
    temp = gsub('\\|','_',temp)
    temp = gsub('~','_',temp)
    temp = gsub('\\?','_',temp)
    temp = gsub('=','_',temp)
    temp = gsub('"','_',temp)
    vec = temp
  }
  colnames(results) = vec
  save(results,file=paste(wd_base,toString(data_for_analysis[i,"results_dataframe"]),sep="/"))
}