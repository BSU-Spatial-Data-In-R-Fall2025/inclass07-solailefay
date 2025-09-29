# script for in class activity 9? 
# Building Attributes for our Smoke Dataset

#load packages
library(googledrive)
library(terra)
library(sf)
library(tidyterra)
library(tidyverse)

#get the data
source("scripts/utilities/download_utils.R")
file_list <- drive_ls(drive_get(as_id("https://drive.google.com/drive/u/1/folders/1PwfUX2hnJlbnqBe3qvl33tFBImtNFTuR")))

#download the individual data files from the list into the data folder of the repository
#Use the function gdrive_folder_download from the utilities object downloaded above to map onto each item in the list and put it into a data folder
file_list %>% 
  dplyr::select(id, name) %>%
  purrr::pmap(function(id, name) {
    gdrive_folder_download(list(id = id, name = name),
                           dstfldr = "inclass09")
  })


### now load objects from the data folder into R objects
cejst_shp <- read_sf("data/original/inclass09/cejst.shp") #boundaries from the Climate and Environmental Justice Screening Tool. 
#Unsure what the boundaries are for. counties?
plot(cejst_shpt[[1]])
fire_prob <- rast("data/original/inclass09/wildfire.tif") #raster of fire probability across the PNW
pa_locations_wgs <- read_sf("data/original/inclass09/pa.shp") #sensor locations??

#check out the crs of our spatial data
st_crs(cejst_shp)
st_crs(pa_locations_wgs)
st_crs(fire_prob)

#we’ve got some slightly different projections. 
#Let’s fix that before we get too far down the road. 
#We’ll reproject the shapefiles as that’s the safest way to get everything lined up

#transforming the crs of the two vectors to that of the single raster
cejst_reproj <- cejst_shp %>% 
  st_transform(., crs = crs(fire_prob))

pa_reproj <- pa_locations_wgs %>% 
  st_transform(., crs = crs(fire_prob))


#now load last dataset: tabular data of monthly sensor readings. not spatial - that's where pa_reproj comes in.
pa_data <- read_csv("data/original/inclass09/paReadings.csv")

#glimpse our data
glimpse(pa_data)
glimpse(pa_reproj)
glimpse(cejst_reproj)
glimpse(fire_prob)

unique(pa_data$id)
unique(pa_reproj$snsr_nd)
#lots more sensor locations here than we have readings for.


### combine sensor locations with sensor data using left_join
# TIP: When working with spatial data in R it is important to remember 2 things: 
#1) geometries are sticky (so they’ll stick around in any join where the spatial data is the first argument) 
#and 2) we can join tabular data to spatial data, but not vice versa 
#(so to join spatial data to a tabular dataset, you’ll need st_drop_geometry first)

# our tabular dataset (pa_data) is in long format - 
# each sensor has multiple rows corresponding to the date that the reading is from. 
# For spatial data, it’s typically better to keep your data in wide format to avoid repeating geometries. 
# Let’s summarize the data into annual values and then pivot_ to make the data wide.

pa_data_wide <- pa_data %>% 
  mutate(year = year(time_stamp)) %>%      # we calculated the year by exploiting the year function.
  select(id, year, pm2.5_atm) %>%       #we selected the columns we were interested in (pm2.5_atm) along with the year and id columns.
  filter(year > 2023) %>%      #We filtered to get values after 2023 as those are datapoints after the creation of the wildfire hazard potential data.
  group_by(id, year) %>%     #We then used group_by to get unique combinations of id and year
  summarise(across(where(is.numeric),      # in order to summarize the data into several statistics for the numeric columns (pm2.5)
                   list(mean = ~mean(.x, na.rm = TRUE),    #make a column that is the annual mean pm2.5
                        median = ~median(.x, na.rm = TRUE),    #make a column that is the annual median pm2.5
                        max = ~max(.x, na.rm = TRUE)),     #make a column that is the annual max pm2.5
                   .names = "{.col}_{.fn}"),     # name these columns the numeric column name _ the function. so, pm2.5_max, etc.
            .groups = "drop") %>% 
  pivot_wider(   #make wide format
    names_from = year,      #column for each year
    values_from = c(pm2.5_atm_mean, pm2.5_atm_median, pm2.5_atm_max),     #pm2.5 values for the values in the year columns
    names_glue = "{.value}_{year}"    #add the function to the year column names to separate max/mean, etc.
  )


### Now that we’ve got the data in a wide format, we can join it to our sensor locations.
pa_data_lftjoin <- pa_reproj %>%    # keep ALL sensor names from the spatial df
  left_join(., pa_data_wide, by = join_by(snsr_nd == id))     # add any corresponding sensor data to these locations, joined by their sensor ID


pa_data_injoin <- pa_reproj %>% 
  inner_join(., pa_data_wide, by = join_by(snsr_nd == id))

############################################################################################# pickup here


ggplot() +
  geom_sf(pa_data_injoin, 
          mapping = aes(color = pm2.5_atm_max_2024)) +
  scale_color_viridis_b()

life_exp <- cejst_reproj %>% 
  select(LIF_PFS)

censor_life_exp <- st_join(x = pa_data_injoin, 
                           y = life_exp,
                           join = st_within,
                           left = TRUE)
plot(life_exp)
plot(pa_data_injoin[1])

ggplot() +
  geom_sf(censor_life_exp, 
          mapping = aes(color = pm2.5_atm_max_2024, size=LIF_PFS)) +
  scale_color_viridis_b()


fire_extract_mean <- terra::zonal(fire_prob, 
                                  vect(cejst_reproj), 
                                  fun="mean", 
                                  na.rm = TRUE, 
                                  as.polygons = TRUE)

fire_sf <- st_as_sf(fire_extract_mean)

sensor_join <- st_join(x = censor_life_exp, 
                       y = fire_sf,
                       join = st_within,
                       left = TRUE)

fire_sf <- st_as_sf(fire_extract_mean)

sensor_join <- st_join(x = censor_life_exp, 
                       y = fire_sf,
                       join = st_within,
                       left = TRUE)

ggplot() +
  geom_sf(sensor_join, 
          mapping = aes(color = pm2.5_atm_max_2024, size=WHP_ID)) +
  scale_color_viridis_b()


state_boundaries <- tigris::states(progress_bar = FALSE)

study_area <- state_boundaries %>% 
  filter(., STUSPS %in% c("ID", "OR", "WA")) %>% 
  st_transform(., crs(fire_prob))

county_boundaries <- tigris::counties(state = c("ID", "OR", "WA"),
                                      progress_bar = FALSE) %>% 
  st_transform(., crs(fire_prob))


ggplot() +
  geom_spatraster(fire_prob, 
                  mapping = aes(fill = WHP_ID)) +
  geom_sf(data = study_area, 
          fill = NA, 
          colour = "blue") +
  geom_sf(data = county_boundaries,
          fill = NA,
          colour = "lightgray",
          lwd = 0.7) +
  geom_sf(censor_life_exp, 
          mapping = aes(color = pm2.5_atm_max_2024, size=LIF_PFS)) +
  scale_fill_viridis_c(option = "inferno", na.value = "transparent") +
  scale_color_viridis_b() +
  theme_bw()




#EXERCISE 
#Summarize the points and the other variables at the county and state level 
#(i.e., combine all of the points in a county/state and recalculate the pm2.5 values, run zonal on the counties etc)


#pa_data_injoin is the sensor data already combined with the locations. so I will use that and combine it to state and county data

#states
sensor_states <- st_join(x = pa_data_injoin, 
                           y = study_area,
                           join = st_within,
                           left = TRUE)

#counties
sensor_full <- st_join(x =sensor_states, 
                         y = county_boundaries,
                         join = st_within,
                         left = TRUE)


# now that i have the county and state info in the sensor dataframe, I will group by county and summarize the mean 2024 pm value across all seensors in that county

sensor_full <- sensor_full %>%
  group_by(NAMELSAD) %>% #group by county
  mutate(meanpm_county = mean(pm2.5_atm_mean_2024)) %>%
  ungroup()

fire_extract_counties <- terra::zonal(fire_prob, 
                                  vect(county_boundaries), 
                                  fun="mean", 
                                  na.rm = TRUE, 
                                  as.polygons = TRUE)


firecounty_sf <- st_as_sf(fire_extract_counties)

df <- st_join(x = censor_life_exp, 
                       y = firecounty_sf,
                       join = st_within,
                       left = TRUE)



ggplot() +
  geom_spatraster(fire_prob, 
                  mapping = aes(fill = WHP_ID)) +
  geom_sf(data = study_area, 
          fill = NA, 
          colour = "blue") +
  geom_sf(data = county_boundaries,
          fill = NA,
          colour = "lightgray",
          lwd = 0.7) +
  geom_sf(censor_life_exp, 
          mapping = aes(color = pm2.5_atm_max_2024, size=LIF_PFS)) +
  scale_fill_viridis_c(option = "inferno", na.value = "transparent") +
  scale_color_viridis_b() +
  theme_bw()








#WHAT







