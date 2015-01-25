#Load list of desired PCA reports and data to be used
require(ggplot2)
require(grid)
setwd("C:/gitRepositories/OpenStudio-analysis-spreadsheet/post_processing/allLhs/sensitivityAnalysis")
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

#Fix non-machine readable names in all results dataframes


#Cycle through desired outputs and produce graphs. These will be stored in wd_base/output
if(!file.exists("post_processing_graphs")){
  dir.create("post_processing_graphs")
}
if(!file.exists("linear_models")){
  dir.create("linear_models")
}
for(i in 1:nrow(data_for_analysis)){
  load(paste(wd_base,data_for_analysis[i,"results_dataframe"],sep="/"))
  setwd("post_processing_graphs")
  results = subset(results,select=c(variables_df[,"name"],levels(output_df[,"resultname"])))
  predictor_slope_df = data.frame(row.names = variables_df[,"name"])
  predictor_intercept_df = data.frame(row.names = variables_df[,"name"])
  for(j in 1:nrow(output_df)){
    slope_df = data.frame()
    for(k in 1:nrow(variables_df)){
      outputName = tolower(substr(toString(data_for_analysis[i,"building_display_name"]),1,1))
      outputName = paste(outputName, substr(toString(data_for_analysis[i,"building_display_name"]),2,nchar(toString(data_for_analysis[i,"building_display_name"]))),sep="")
      outputName = paste(outputName, toupper(substr(toString(output_df[j,"varname"]),1,1)),sep="")
      outputName = paste(outputName, substr(toString(output_df[j,"varname"]),2,nchar(toString(output_df[j,"varname"]))),sep="")
      outputName = paste(outputName,"_",k,".png",sep="")
      outputName = gsub(" ","",outputName)
      plot_df = data.frame()
      plot_df[1:nrow(results),toString(output_df[j,"resultname"])] = results[,toString(output_df[j,"resultname"])]
      plot_df[1:nrow(results),variables_df[k,"name"]] = results[,variables_df[k,"name"]] 
      plot_df = plot_df[c(order(plot_df[,variables_df[k,"name"]])),]
      x_tick_labels = ""
      for(bin in 1:10){
        start_row = ceiling(nrow(plot_df)/10*(bin-1))+1
        end_row = ceiling(nrow(plot_df)/10*(bin))
        plot_df[start_row:end_row,"bin"] = toString(round(mean(plot_df[start_row:end_row,variables_df[k,"name"]]),3))
        x_tick_labels = c(x_tick_labels,toString(round(mean(plot_df[start_row:end_row,variables_df[k,"name"]]),3)))
      }
      x_tick_labels = x_tick_labels[2:length(x_tick_labels)]
      png(filename=outputName,height=600,width=1000,pointsize=12)
      p=ggplot(plot_df,aes(x=factor(x=plot_df$bin,levels=x_tick_labels,ordered=T),y=plot_df[,toString(output_df[j,"resultname"])]))+
        geom_boxplot(outlier.colour = "gray24", outlier.size = 3)+
        labs(y=toString(output_df[j,"resultnamed"]),x=variables_df[k,"display_name"],title="Total Variable Effect")+
        theme(plot.title=element_text(size=30,face="bold"),
              axis.title.x=element_text(size=24,face="bold"),
              axis.title.y=element_text(size=24,face="bold",vjust=2),
              axis.text.x=element_text(angle=60,hjust=1,color="black",size=14,face="bold"),
              axis.text.y=element_text(color="black",size=14,face="bold"),
              plot.margin=unit(c(1,1,5,1), "lines"))
      print(p)
      dev.off()
      graphics.off()
      lm_var = paste(toString(output_df[j,"resultname"])," ~ ",variables_df[k,"name"],sep="")
      l = lm(lm_var, data = plot_df)
      slope=coef(l)[2]
      intercept = coef(l)[1]
      f=summary(l)$fstatistic
      p=pf(f[1],f[2],f[3],lower.tail=F)
      scale_mult = diff(range(plot_df[,variables_df[k,"name"]]))
      slope_df[k,"slope"] = slope*scale_mult
      slope_df[k,"int"] = intercept
      slope_df[k,"p_value"] = p
      slope_df[k,"var"] = variables_df[k,"display_name"]
      slope_df[k,"result"] = variables_df[k,"name"]
    }
    outputName = tolower(substr(toString(data_for_analysis[i,"building_display_name"]),1,1))
    outputName = paste(outputName, substr(toString(data_for_analysis[i,"building_display_name"]),2,nchar(toString(data_for_analysis[i,"building_display_name"]))),sep="")
    outputName = paste(outputName, toupper(substr(toString(output_df[j,"varname"]),1,1)),sep="")
    outputName = paste(outputName, substr(toString(output_df[j,"varname"]),2,nchar(toString(output_df[j,"varname"]))),sep="")
    outputName = paste(outputName,"_0",".png",sep="")
    slope_df = slope_df[c(order(slope_df$slope,decreasing=TRUE)),]
    x_tick_labels = ""
    for(k in 1:nrow(slope_df)){
      x_tick_labels = c(x_tick_labels,slope_df[k,"var"])
    }
    x_tick_labels = x_tick_labels[2:length(x_tick_labels)]
    png(filename=outputName,height=600,width=1000,pointsize=12)
    p=ggplot(slope_df,aes(x=factor(x=slope_df$var,levels=x_tick_labels,ordered=T),y=slope_df$slope))+
      geom_bar(aes(fill=slope_df$p_value),stat="identity")+
      scale_fill_gradientn(name = "P-Value",limits=c(0,1),breaks=c(0.05,0.25,0.5,0.75,1),
                           colours=c('#FFFFE5','#FFF7BC','#FEE391','#FEC44F','#FB9A29','#EC7014','#CC4C02','#993404','#662506'),
                           values=c(0,0.025,0.05,0.075,0.1,0.25,0.5,0.75,1))+
      guides(fill = guide_colorbar(barwidth = 1, barheight = 15))+
      theme(plot.title=element_text(size=24,face="bold"),
            axis.title.x= element_blank(),
            axis.title.y=element_text(size=18,face="bold",vjust=2),
            axis.text.x=element_text(angle=60,hjust=1,color="black",size=10,face="bold"),
            axis.text.y=element_text(color="black",size=14,face="bold"),
            legend.title = element_text(size=16, face="bold"),
            plot.margin=unit(c(1,1,5,1), "lines"))
    print(p)
    dev.off()
    graphics.off()
    for(k in 1:nrow(predictor_slope_df)){
      predictor_slope_df[slope_df[k,"result"],toString(output_df[j,"resultname"])] = slope_df[k,"slope"]
      predictor_intercept_df[slope_df[k,"result"],toString(output_df[j,"resultname"])] = slope_df[k,"int"]
    }
  }
  setwd("../linear_models")
  save(predictor_slope_df,predictor_intercept_df,file=paste(toString(data_for_analysis[i,"building_name"]),"linear_model.RData",sep="_"))
  setwd("..")
}