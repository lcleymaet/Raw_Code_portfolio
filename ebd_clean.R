
#Purpose: Clean e-bird dataset to remove unnecessary cols and missing data points
library(tidyverse)
library(dplyr)
library(ggplot2)
library(readr)
library(lubridate)
library(sf)
library(terra)

ebd <- read_tsv("ebd_sampling_NV_Feb21_bundle/ebd_sampling_relFeb-2021-US-NV.txt")
roads <- read_sf("tl_2019_32_prisecroads/tl_2019_32_prisecroads.shp")

#Select columns and fix NAs
ebd_clean <- ebd %>% filter(STATE == "Nevada") %>% select(-c(country, `COUNTRY CODE`, STATE, `STATE CODE`, 
                                                             `ATLAS BLOCK`, `LOCALITY ID`, `LOCALITY TYPE`, 
                                                             `PROTOCOL CODE`,
                                                             `NUMBER OBSERVERS`, `GROUP IDENTIFIER`, `TRIP COMMENTS`,
                                                             `IBA CODE`, `BCR CODE`, `USFWS CODE`, `COUNTY CODE`,
                                                             `EFFORT AREA HA`, LOCALITY, `PROJECT CODE`)) %>%
  filter(`ALL SPECIES REPORTED` == 1) %>%
  filter(`PROTOCOL TYPE` %in% c("Traveling", "Stationary")) %>%
  mutate(`EFFORT DISTANCE KM` = replace_na(`EFFORT DISTANCE KM`, 0)) %>%
  select(-`PROTOCOL TYPE`) %>%
  filter(!is.na(`DURATION MINUTES`)) 

#add week number to data
#Week of Jan 1 if 4 days or longer is week 1, if shorter is assigned to week 52 of previous year
ebd_clean$WEEK <- as.factor(strftime(ebd_clean$`OBSERVATION DATE`, format = "%V"))

#Adding years as categorical to aid in visualizations
ebd_clean$YEAR <- as.factor(format(ebd_clean$`OBSERVATION DATE`, '%Y'))

#summary(ebd_clean)

#saving projection
proj <- st_crs(roads)
#converting to sf object with projection matching TIGER data
ebd_sf <- st_as_sf(ebd_clean, coords = c("LONGITUDE", "LATITUDE"), crs = proj)

#Adding elevation to sf object
library(elevatr)

ebd_sf_elev <- get_elev_point(ebd_sf, src = "epqs",prj = proj)

st_write(ebd_sf_elev, "ebd_clean_elev/ebd_clean_elev.shp")


