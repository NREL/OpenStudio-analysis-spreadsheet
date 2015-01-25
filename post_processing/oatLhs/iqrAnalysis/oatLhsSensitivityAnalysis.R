require(grid)
require(ggplot2)
require(stats)
require(grid)

#Figure out how to handel paths for the spreadsheet repo
setwd("C:/gitRepositories/OpenStudio-analysis-spreadsheet/post_processing/oatLhs/iqrAnalysis")
wd_base = "."

#Load in resources datasheets dynamically
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
if(!file.exists("sensitivity_dfs")){
  dir.create("sensitivity_dfs")
}
heat_map_storage = list()
for(i in 1:nrow(output_df)){
  heat_map_df = data.frame()
  for(j in 1:nrow(data_for_analysis)){
    #Initialize outside loop for heat-mapping
    load(paste(wd_base,data_for_analysis[j,"results_dataframe"],sep="/"))
    load(paste(wd_base,data_for_analysis[j,"metadata_dataframe"],sep="/"))
    vs = subset(metadata, perturbable == TRUE)
    plot_df = data.frame()
    x_tick_labels = ""
    for(k in 1:nrow(vs)){
      non_static_rows = c()
      for(row_index in 1:nrow(results)){
        if(vs[k,'static_value']!=results[row_index,vs[k,'name']]){
          non_static_rows = rbind(non_static_rows,results[row_index,])
        }
      }
      start_index = nrow(plot_df)+1
      end_index = nrow(plot_df)+nrow(non_static_rows)
      plot_df[start_index:end_index,toString(output_df[i,'resultname'])] = non_static_rows[,toString(output_df[i,'resultname'])]
      plot_df[start_index:end_index,'var'] = vs[k,'display_name']
      x_tick_labels = c(x_tick_labels,vs[k,'display_name'])
      heat_map_index = nrow(heat_map_df)+1
      heat_map_df[heat_map_index,'result'] = toString(output_df[i,'resultnamed'])
      heat_map_df[heat_map_index,'building'] = toString(data_for_analysis[j,'building_display_name'])
      heat_map_df[heat_map_index,'var'] = vs[k,'display_name']
      heat_map_df[heat_map_index,'iqr'] = IQR(non_static_rows[,toString(output_df[i,'resultname'])])
    }
    x_tick_labels = x_tick_labels[2:length(x_tick_labels)]
    outputName = paste(toString(toString(data_for_analysis[j,'building_display_name'])),toString(output_df[i,'resultnamed']))
    outputName = paste(outputName,'.png',sep='')
    setwd('post_processing_graphs')
    png(filename=outputName,height=600,width=1000,pointsize=12)
    p=ggplot(plot_df,aes(x=factor(x=plot_df$var,levels=plot_df$var,ordered=T),y=plot_df[,toString(output_df[i,'resultname'])]))+
      geom_boxplot(outlier.colour = "gray24", outlier.size = 3)+
      labs(y=toString(output_df[i,"resultnamed"]),x='Perturbed Variable',title=paste(toString(data_for_analysis[j,'building_display_name']),"One-at-a-Time Variable Sensitivity"))+
      theme(plot.title=element_text(size=30,face="bold"),
            axis.title.x=element_text(size=24,face="bold"),
            axis.title.y=element_text(size=24,face="bold",vjust=2),
            axis.text.x=element_text(angle=60,hjust=1,color="black",size=10,face="bold"),
            axis.text.y=element_text(color="black",size=14,face="bold"),
            plot.margin=unit(c(1,1,5,1), "lines"))
    print(p)
    dev.off()
    graphics.off()
    setwd('..')
  }
  heat_map_storage[[i]] = heat_map_df
}
setwd('post_processing_graphs')
for(i in 1:length(heat_map_storage)){
  active_df = heat_map_storage[[i]]
  outputName = paste(active_df[1,'result'],"Heatmap")
  outputName = paste(outputName,'.png',sep='')
  png(filename=outputName,height=600,width=1000,pointsize=12)
  p=ggplot(active_df,aes(x=active_df$building,y=active_df$var,fill=active_df$iqr))+
    geom_tile()+
    labs(y='Variables',x='Building',title=paste(active_df[1,'result'],"Heatmap"))+
    scale_fill_gradientn(name = "IQR",
                         colours=c('#FFFFE5','#FFF7BC','#FEE391','#FEC44F','#FB9A29',
                                   '#EC7014','#CC4C02','#993404','#662506'))+
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
}
setwd('..')
setwd('sensitivity_dfs')
save(heat_map_storage,file='heatmap_df.RData')
setwd('..')