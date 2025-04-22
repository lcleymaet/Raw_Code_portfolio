library(sf)
library(tidyterra)
library(ggplot2)
library(purrr)
library(fs)
library(rmapshaper)

temp <- read_sf("ebd_clean_elev/ebd_clean_elev.shp")
bound <- read_sf("NDOT_NV_BDRY/Nevada_State_Boundary.shp")
proj <- st_crs(temp)
bound <- st_transform(bound, proj)

#check all data inside nevada boundary
png("final_set/plots/datapoints.png")
ggplot()+geom_sf(data = bound, aes(fill = NA), fill = NA)+geom_sf(temp, mapping = aes()) +ggtitle("Locations of observations")
dev.off()

#aggregate water data to one sf object from many shapefiles
water <- fs::dir_ls('nevada_area_water', regexp = ".*\\.shp$") %>% purrr::map(sf::read_sf) %>% dplyr::bind_rows()
water <- st_transform(water, proj) #match crs

#plot water bodies of Nevada
png("final_set/plots/water_bodies.png")
ggplot() + geom_sf(data = bound, aes(fill = NA)) + geom_sf(data = water, aes(fill = NA), fill = "blue", color = "darkblue") +
  ggtitle("Water of Nevada")#+
 # geom_sf(temp, mapping = aes(color = WEEK), shape = 1) + facet_wrap(~ WEEK)
dev.off()

#st_write(water, "aggregated_files/area_water.shp") #write out aggregated water

faces <- fs::dir_ls('nevada_faces', regexp = ".\\.shp$") %>% purrr::map(sf::read_sf) %>% dplyr::bind_rows()
faces <- st_transform(faces, proj)

ggplot() + geom_sf(data = bound, aes(fill = NA)) + geom_sf(data = faces, aes(fill = NA), color = "red", fill = "darkred")

#st_write(faces, "aggregated_files/faces/faces.shp")

roads <- read_sf("tl_2019_32_prisecroads/tl_2019_32_prisecroads.shp") #contains only highways
roads <- st_transform(roads, proj)

png("final_set/plots/roads.png")
ggplot() + geom_sf(data = bound, aes(fill = NA)) + geom_sf(data = roads, aes(fill = NA), color = "green")+
  ggtitle("Roads of Nevada")
dev.off()

#st_write(roads, "aggregated_files/roads/highways.shp")

rails <- read_sf("tl_2024_us_rails/tl_2024_us_rails.shp")
rails <- st_transform(rails, proj)
rails <- ms_clip(rails, bound)
rails <- st_transform(rails, proj)

png("final_set/plots/rails.png")
ggplot() + geom_sf(data = bound, aes(fill = NA)) + geom_sf(data = rails, aes(fill = NA), color = "white")+
  ggtitle("Railroads of Nevada")
dev.off()
