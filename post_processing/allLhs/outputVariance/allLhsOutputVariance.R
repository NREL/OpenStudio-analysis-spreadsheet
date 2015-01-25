#Load list of desired PCA reports and data to be used
require(ggplot2)
require(reshape2)
require(stats)
require(grid)
setwd("C:/gitRepositories/OpenStudio-analysis-spreadsheet/post_processing/allLhs/outputVariance")
wd_base = "."
output_df = read.csv(paste(wd_base,"resources","reporting_outputs.csv",sep="/"))
data_for_analysis = read.csv(paste(wd_base,"resources","data.csv",sep="/"))

#Load metadata dataframe and rip out independent vars
load(paste(wd_base,data_for_analysis[1,"metadata_dataframe"],sep="/"))
variables_df = subset(metadata,perturbable==T)

#Check existence of desired outputs
error_flag = F
for(i in 1:nrow(output_df)){
  error_message = ""
  if(!(output_df[i,"resultname"] %in% metadata[,"name"])){
    error_flag = T
    error_message = paste(error_message,"Desired PCA result ",output_df[i,"resultname"]," was not found in the provided data. ",sep="")
  }
}
if(error_flag){
  stop(error_message)
}

#Cycle through desired outputs and produce graphs. These will be stored in wd_base/output
if(!file.exists("post_processing_graphs")){
  dir.create("post_processing_graphs")
}
if(!file.exists("correlation_dfs")){
  dir.create("correlation_dfs")
}
if(!file.exists("p_value_dfs")){
  dir.create("p_value_dfs")
}

var_array = array(0,dim=c(nrow(data_for_analysis),nrow(output_df),nrow(variables_df)))
for(i in 1:nrow(data_for_analysis)){
  load(paste(wd_base,toString(data_for_analysis[i,"results_dataframe"]),sep="/"))
  load(paste(wd_base,toString(data_for_analysis[i,"metadata_dataframe"]),sep="/"))
  variables_df = subset(metadata,perturbable==T)
  results = subset(results,select=c(variables_df[,"name"],levels(output_df[,"resultname"])))
  for(j in 1:nrow(output_df)){
    for(k in 1:nrow(variables_df)){
      var_array[i,j,k] = cor(x=results[,toString(output_df[j,'resultname'])],y=results[,variables_df[k,'name']])
    }
  }
}

for(i in 1:nrow(output_df)){
  temp_df = subset(melt(var_array),Var2==i)
  ploting_df = data.frame()
  for(j in 1:nrow(temp_df)){
    ploting_df[j,'building_type'] = toString(data_for_analysis[temp_df[j,'Var1'],'building_display_name'])
    ploting_df[j,'input_variable'] = variables_df[temp_df[j,'Var3'],'display_name']
    ploting_df[j,'variance'] = temp_df[j,'value']
  }
  outputName = paste(toString(output_df[i,'resultnamed']),'Correlation')
  outputName = paste(outputName,'.png',sep='')
  setwd('post_processing_graphs')
  png(filename=outputName,height=600,width=1000,pointsize=12)
  p=ggplot(ploting_df,aes(x=ploting_df$building_type,y=ploting_df$input_variable,fill=ploting_df$variance))+
    geom_tile()+
    labs(y='Variables',x='Space Types',title=paste(toString(output_df[i,'resultnamed']),'Correlation'))+
    guides(fill = guide_colorbar(barwidth = 1, barheight = 15))+
    scale_fill_gradientn(name = "Correlation",limits=c(-1,1),colours=c('#3D52A1','#3A89C9','#77B7E5','#B4DDF7',
                                                                    '#E6F5FE','#FFFAD2','#FFE3AA','#F9DB7E',
                                                                    '#ED875E','#D24D3E','#AE1C3E'))+
    theme(plot.title=element_text(size=30,face="bold"),
          axis.title.x=element_text(size=24,face="bold"),
          axis.title.y=element_text(size=24,face="bold",vjust=2),
          axis.text.x=element_text(angle=60,hjust=1,color="black",size=10,face="bold"),
          axis.text.y=element_text(color="black",size=10,face="bold"),
          plot.margin=unit(c(1,1,5,1), "lines"))
  print(p)
  dev.off()
  graphics.off()
  setwd('../correlation_dfs')
  save(ploting_df,file=paste(toString(output_df[i,"varname"]),"correlation_measures.RData",sep="_"))
  setwd("..")
}

slope_storage = list()
pval_array = array(0,dim=c(nrow(data_for_analysis),nrow(output_df),nrow(variables_df)))
for(i in 1:nrow(data_for_analysis)){
  load(paste(wd_base,toString(data_for_analysis[i,"results_dataframe"]),sep="/"))
  load(paste(wd_base,toString(data_for_analysis[i,"metadata_dataframe"]),sep="/"))
  variables_df = subset(metadata,perturbable==T)
  results = subset(results,select=c(variables_df[,"name"],levels(output_df[,"resultname"])))
  slope_df = data.frame()
  for(j in 1:nrow(output_df)){
    for(k in 1:nrow(variables_df)){
      lm_var = paste(toString(output_df[j,"resultname"])," ~ ",variables_df[k,"name"],sep="")
      l = lm(lm_var, data = results)
      slope=coef(l)[2]
      intercept = coef(l)[1]
      f=summary(l)$fstatistic
      p=pf(f[1],f[2],f[3],lower.tail=F)
      scale_mult = diff(range(results[,toString(variables_df[k,"name"])]))
      slope_df[k,"slope"] = slope*scale_mult
      slope_df[k,"int"] = intercept
      slope_df[k,"p_value"] = p
      slope_df[k,"var"] = toString(variables_df[k,"display_name"])
      slope_df[k,"result"] = toString(output_df[j,"resultname"])
      pval_array[i,j,k] = p
    }
  }
  slope_storage[[i]] = slope_df
}

for(i in 1:nrow(output_df)){
  temp_df = subset(melt(pval_array),Var2==i)
  ploting_df = data.frame()
  for(j in 1:nrow(temp_df)){
    ploting_df[j,'building_type'] = toString(data_for_analysis[temp_df[j,'Var1'],'building_display_name'])
    ploting_df[j,'input_variable'] = variables_df[temp_df[j,'Var3'],'display_name']
    ploting_df[j,'p_value'] = temp_df[j,'value']
  }
  outputName = paste(toString(output_df[i,'resultnamed']),'P-Value')
  outputName = paste(outputName,'.png',sep='')
  setwd('post_processing_graphs')
  png(filename=outputName,height=600,width=1000,pointsize=12)
  p=ggplot(ploting_df,aes(x=ploting_df$building_type,y=ploting_df$input_variable,fill=ploting_df$p_value))+
    geom_tile()+
    labs(y='Variables',x='Space Types',title=paste(toString(output_df[i,'resultnamed']),'P-Value'))+
    scale_fill_gradientn(name = "P-Value",limits=c(0,1),breaks=c(0.05,0.25,0.5,0.75,1),
                         colours=c('#FFFFE5','#FFF7BC','#FEE391','#FEC44F','#FB9A29','#EC7014','#CC4C02','#993404','#662506'),
                         values=c(0,0.025,0.05,0.075,0.1,0.25,0.5,0.75,1))+
    guides(fill = guide_colorbar(barwidth = 1, barheight = 15))+
    theme(plot.title=element_text(size=30,face="bold"),
          axis.title.x=element_text(size=24,face="bold"),
          axis.title.y=element_text(size=24,face="bold",vjust=2),
          axis.text.x=element_text(angle=60,hjust=1,color="black",size=10,face="bold"),
          axis.text.y=element_text(color="black",size=10,face="bold"),
          plot.margin=unit(c(1,1,5,1), "lines"))
  print(p)
  dev.off()
  graphics.off()
  setwd('../p_value_dfs')
  slope_df = slope_storage[[i]]
  save(ploting_df,slope_df,file=paste(toString(output_df[i,"varname"]),"p_value.RData",sep="_"))
  setwd("..")
}