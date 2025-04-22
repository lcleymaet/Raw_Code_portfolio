library(terra)
library(sf)
library(tidyverse)
library(tidyterra)
library(raster)
library(sp)
library(elevatr)
library(lattice)
library(MASS)
require(pscl)


#load grid as sf
grid <- read_sf("final_set/grids_distances/grids.shp") 


#fill in na's in elevation, assigning polygon centroids
grid <- get_elev_point(grid, src = "epqs",prj = st_crs(grid))

#subset for effort and duration that are not na to model to locations without this information
effort <- filter(grid, !is.na(av_drtn))
duration <- filter(grid, !is.na(av_drtn))

#make predictive model for effort and duration
#check effort distance distribution
png(filename = "final_set/plots/ffrt_dist_hist.png")
hist(effort$av_ffrt, main = "Distribution of effort distance values", freq = F) #heavily right skewed, looks poisson
dev.off()

ffrtLM <- glm(av_ffrt ~ av_drtn + av_wtr_ + av_rl_d + elevation + av_rd_d + a__UAC2, 
              data = effort, family = poisson)

png(filename = "final_set/plots/fitted_ffrt_dists.png")
hist(ffrtLM$fitted.values, main = "Fitted values of effort distance", freq = F)
dev.off()

predictors <- cbind(data.frame(coef = matrix(1, nrow = nrow(grid), ncol = 1)),
                    as.data.frame(grid[,c(9,13,14,22,12,15)])) %>% 
  mutate(av_drtn = ifelse(is.na(av_drtn), 0, av_drtn))%>%
  st_drop_geometry() 
predictors <- predictors[,1:7]
frt.fit = matrix(nrow = nrow(grid), ncol = 1)
for(i in 1:nrow(grid)){
  if(!is.na(filter(grid, row_number() == i)%>%pull(av_ffrt))){
    frt.fit[i] <- filter(grid, row_number() == i)%>%pull(av_ffrt)
    next
  }else{
    temp = ffrtLM$coefficients[1]
    for(j in 2:7){
     temp = temp + (ffrtLM$coefficients[j] * predictors[i,j])
    } 
    temp <- as.numeric(temp)
    print(i)
    frt.fit[i] <- temp
  }
}

#add fitted values to grid
grid$ffrt_dist <- frt.fit[,1]

#now do duration
png(filename = "final_set/plots/duration_dist.png")
hist(duration$av_drtn, freq = F, main = "Distribution of duration (min)")
dev.off()

duration <- cbind(ffrtLM$fitted.values, duration)
#poisson was bad, try gamma
timeLM <- glm(av_drtn ~ av_wtr_ + av_rl_d + elevation + av_rd_d + a__UAC2, 
              data = duration, family = Gamma("inverse"))

png(filename = "final_set/plots/duration_fitted.png")
hist(timeLM$fitted.values, freq = F, main = "Fitted values for duration")
dev.off()

#predictors <- predictors[,2:7]
frt.fit = matrix(nrow = nrow(grid), ncol = 1)
for(i in 1:nrow(grid)){
  if(!is.na(filter(grid, row_number() == i)%>%pull(av_drtn))){
    frt.fit[i] <- filter(grid, row_number() == i)%>%pull(av_drtn)
    next
  }else{
    temp = timeLM$coefficients[1]
    for(j in 2:6){
      temp = temp + (timeLM$coefficients[j] * predictors[i,j])
    } 
    frt.fit[i] <- temp
  }
}

grid$ffrt_drtn <- frt.fit

#write out for Celime to use in his model
st_write(grid, "final_set/model_set/grid_final.shp", append = F)




