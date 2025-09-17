#In class activity 7


#load packages
library(googledrive)
library(sf)
library(terra)
library(tidyterra)
library(tidyverse)

#source functions
source("scripts/utilities/download_utils.R")

file_list <- drive_ls(drive_get(as_id("https://drive.google.com/drive/u/1/folders/1PwfUX2hnJlbnqBe3qvl33tFBImtNFTuR")))

file_list %>% 
  dplyr::select(id, name) %>%
  purrr::pmap(function(id, name) {
    gdrive_folder_download(list(id = id, name = name),
                           dstfldr = "inclass07")
  })


#read in the vector
cejst_shp <- read_sf("data/original/inclass07/cejst.shp")
class(cejst_shp) #sf, tbl_df, tbl, data.frame

str(cejst_shp)


glimpse(cejst_shp)

#make sure the geometry is valid
all(st_is_valid(cejst_shp)) #TRUE

#check out the shape file as an object
plot(st_geometry(cejst_shp))


### NOW THE RASTER

fire_prob <- rast("data/original/inclass07/wildfire.tif")
plot(fire_prob)


### Check out the extent of the spatial objects. Do this by looking at
# the BOUNDING BOX
st_bbox(cejst_shp)

#this shows the coordinates for a rectangle that encompasses all of the vertices of the object
#using st_bbox returns an object of class bbox, a special kind of object.

#convert the bbox to a simple feature collection (sfc)

all_bbox <- st_bbox(cejst_shp) %>% 
  st_as_sfc()
id_bbox <- cejst_shp %>% 
  filter(., SF == "Idaho") %>% 
  st_bbox() %>% 
  st_as_sfc()

plot(all_bbox)
plot(id_bbox, add=TRUE, border ="red")

#there is a built-in geom_ in ggplot2 that will allow us to make maps with all of the flexibility of ggplot.
ggplot() +
  geom_sf(data = all_bbox, color = "yellow", fill = "darkorchid4") +
  geom_sf(data= id_bbox, fill = "orangered") +
  theme_bw()

#the terra package uses some different conventions and tidyterra 
#only provides functionality for some operations that are more complex

# the function for getting the extent from a raster using terra is ext()
ext(fire_prob)
ext(fire_prob) %>% class()

#it has a new class, a SpatExtent

plot(ext(fire_prob), border = "red")
plot(fire_prob, add=TRUE)

#The tidyterra package allows us to use filter as a way to subset rasters without using indexing. 
#We can use that here to find all of the cells whose wildfire hazard potential is greater than 30000
#notably, the extent of a SpatRaster does not change to match the subset data.

fire_subset <- fire_prob %>% 
  filter(WHP_ID > 30000)

plot(ext(fire_subset), border = "red")
plot(fire_subset, add=TRUE)

#you may want to manually change the extent of your spatial objects while keeping everything else the same

orig_bbox <- st_bbox(cejst_shp)

new_bbox <- st_bbox(c(orig_bbox["xmin"] + 1, orig_bbox["xmax"] - 1,  orig_bbox["ymax"] - 1, 
                      orig_bbox["ymin"] + 1), crs = st_crs(orig_bbox)) %>% st_as_sfc()

ggplot() +
  geom_sf(data = st_as_sfc(orig_bbox), color = "yellow", fill = "darkorchid4") +
  geom_sf(data= new_bbox, fill = "orangered") +
  theme_bw()

# now do the same for the raster bbox!
#The process is similar for rasters with terra, but we need to get the SpatExtent object into a more useable format.
#The other thing to notice is that our raster is in a projection that uses meters as its measurement unit 
#(you can tell by the differene in the orders of magnitude in the values). 
# this means we need to think a bit differently about how to shift the box.

#saving the raster extent/bounding box as a vector object
orig_ext <- as.vector(ext(fire_prob))

#shrink values
new_ext <- ext(as.numeric(c(
  orig_ext["xmin"] + 100000,
  orig_ext["xmax"] - 100000,
  orig_ext["ymin"] + 100000,
  orig_ext["ymax"] - 100000
)))

plot(orig_ext)
plot(new_ext, add=TRUE, border = "red")
#WHY DID THE NEW EXTENT NOT WORK**********************************************

#check resolution of the raster data
res(fire_prob)

#In some cases you may want to sharpen or coarsen the resolution. 
#You can use aggregate or disagg in terra to do this. The key bit is the fact argument. 
#Which tells you the factor by which we create that surface.

coarser_fire <- aggregate(fire_prob, fact = 5)
finer_fire <- disagg(fire_prob, fact = 5)

res(coarser_fire)
ext(coarser_fire)

res(finer_fire)
ext(finer_fire)

plot(coarser_fire)
plot(finer_fire)

#the vector and raster are different shapes, meaning they are probably in different projections
#get the crs for each

st_crs(cejst_shp)
crs(fire_prob)

fire_prob_new <- fire_prob
crs(fire_prob_new) <- "epsg:9001"
plot(fire_prob)
plot(fire_prob_new)

#In sf, we can use st_transform to transform the CRS of a spatial layer.
#In general, it is better to re-project vector data to match raster data, 
#as the vector form is more flexible (because vectors can stretch, but raster cells can’t).

cejst_reproject <- cejst_shp %>% 
  st_transform(., st_crs(fire_prob_new))
st_crs(cejst_reproject)

st_bbox(cejst_reproject)
st_bbox(cejst_shp)
