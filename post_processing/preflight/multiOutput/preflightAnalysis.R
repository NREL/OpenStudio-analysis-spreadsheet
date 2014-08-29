require(knitr)
require(ggplot2)
require(AlgDesign)
require(grid)
require(jpeg)
require(biOps)
require(rmarkdown)

setwd("C:/gitRepositories/OpenStudio-analysis-spreadsheet/post_processing/preflight/multiOutput")
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

# import 'reporting_outputs.csv'
desired_results = read.csv(paste(wd_base,"/resources/reporting_outputs.csv",sep=""))
resultlist = NULL
resultlistd = NULL
for(i in 1:nrow(desired_results["resultlist"])){
  resultlist = c(resultlist,toString(desired_results[i,"resultlist"]))
  resultlistd = c(resultlistd,toString(desired_results[i,"resultlistd"]))
}

# check resultlist and resultlistd
if(length(resultlist)!=length(resultlistd)){
  stop("Please enter the same number of result names and result display names.")
}

# get result units
resultunits=NULL
for(i in 1:length(resultlist)){
  resultunits = c(resultunits,variables_df[which(variables_df$name == resultlist[1]),"units"])
}

if(!file.exists("htmlPages")){
  dir.create("htmlPages")
}

# initialize the preflight output dataframe
for(b in 10:nrow(buildings)){
  load(paste(buildings$results_dataframe[b]))
  project_name = buildings$building_name[b]
  preflight_df = results
  load(paste(buildings$metadata_dataframe[b]))
  variables_df = metadata
  pivots = subset(variables_df, type_of_variable=='pivot')
  vs = subset(variables_df, type_of_variable=='variable')
  render('header.Rmd', output_file =paste('htmlPages/',toString(buildings[b,'building_display_name']),'.html',sep=''),
         'knitrBootstrap::bootstrap_document',envir=globalenv(),quiet=TRUE)
}