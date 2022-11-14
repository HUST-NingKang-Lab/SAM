library(ggplot2)
library(dplyr)
library(caret)
options (stringsAsFactors = FALSE)
args = commandArgs(trailingOnly = TRUE)
source(args[1])

# phenotype_data
phenotype_data = args[2]

# microbiota_data
microbiota_data = args[3]

#output path
output = args[4]

setwd(output)

#theme
mytheme <- theme(
  panel.grid.major=element_blank(),
  panel.grid.minor=element_blank(),
  panel.background=element_blank(),
  legend.position="none")

#Chinese-SP cohort
#SPA
#input
all_phenotype <- read.table(phenotype_data, row.names = 1, header=T, sep="\t", quote="", comment.char="")
phenotype_feature <- c("Whitening", "Sebum", "Porphyrins", "Texture", "Melanin", "Pore",
                       "Spot", "Wrinkle", "Hemoglobin", "Ultravioletspot")

#5folds random forests
x <- all_phenotype[, phenotype_feature]
y <- all_phenotype[, "Age"]

result <- rf.regression.cross_validation(x, y, nfolds = 5)

#save SPA
predict_result <- data.frame(sample=rownames(all_phenotype),age=result$y,predict_age=result$predicted)
colnames(predict_result)[3] <- "phenotype_age"
write.table(predict_result, "SPA.txt",
            sep="\t", row.names = F, quote = F, col.names = T)

#random forests result--plot
p <- plot_y_vs_predict_y(result$y, result$predicted, result$MAE,result$R_squared)
zoom=2.5
ggsave("SPA.pdf", p, width=75*zoom, height=75*zoom, units="mm")

#feature importance
feature_importance <- as.data.frame(result$importances)
feature_importance$sd <- apply(feature_importance[,1:5],1,sd)
feature_importance <- feature_importance[order(feature_importance$rank),]

#save feature importance table
save_feature_importance(feature_importance, "SPA_importance.txt")

#plot feature importance
p <- ggplot(feature_importance, aes(x = reorder(rownames(feature_importance),mean), y = mean))+
  geom_bar(stat="identity", color= "#BEBDBD", fill="#BEBDBD")+
  coord_flip()+
  labs(x = 'Feature', y = 'Importance')+
  mytheme+
  geom_errorbar(aes(ymin = mean - sd,
                    ymax = mean + sd),width = .3,color="black")
zoom=2.5
ggsave("SPA_importance.pdf", p, width=40*zoom, height=75*zoom, units="mm")

#Males vs Females
female_sample <- rownames(all_phenotype[which(all_phenotype$Gender=="Female"),])
male_sample <- rownames(all_phenotype[which(all_phenotype$Gender=="Male"),])
female_phenotype <- all_phenotype[female_sample,]
male_phenotype <- all_phenotype[male_sample,]

#Modeling using Female samples
x <- female_phenotype[,phenotype_feature]
y <- female_phenotype[,"Age"]

result <- rf.regression.cross_validation(x, y, nfolds = 5)

#Female SPA
predict_result_female <- data.frame(y=result$y, predict=result$predicted)
predict_result_female$SampleID <- rownames(female_phenotype)
predict_result_female$Gender <- "Female"
predict_result_female <- select(predict_result_female, "SampleID",everything())

#plotting
p <- plot_y_vs_predict_y(result$y, result$predicted, result$MAE,result$R_squared)
zoom=2.5
ggsave("SPA_females.pdf",
       p, width=75*zoom, height=75*zoom, units="mm")

#Female model predicing male samples
newx <- male_phenotype[, phenotype_feature]
true_y <- male_phenotype[,"Age"]
predict_newx_result <- predict_newx(result$rf.model, newx, true_y)

#Male SPA
predict_result_male <- data.frame(y=true_y, predict=predict_newx_result$predicted_y[,"mean"])
predict_result_male$SampleID <- rownames(male_phenotype)
predict_result_male$Gender <- "Male"
predict_result_male <- select(predict_result_male, "SampleID",everything())

#plotting
p <- plot_y_vs_predict_y(predict_result_male$y, predict_result_male$predict, predict_newx_result$MAE,predict_newx_result$R_squared)
zoom=2.5
ggsave("SPA_males.pdf",
       p, width=75*zoom, height=75*zoom, units="mm")

#Combine Female SPA and Male SPA
combined_predict_result <- rbind(predict_result_female,predict_result_male)
combined_predict_result$Gender <- factor(combined_predict_result$Gender,levels = c("Male","Female"))
colnames(combined_predict_result)[2:3] <- c("age","phenotype_age")
write.table(combined_predict_result, "./SPA_gender_comparison.txt",
            sep="\t", row.names = F, quote = F, col.names = T)

#plotting
p <- ggplot(combined_predict_result,aes(x=age, y=phenotype_age, color=Gender)) + geom_point() +
  stat_smooth(method = "loess", span = 1, se=TRUE) + 
  scale_color_manual(values = c("#3677AD", "#D5221E")) + 
  ylab(paste("Predicted ", "age", sep = "")) + 
  xlab(paste("Observed ", "age", sep = "")) +
  theme_bw() #+theme(legend.position="none")#去掉图例

zoom=2.5
ggsave("./SPA_gender_comparison.pdf",
       p, width=75*zoom, height=75*zoom, units="mm")

#Chinese SI cohort
#SMA
#input
mep <- read.table(microbiota_data, row.names = 1, header=T, sep="\t", quote="", comment.char="")
metadata <- data.frame(row.names = rownames(mep), "Product" = mep$Product, "Age" = mep$Age)
mep = mep[,-1] #strip product column
mep = mep[,-1] #strip age column
#This study only investigated females aged 20-35 (n = 204个)
young_sample <- rownames(metadata[which(metadata$Age<=35),])
pre_sample <- rownames(metadata[which(metadata$Product=="Pre"),])
pre_young_sample <- intersect(pre_sample, young_sample)
aft_sample <- rownames(metadata[which(metadata$Product=="Aft"),])
aft_young_sample <- intersect(aft_sample, young_sample)

################### SMA model
#modify taxa name
colnames(mep) <- gsub("\\|",".",colnames(mep))

#filter taxa with zero variance
mep <- mep[,which(apply(mep,2,var)!=0)]
cat("The number of fitlered variables (removed variables with zero variance) : ", ncol(mep) ,"\n")

#filter taxa with abs = 0 in more than 99% samples
Zero.p <- 0.99
mep <- mep[,which(colSums(mep==0)<Zero.p*nrow(mep))]
cat("The number of variables (removed variables containing over ", Zero.p," zero) in training data: ", ncol(mep) ,"\n")

#add age to the abundance table
mep$Age <- metadata[rownames(mep),]$Age

#divided sample to pre/aft intervenion groups
pre_young_mep <- mep[pre_young_sample,]
aft_young_mep <- mep[aft_young_sample,]

#training on the pre-intervention samples
x <- pre_young_mep[, -ncol(pre_young_mep)]
y <- pre_young_mep[, "Age"]
set.seed(1)
result <- rf.regression.cross_validation(x, y, nfolds = 5)

#rank the feature by importances
feature_importance <- as.data.frame(result$importances)
feature_importance$sd <- apply(feature_importance[,1:5],1,sd)
feature_importance <- feature_importance[order(feature_importance$rank),]
save_feature_importance(feature_importance, "./SMA_importance.txt")

#select the features with the top importance for the modeling; and determine the number of the features used for the trained model for best performance
repeated_top_n_perf <- repeated_cv_feature_select(x, y, feature_importance, nfolds = 10, repeats = 5)
repeated_top_n_perf$n_features <- log2(repeated_top_n_perf$n_features)
p <- ggplot(repeated_top_n_perf)+
  geom_line(aes(x=repeated_top_n_perf[,1],y=repeated_top_n_perf[,2]), color="#BDBDBD", size=1.5)+
  geom_line(aes(x=repeated_top_n_perf[,1],y=repeated_top_n_perf[,3]), color="#BDBDBD", size=1.5)+
  geom_line(aes(x=repeated_top_n_perf[,1],y=repeated_top_n_perf[,4]), color="#BDBDBD", size=1.5)+
  geom_line(aes(x=repeated_top_n_perf[,1],y=repeated_top_n_perf[,5]), color="#BDBDBD", size=1.5)+
  geom_line(aes(x=repeated_top_n_perf[,1],y=repeated_top_n_perf[,6]), color="#BDBDBD", size=1.5)+
  geom_line(aes(x=repeated_top_n_perf[,1],y=repeated_top_n_perf[,"mean"]), size=1.5)+
  scale_x_continuous(breaks=(repeated_top_n_perf$n_features), labels = 2^(repeated_top_n_perf$n_features))+
  xlab("# of features used ") + 
  ylab("MAE") + 
  theme_bw()

p <- p + geom_errorbar(aes(x = repeated_top_n_perf[,1],
                           y = repeated_top_n_perf[,"mean"],
                           ymin = mean - sd,
                           ymax = mean + sd),width = .3,color="black")
zoom=2.5
ggsave("./Determine_the_best_number_of_the_microbial_features.pdf",
       p, width=75*zoom, height=75*zoom, units="mm")

#After rounds of experiments, 32 was finally chosen
select_feature <- rownames(feature_importance[which(feature_importance$rank<=32),])

x <- pre_young_mep[, select_feature]
y <- pre_young_mep[, "Age"]

set.seed(11)
result <- rf.regression.cross_validation(x, y, nfolds = 5)

#pre young microbiota_age：
predict_result_pre_young <- data.frame(y=result$y, predict=result$predicted)
predict_result_pre_young$SampleID <- rownames(pre_young_mep)
predict_result_pre_young$Product <- "Pre"
predict_result_pre_young <- select(predict_result_pre_young, "SampleID",everything())

#pre young microbiota_age：random forests result--plot
p <- plot_y_vs_predict_y(result$y, result$predicted, result$MAE,result$R_squared)

zoom=2.5
ggsave("./SMA_pre_intervention.pdf",
       p, width=75*zoom, height=75*zoom, units="mm")

#using the model trained by the pre-intervention samples to predict the aft-intervention samples.
newx <- aft_young_mep[,select_feature]
true_y <- aft_young_mep[,"Age"]
predict_newx_result <- predict_newx(result$rf.model, newx, true_y)

#aft young microbiota_age：
predict_result_aft_young <- data.frame(y=true_y, predict=predict_newx_result$predicted_y[,"mean"])
predict_result_aft_young$SampleID <- rownames(aft_young_mep)
predict_result_aft_young$Product <- "Aft"
predict_result_aft_young <- select(predict_result_aft_young, "SampleID",everything())

#aft young microbiota_age：random forests result--plot
p <- plot_y_vs_predict_y(predict_result_aft_young$y, predict_result_aft_young$predict, 
                         predict_newx_result$MAE,predict_newx_result$R_squared)
zoom=2.5
ggsave("./SMA_aft_intervention.pdf", p, width=75*zoom, height=75*zoom, units="mm")

#combined young pre/aft microbiota_age
combined_predict_result <- rbind(predict_result_pre_young,predict_result_aft_young)
combined_predict_result$Product <- factor(combined_predict_result$Product,levels = c("Pre","Aft"))
colnames(combined_predict_result)[2:3] <- c("age","microbiota_age")
write.table(combined_predict_result, "./SMA.txt",
            sep="\t", row.names = F, quote = F, col.names = T)

#young pre/aft microbiota_age point_plot
p <- ggplot(combined_predict_result,aes(x=age, y=microbiota_age, color=Product)) + geom_point() +
  stat_smooth(method = "loess", span = 1, se=TRUE) + 
  ylab(paste("Predicted ", "age", sep = "")) + 
  xlab(paste("Observed ", "age", sep = "")) +
  scale_color_manual(values = c("#4EA74A", "#8E4B99")) +
  theme_bw() #+ theme(legend.position="none")
zoom=2.5
ggsave("./SMA.pdf", p, width=75*zoom, height=75*zoom, units="mm")
