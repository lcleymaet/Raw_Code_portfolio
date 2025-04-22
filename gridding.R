library(sf)
library(terra)
library(ggplot2)
library(tidyterra)
library(raster)
library(tidyr)
library(dplyr)

#import dataset
ebd1 <- read_sf('distances/ebd_data_distances.shp') %>% 
  select(-LASTEDD, -elv_nts, -ALLSPER) 

seasons <- list(Winter = c(1:11,51:53), Spring = 12:24, Summer = 25:37, Fall = 38:50)
ebd1 <- ebd1 %>% mutate(SEASON = "MISSING")
#group weeks into seasons
for(i in 1:4){
  season = names(seasons)[i]
  if(i == 1){
    ebd2 <- filter(ebd1, WEEK %in% seasons[[i]]) %>% mutate(SEASON = season)
  }else{
    temp <- filter(ebd1, WEEK %in% seasons[[i]]) %>% mutate(SEASON = season)
    ebd2 <- rbind(ebd2, temp)
  }
}

#create grid over nevada
nv <- vect("NDOT_NV_BDRY/Nevada_State_Boundary.shp")
grid <- rast(nv, nrows = 50, ncols = 50)

crs(grid) <- crs(nv) #match projections
grid <- as.polygons(grid) #convert rastor to polygons
grid <- terra::intersect(nv, grid) #crop grid to nevada boundary
#remove extra columns and number each square individually
grid <- st_as_sf(grid) %>% select(ID, geometry) %>% mutate(ID = seq(1,nrow(grid)))
proj = st_crs(grid)

ebd2 <- st_transform(ebd2, proj) #match projections

#classify each point as inside one polygon
ebd2 <- st_join(ebd2, grid)
#count points per polygon per week
ebd2 <- ebd2 %>% as.data.frame %>% group_by(ID, SEASON) %>% add_count() %>% 
  mutate(ave_duration = mean(DURATIM)) %>% #adding averages for each ID,WEEK pair
  mutate(ave_effort = mean(EFFORDK)) %>%
  mutate(ave_elev = mean(elevatn)) %>% 
  mutate(ave_rd_dist = mean(dstnc_rd)) %>%
  mutate(ave_water_dist = mean(dstnc_w)) %>%
  mutate(ave_rail_dist = mean(dstnc_rl)) %>%
  mutate(ave_d_UAC20 = mean(d_UAC20)) %>%
  ungroup()

#add weeks for each polygon in grid
grid_len <- nrow(grid)
grid <- mutate(grid, SEASON = "WINTER")
grid1 <- grid

for(i in 2:4){
  temp <- grid1 %>% mutate(SEASON = names(seasons)[i])
  grid <- rbind(grid, temp)
}
#add new index number for each pair of ID and week
grid <- mutate(grid, INDEX = seq(1,nrow(grid)))
#create indexing matrix to apply to dataset for faster query
ind_matrix <- st_drop_geometry(grid) |> as.data.frame()

#write out ebd data with geometries and seasons for presence/absence regression
st_write(ebd2, "final_set/ebd_seasons.shp")

#add new index to dataset
##Does not need geometry anymore, drop for better speed as tibble not sf
ebd2 <- mutate(ebd2, INDEX = 0) |> st_drop_geometry() |> as.data.frame()

#Add correct index
ebd3 <- data.frame(matrix(nrow = 0, ncol = ncol(ebd2)))
colnames(ebd3) <- colnames(ebd2)

for(i in 1:nrow(ind_matrix)){
  gTemp <- ind_matrix %>% filter(INDEX == i)
  gID <- gTemp %>% pull(ID)
  gWK <- gTemp %>% pull(SEASON)
  ebdTemp <- ebd2 %>% filter(SEASON == gWK & ID == gID) 
  if(nrow(ebdTemp) == 0){
    next
  }else{
    ebdTemp <- mutate(ebdTemp, INDEX = i)
    ebd3 <- rbind(ebd3, ebdTemp)
  }
}

#Add attributes to grids based on INDEX column
grid_join <- left_join(grid, ebd3, by = c("INDEX" = "INDEX"), suffix = c(".grid",".dat"))
#Remove extra columns and geometry
grid_join <- grid_join %>% 
  select(-SAMPLEI, -DURATIM, -EFFORDK, -elevatn, -dstnc_rd, -dstnc_w, -dstnc_rl, -d_UAC20, -ID.dat, -geometry.dat, -OBSERVD, -OBSERVI ) 
#Replace NA for a grid with 0 for the count
grid_join <- grid_join %>% replace_na(list(n = 0)) 
#obtain centroids of polygons and replace the polygon geometry with new points geometry
grid_centroids <- st_centroid(st_geometry(grid_join))
st_geometry(grid_join) <- st_geometry(grid_centroids)
#remove duplicated rows
grid_join <- distinct(grid_join, INDEX, .keep_all = TRUE)

grid_join <- grid_join %>% mutate(PRES = ifelse(n==0,0,1))

#write grid sf to file
st_write(grid_join, "final_set/ebd_gridded_seasons.shp", append = FALSE)

#plot(grid)

