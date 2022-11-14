library(ggplot2)
args = commandArgs(trailingOnly = TRUE)
#setwd("args[1]") #where the results are stored
zoom = 3

predict_result_path = args[1]
MAE_path = args[2]
r2_path = args[3]
results_pdf = args[4]

plot_y_vs_predict_y <- function(y,predict_y,mae,r_squared){
  df <- data.frame(y=y,predicted_y=predict_y)
  mae_label = paste("MAE: ", as.character(round(mean(mae),2))," ± ",as.character(round(sd(mae),2))," yr",sep = "")
  r2_label = paste("R squared: ", as.character(round(mean(r_squared)*100,2))," ± ",as.character(round(sd(r_squared)*100,2))," %",sep = "")
  ggplot(df, aes(x = y, y = predicted_y)) + 
    ylab(paste("Predicted ", "age", sep = "")) + 
    xlab(paste("Observed ", "age", sep = "")) + 
    geom_point(alpha = 0.1) + 
    geom_smooth(method = "loess", span = 1) + 
    annotate(geom = "text", x = Inf, y = Inf, label = mae_label, color = "grey40", vjust = 2.4, hjust = 1.5) + 
    annotate(geom = "text", x = Inf, y = Inf, label = r2_label, color = "grey40", vjust = 4, hjust = 1.25) + 
    theme_bw()
}
#998 phenotype
predict_result <- read.csv(predict_result_path, header=T, sep=",", quote="", comment.char="")
predict_result <- predict_result[,-1]

mae <- read.table(MAE_path, header=F, sep=",", quote="", comment.char="")
mae <- mae$V1
R_squared <- read.table(r2_path, header=F, sep=",", quote="", comment.char="")
R_squared <- R_squared$V1

p <- plot_y_vs_predict_y(predict_result$age, predict_result$predict_age, mae, R_squared)

ggsave(results_pdf, p, width=75*zoom, height=75*zoom, units="mm")


