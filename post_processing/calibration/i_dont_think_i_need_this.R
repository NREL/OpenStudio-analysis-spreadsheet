require(ggplot2)
require(grid)

top_dir = "C:/gitRepositories/cofee-analysis"
setwd(top_dir)
setwd("structures")
folder_list = dir()
master_frame = data.frame()
for(i in 1:length(folder_list)){
  master_frame[i,"folder_id"] = folder_list[i]
  setwd(master_frame[i,"folder_id"])
  master_frame[i,"m0"] = FALSE
  master_frame[i,"cal"] = FALSE
  master_frame[i,"ee"] = FALSE
  if(file.exists("model0")){
    master_frame[i,"m0"] = TRUE
  }
  if(file.exists("calibration")){
    master_frame[i,"cal"] = TRUE
  }
  if(file.exists("ee")){
    master_frame[i,"ee"] = TRUE
  }
  setwd("..")
}

cal_process = 1

if(cal_process == 1){
  cal_frame = master_frame[master_frame[,"cal"],]
  scraping_frame = data.frame()
  no_calibration_data_frame = list()
  metric_names = c("calibration_reports.electric_bill_consumption_cvrmse","calibration_reports.electric_bill_consumption_nmbe",
                   "calibration_reports.gas_bill_consumption_cvrmse","calibration_reports.gas_bill_consumption_nmbe")
  ee_measures = c("enable_demand_controlled_ventilation.dcv_type","economizer_control_type",
                  "ee_electric_equipment_power_reduction","enable_demand_controlled_ventilation","replace_t12s_with_t8s")
  ee_baseline = c("NoChange","NoChange",0,"NoChange",FALSE)
  for(i in 1:nrow(cal_frame)){
    if(i==48){next}
    scraping_frame[i,"gl14_met"] = FALSE
    setwd(cal_frame[i,"folder_id"])
    ee_flag = 0
#     if(cal_frame[i,"ee"]){
#       ee_flag = 1
#       setwd("ee")
#       data_path = paste("building_",cal_frame[i,"folder_id"],"_ee_results.RData",sep="")
#       if(file.exists(data_path)){
#         load(data_path)
#       }else{
#         no_calibration_data_frame[length(no_calibration_data_frame)+1] = paste(cal_frame[i,"folder_id"])
#         warning(paste("R Data Frame was not found in ",data_path,sep=""))
#         setwd("../..")
#         next
#       }
#     }else{
      setwd("calibration")
      data_path = paste("building_",cal_frame[i,"folder_id"],"_calibration_results.RData",sep="")
      if(file.exists(data_path)){
        load(data_path)
      }else{
        no_calibration_data_frame[length(no_calibration_data_frame)+1] = paste(cal_frame[i,"folder_id"])
        warning(paste("R Data Frame was not found in ",data_path,sep=""))
        setwd("../..")
        next
      }
#     }
    if(ee_flag == 0){
      for(j in 1:nrow(results)){
        guideline14_vec = abs(results[j,"calibration_reports.electric_bill_consumption_cvrmse"]) < 15
        guideline14_vec = c(guideline14_vec, abs(results[j,"calibration_reports.electric_bill_consumption_nmbe"]) < 5)
        guideline14_vec = c(guideline14_vec, abs(results[j,"calibration_reports.gas_bill_consumption_cvrmse"]) < 15)
        guideline14_vec = c(guideline14_vec, abs(results[j,"calibration_reports.gas_bill_consumption_nmbe"]) < 5)
        num_satisfied = length(metric_names[guideline14_vec])
        results[j,"guidelines_met"] = num_satisfied
        scraping_frame[i,"folder_id"] = cal_frame[i,"folder_id"]
        if(num_satisfied==4){
          scraping_frame[i,"elec_cvrmse"] = results[j,"calibration_reports.electric_bill_consumption_cvrmse"]
          scraping_frame[i,"elec_nmbe"] = results[j,"calibration_reports.electric_bill_consumption_nmbe"]
          scraping_frame[i,"gas_cvrmse"] = results[j,"calibration_reports.gas_bill_consumption_cvrmse"]
          scraping_frame[i,"gas_nmbe"] = results[j,"calibration_reports.gas_bill_consumption_nmbe"]
          scraping_frame[i,"guidelines_met"] = results[j,"guidelines_met"]
          scraping_frame[i,"row"] = j
          scraping_frame[i,"gl14_met"] = TRUE
          scraping_frame[i,"prevented"] = FALSE
          scraping_frame[i,"cal_failure"] = FALSE
          scraping_frame[i,"questionable"] = FALSE
          scraping_frame[i,"preposterous"] = FALSE
          scraping_frame[i,"distance"] = sqrt(sum(results[j,metric_names]^2))
          break
        }
      }
      if(!scraping_frame[i,"gl14_met"]){
        for(j in 1:nrow(results)){
          results[j,"distance"] = sqrt(sum(results[j,metric_names]^2))
        }
        results = results[order(results$"distance", decreasing = FALSE),]
        best_result = results[1,]
        scraping_frame[i,"elec_cvrmse"] = best_result["calibration_reports.electric_bill_consumption_cvrmse"]
        scraping_frame[i,"elec_nmbe"] = best_result["calibration_reports.electric_bill_consumption_nmbe"]
        scraping_frame[i,"gas_cvrmse"] = best_result["calibration_reports.gas_bill_consumption_cvrmse"]
        scraping_frame[i,"gas_nmbe"] = best_result["calibration_reports.gas_bill_consumption_nmbe"]
        scraping_frame[i,"row"] = j
        scraping_frame[i,"gl14_met"] = FALSE
        scraping_frame[i,"prevented"] = FALSE
        scraping_frame[i,"cal_failure"] = FALSE
        scraping_frame[i,"questionable"] = FALSE
        scraping_frame[i,"preposterous"] = FALSE
        scraping_frame[i,"distance"] = best_result["distance"]
        if(best_result["guidelines_met"] == 0){scraping_frame[i,"cal_failure"] = TRUE}
        if(best_result["guidelines_met"] == 3){scraping_frame[i,"prevented"] = TRUE}
        scraping_frame[i,"guidelines_met"] = best_result["guidelines_met"]
        if(max(best_result[metric_names])>100){scraping_frame[i,"questionable"] = TRUE}
        if(max(best_result[metric_names])>1000){scraping_frame[i,"preposterous"] = TRUE}
      }
    }else{
      for(j in 1:nrow(results)){
        if(all(results[j,ee_measures] == ee_baseline)){
          baseline = results[j,]
          guideline14_vec = abs(baseline["calibration_reports.electric_bill_consumption_cvrmse"]) < 15
          guideline14_vec = c(guideline14_vec, abs(baseline["calibration_reports.electric_bill_consumption_nmbe"]) < 5)
          guideline14_vec = c(guideline14_vec, abs(baseline["calibration_reports.gas_bill_consumption_cvrmse"]) < 15)
          guideline14_vec = c(guideline14_vec, abs(baseline["calibration_reports.gas_bill_consumption_nmbe"]) < 5)
          num_satisfied = length(metric_names[guideline14_vec])
          scraping_frame[i,"guidelines_met"] = num_satisfied
          scraping_frame[i,"folder_id"] = cal_frame[i,"folder_id"]
          scraping_frame[i,"elec_cvrmse"] = baseline["calibration_reports.electric_bill_consumption_cvrmse"]
          scraping_frame[i,"elec_nmbe"] = baseline["calibration_reports.electric_bill_consumption_nmbe"]
          scraping_frame[i,"gas_cvrmse"] = baseline["calibration_reports.gas_bill_consumption_cvrmse"]
          scraping_frame[i,"gas_nmbe"] = baseline["calibration_reports.gas_bill_consumption_nmbe"]
          scraping_frame[i,"row"] = j
          scraping_frame[i,"gl14_met"] = FALSE
          if(num_satisfied==4){scraping_frame[i,"gl14_met"] = TRUE}
          scraping_frame[i,"prevented"] = FALSE
          scraping_frame[i,"cal_failure"] = FALSE
          scraping_frame[i,"questionable"] = FALSE
          scraping_frame[i,"preposterous"] = FALSE
          scraping_frame[i,"distance"] = baseline["distance"]
          if(baseline["guidelines_met"] == 0){scraping_frame[i,"cal_failure"] = TRUE}
          if(baseline["guidelines_met"] == 3){scraping_frame[i,"prevented"] = TRUE}
          scraping_frame[i,"guidelines_met"] = baseline["guidelines_met"]
          if(max(baseline[metric_names])>100){scraping_frame[i,"questionable"] = TRUE}
          if(max(baseline[metric_names])>1000){scraping_frame[i,"preposterous"] = TRUE}
        }
      }
    }
    setwd("../..")
  }
  cal_post = data.frame()
  for(i in 1:nrow(scraping_frame)){
    if(all(!is.na(scraping_frame[i,]))){
      cal_post = rbind(cal_post,scraping_frame[i,])
    }
  }
  if(length(no_calibration_data_frame)!=0){print("Calabration folder(s) skipped. Please see no_calibration_data_frame for a list.")}
  setwd("..")
}


cal_graphing = 1

if(cal_graphing == 1){
  if(!exists("cal_post")){stop("The cal_post dataframe could not be found. Please re-create or load it?")}
  graphing_df = cal_post[!cal_post$preposterous,]
#   graphing_df = cal_post[!cal_post$questionable,]
  for(i in 1:nrow(graphing_df)){
    if(graphing_df[i,"guidelines_met"]==0){
      graphing_df[i,"result_type"] = "No Guidelines Met"
    }else if(graphing_df[i,"guidelines_met"]==3){
      graphing_df[i,"result_type"] = "Single Unmet Guideline"
    }else if(graphing_df[i,"guidelines_met"]==4){
      graphing_df[i,"result_type"] = "Calibrated"
    }else{
      graphing_df[i,"result_type"] = "Some Guidelines Met"
    }
  }
  graphing_df = data.frame(result_type = factor(c(graphing_df[,"result_type"]), levels=c(graphing_df[,"result_type"]),ordered=TRUE),
                           elec_cvrmse=graphing_df[,"elec_cvrmse"], elec_nmbe=graphing_df[,"elec_nmbe"],
                           gas_cvrmse=graphing_df[,"gas_cvrmse"], gas_nmbe=graphing_df[,"gas_nmbe"])
  
  if(!file.exists("post_processing_graphs")){
    dir.create("post_processing_graphs")
  }
  setwd("post_processing_graphs")
  
  max_x = max(graphing_df[,"elec_cvrmse"])
  max_y = max(graphing_df[,"elec_nmbe"])
  min_x = min(graphing_df[,"elec_cvrmse"])
  min_y = min(graphing_df[,"elec_nmbe"])
  
  png(filename="electricityMetrics.png",height=600,width=1000,pointsize=12)
  ggplot(data=graphing_df,aes(x=elec_cvrmse,y=elec_nmbe))+
    geom_segment(aes(x = -15, y = 5, xend = 15, yend = 5),size=1.25,lineend="square")+
    geom_segment(aes(x = -15, y = -5, xend = 15, yend = -5),size=1.25,lineend="square")+
    geom_segment(aes(x = -15, y = -5, xend = -15, yend = 5),size=1.25,lineend="square")+
    geom_segment(aes(x = 15, y = -5, xend = 15, yend = 5),size=1.25,lineend="square")+
    geom_segment(aes(x = -15, y = 5, xend = -15, yend = max_y),size=1.25,lineend="square")+
    geom_segment(aes(x = -15, y = 5, xend = min_x, yend = 5),size=1.25,lineend="square")+
    geom_segment(aes(x = -15, y = -5, xend = -15, yend = min_y),size=1.25,lineend="square")+
    geom_segment(aes(x = -15, y = -5, xend = min_x, yend = -5),size=1.25,lineend="square")+
    geom_segment(aes(x = 15, y = 5, xend = 15, yend = max_y),size=1.25,lineend="square")+
    geom_segment(aes(x = 15, y = 5, xend = max_x, yend = 5),size=1.25,lineend="square")+
    geom_segment(aes(x = 15, y = -5, xend = 15, yend = min_y),size=1.25,lineend="square")+
    geom_segment(aes(x = 15, y = -5, xend = max_x, yend = -5),size=1.25,lineend="square")+
    geom_point(aes(colour=result_type),size=5,alpha=.5)+
    geom_point(aes(shape=result_type),size=2.5)+
    labs(y=paste("Electric NMBE"),x="Electric CV(RMSE)")+
    scale_shape_discrete(name="End State")+
    scale_colour_discrete(name="End State")+
    theme(axis.title.x=element_text(size=24,face="bold"),
          axis.title.y=element_text(size=24,face="bold",vjust=2),
          axis.text.x=element_text(angle=60,hjust=1,color="black",size=14,face="bold"),
          axis.text.y=element_text(color="black",size=14,face="bold"),
          legend.position="top",
          legend.title = element_text(size=16, face="bold"),
          legend.title = element_text(size=16, face="bold"),
          plot.margin=unit(c(1,1,5,1), "lines"))
  dev.off()
  max_x = max(graphing_df[,"gas_cvrmse"])
  max_y = max(graphing_df[,"gas_nmbe"])
  min_x = min(graphing_df[,"gas_cvrmse"])
  min_y = min(graphing_df[,"gas_nmbe"])
  
  png(filename="gasMetrics.png",height=600,width=1000,pointsize=12)
  ggplot(data=graphing_df,aes(x=gas_cvrmse,y=gas_nmbe))+
    geom_segment(aes(x = -15, y = 5, xend = 15, yend = 5),size=1.25,lineend="square")+
    geom_segment(aes(x = -15, y = -5, xend = 15, yend = -5),size=1.25,lineend="square")+
    geom_segment(aes(x = -15, y = -5, xend = -15, yend = 5),size=1.25,lineend="square")+
    geom_segment(aes(x = 15, y = -5, xend = 15, yend = 5),size=1.25,lineend="square")+
    geom_segment(aes(x = -15, y = 5, xend = -15, yend = max_y),size=1.25,lineend="square")+
    geom_segment(aes(x = -15, y = 5, xend = min_x, yend = 5),size=1.25,lineend="square")+
    geom_segment(aes(x = -15, y = -5, xend = -15, yend = min_y),size=1.25,lineend="square")+
    geom_segment(aes(x = -15, y = -5, xend = min_x, yend = -5),size=1.25,lineend="square")+
    geom_segment(aes(x = 15, y = 5, xend = 15, yend = max_y),size=1.25,lineend="square")+
    geom_segment(aes(x = 15, y = 5, xend = max_x, yend = 5),size=1.25,lineend="square")+
    geom_segment(aes(x = 15, y = -5, xend = 15, yend = min_y),size=1.25,lineend="square")+
    geom_segment(aes(x = 15, y = -5, xend = max_x, yend = -5),size=1.25,lineend="square")+
    geom_point(aes(colour=result_type),size=5,alpha=.5)+
    geom_point(aes(shape=result_type),size=2.5)+
    scale_shape_discrete(name="End State")+
    scale_colour_discrete(name="End State")+
    labs(y=paste("Gas NMBE"),x="Gas CV(RMSE)")+
    theme(axis.title.x=element_text(size = rel(2),face="bold"),
          axis.title.y=element_text(size=rel(2),face="bold",vjust=2),
          axis.text.x=element_text(angle=60,hjust=1,color="black",size=rel(1.5),face="bold"),
          axis.text.y=element_text(color="black",size=rel(1.5),face="bold"),
          legend.position="top",
          legend.title = element_text(size=16, face="bold"),
          legend.title = element_text(size=16, face="bold"),
          plot.margin=unit(c(1,1,5,1), "lines"))
  dev.off()
  
  setwd("..")
}