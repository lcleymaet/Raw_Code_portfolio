library(gstat)
library(sf)
library(terra)
library(tidyterra)
library(ggplot2)
library(nlme)
library(lme4)
library(gtools)
library(mgcv)
library(MASS)
library(raster)

#load dataset
dat <- read_sf("final_set/model_set/grid_final.shp")

#turn season into a factor
dat$SEASON_g <- as.factor(dat$SEASON_g)

#get one set of coordinates
coords <- st_coordinates(filter(dat, SEASON_g == "Spring"))

#Create separate sets for each season to model separately
fall <- filter(dat, SEASON_g == "Fall")
spring <- filter(dat, SEASON_g == "Spring")
summer <- filter(dat, SEASON_g == "Summer")
winter <- filter(dat, SEASON_g == "WINTER") #There are no present observations for this group

#try some models
null.mod <- glmer(PRES ~ elevation + av_rd_d + av_wtr_ + av_rl_d + a__UAC2 + (1|SEASON_g), 
                  data = dat, 
                  family = binomial(link = "logit")) #this one has lots of warnings
gmod <- glm(PRES ~ SEASON_g + elevation + av_rd_d + av_rl_d + a__UAC2 + av_wtr_, data = dat,
            family = binomial(link = "logit")) #this one is not great
AICtab <- AIC(gmod)
#plot(gmod)

gmodSP <- glm(PRES ~ elevation + av_rd_d + av_wtr_ + av_rl_d + a__UAC2 , 
              data = spring, 
              family = binomial(link = "logit")) 
gmodSU <- glm(PRES ~ elevation + av_rd_d + av_wtr_ + av_rl_d + a__UAC2, 
              data = summer, 
              family = binomial(link = "logit")) 
gmodWI <- glm(PRES ~ elevation + av_rd_d + av_wtr_ + av_rl_d + a__UAC2, 
              data = winter, 
              family = binomial(link = "logit")) 
gmodFA <- glm(PRES ~ elevation + av_rd_d + av_wtr_ + av_rl_d + a__UAC2, 
              data = fall, 
              family = binomial(link = "logit")) 

gamSP <- gam(PRES ~ s(elevation) + s(av_rd_d) + s(av_wtr_) + s(av_rl_d) + s(a__UAC2), 
              data = spring, 
              family = binomial(link = "logit")) 
gamSU <- gam(PRES ~ s(elevation) + s(av_rd_d) + s(av_wtr_) + s(av_rl_d) + s(a__UAC2), 
              data = summer, 
              family = binomial(link = "logit")) 
gamWI <- gam(PRES ~ s(elevation) + s(av_rd_d) + s(av_wtr_) + s(av_rl_d) + s(a__UAC2), 
              data = winter, 
              family = binomial(link = "logit")) 
gamFA <- gam(PRES ~ s(elevation) + s(av_rd_d) + s(av_wtr_) + s(av_rl_d) + s(a__UAC2), 
              data = fall, 
              family = binomial(link = "logit")) 

#make AIC table
AICtab <- rbind(AIC(gmod), AIC(gmodSP), AIC(null.mod), AIC(gmodSU), AIC(gmodWI), AIC(gmodFA),
                AIC(gamSP), AIC(gamSU), AIC(gamWI), AIC(gamFA))
rownames(AICtab) <- c("glm","spring","glmer","summer","winter","fall","gamSpring", "gamsummer", "gamwinter","gamfall")
AICtab

#separating by season makes better models, keep in mind winter has 0 observations, lets check correlation structure
#want to keep with mixed effects model
glmerResid <- residuals(null.mod)
resid_spat <- cbind(glmerResid, st_coordinates(dat)[,1], st_coordinates(dat)[,2])
colnames(resid_spat) <- c("resid","X","Y")
resid_df <- as.data.frame(resid_spat)
resid_sf <- st_as_sf(resid_df, coords = c("X","Y"))
vgram <- variogram(resid ~ 1,data = resid_sf, cutoff = 100000)
plot(vgram)

#residuals exhibit some spatial autocorrelation in plotting variogram
#fit to some options and see which is best
vfit <- fit.variogram(vgram, vgm(.15, "Exp", 40000, .61))

png(filename = "final_set/plots/residual_variogram_logreg.png")
plot(vgram, model = vfit, cutoff = 100000) #looks exponential
dev.off()

#residual spatial autocorrelation exhibits exponential semivariance
#Try another model
dat_df <- as.data.frame(dat)
dat_df$X <- st_coordinates(dat)[,1]
dat_df$Y <- st_coordinates(dat)[,2]
dat_df$dummy <- rep(1,nrow(dat_df))
# cormod <- glmmPQL(PRES ~ elevation + av_rd_d + av_wtr_ + av_rl_d + a__UAC2, 
#                   random = ~1 | SEASON_g, #season as random effect due to differences in seasonal p/a
#                   family = binomial(link = "logit"), data = dat_df, #binomial for logistic reg
#                   correlation = corExp(1, form = ~ X + Y)) #exponential spatial correlation structure
#this model for some reason isn't giving probabilities for unknown reason, try something else

#trying a different model here
gam_cor <- gam(
  PRES ~ s(elevation, by = SEASON_g, k = 20) + s(av_rd_d, by = SEASON_g, k = 20) + s(av_wtr_, by = SEASON_g, k = 20) +
    s(av_rl_d, by = SEASON_g, k = 20) + s(a__UAC2, by = SEASON_g, k = 20) + ffrt_dist + #SEASON_g +
    s(X, Y, bs = "tp"),  # Thin-plate spline for spatial effects
  family = binomial,          
  data = dat_df) #including duration breaks model
summary(gam_cor)
gam_cor_fit <- fitted(gam_cor)

gam.check(gam_cor)
plot.gam(gam_cor)
AICtab <-gam_corAICtab <- rbind(AICtab, AIC(gam_cor))
AICtab

#saving centroids to rasterize and prepping to rasterize
cents <- unique(as.data.frame(st_coordinates(dat)))
wint.rows <- which(dat$SEASON_g == "WINTER")
sp.rows <- which(dat$SEASON_g == "Spring")
su.rows <- which(dat$SEASON_g == "Summer")
fa.rows <- which(dat$SEASON_g == "Fall")


#rasterize results
mod <- data.frame(Z = gam_cor_fit, X = dat_df$X, Y = dat_df$Y)
#separating by season
SPmod <- mod[sp.rows,]
WImod <- mod[wint.rows,]
SUmod <- mod[su.rows,]
FAmod <- mod[fa.rows,]

SPsf <- st_as_sf(SPmod, coords = c("X","Y"), crs = st_crs(dat)) |> as("Spatial")
SUsf <- st_as_sf(SUmod, coords = c("X","Y"), crs = st_crs(dat)) |> as("Spatial")
WIsf <- st_as_sf(WImod, coords = c("X","Y"), crs = st_crs(dat)) |> as("Spatial")
FAsf <- st_as_sf(FAmod, coords = c("X","Y"), crs = st_crs(dat)) |> as("Spatial")

r <- raster(crs = crs(dat), vals = 0, nrows = 100, ncols = 100, ext = extent(dat))

SPr <- terra::rasterize(SPsf, r, field = "Z")
SPr_smoothed <- terra::focal(SPr, w = matrix(1, nrow = 5, ncol = 5), fun = mean, na.rm = TRUE)
SPr_smoothed.df <- as.data.frame(SPr_smoothed, xy = TRUE, na.rm = TRUE)

png(filename = "final_set/plots/Spring_Predictions.png")
ggplot(SPr_smoothed.df) +
  geom_raster(aes(x = x, y = y, fill = layer)) +
  geom_sf(filter(dat, SEASON_g == "Spring" & PRES == 1), mapping = aes(), color = "red") + #this fixes the shape somehow??
  scale_fill_viridis_c() +
  theme_minimal() +
  labs(title = "Smoothed Predicted Probabilities of observations", subtitle = "Spring, points indicate  true presence", fill = "Probability") 
dev.off()

SUr <- terra::rasterize(SUsf, r, field = "Z")
SUr_smoothed <- terra::focal(SUr, w = matrix(1, nrow = 5, ncol = 5), fun = mean, na.rm = TRUE)
SUr_smoothed.df <- as.data.frame(SUr_smoothed, xy = TRUE, na.rm = TRUE)

png(filename = "final_set/plots/Summer_Predictions.png")
ggplot(SUr_smoothed.df) +
  geom_raster(aes(x = x, y = y, fill = layer)) +
  geom_sf(filter(dat, SEASON_g == "Summer" & PRES == 1), mapping = aes(), color = "red") + #this fixes the shape somehow??
  scale_fill_viridis_c() +
  theme_minimal() +
  labs(title = "Smoothed Predicted Probabilities of observations", subtitle = "Summer, points indicate  true presence", fill = "Probability") 
dev.off()


WIr <- terra::rasterize(WIsf, r, field = "Z")
WIr_smoothed <- terra::focal(WIr, w = matrix(1, nrow = 5, ncol = 5), fun = mean, na.rm = TRUE)
WIr_smoothed.df <- as.data.frame(WIr_smoothed, xy = TRUE, na.rm = TRUE)

png(filename = "final_set/plots/Sinter_Predictions.png")
ggplot(WIr_smoothed.df) +
  geom_raster(aes(x = x, y = y, fill = layer)) +
  geom_sf(filter(dat, SEASON_g == "WINTER" & PRES == 1), mapping = aes(), color = "red") + #this fixes the shape somehow??
  scale_fill_viridis_c() +
  theme_minimal() +
  labs(title = "Smoothed Predicted Probabilities of observations", subtitle = "Winter, points indicate  true presence", fill = "Probability") 
dev.off()


FAr <- terra::rasterize(FAsf, r, field = "Z")
FAr_smoothed <- terra::focal(FAr, w = matrix(1, nrow = 5, ncol = 5), fun = mean, na.rm = TRUE)
FAr_smoothed.df <- as.data.frame(FAr_smoothed, xy = TRUE, na.rm = TRUE)

png(filename = "final_set/plots/Fall_Predictions.png")
ggplot(FAr_smoothed.df) +
  geom_raster(aes(x = x, y = y, fill = layer)) +
  geom_sf(filter(dat, SEASON_g == "Fall" & PRES == 1), mapping = aes(), color = "red") + #this fixes the shape somehow??
  scale_fill_viridis_c() +
  theme_minimal() +
  labs(title = "Smoothed Predicted Probabilities of observations", subtitle = "Fall, points indicate  true presence", fill = "Probability") 
dev.off()


