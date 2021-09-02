##################################################################################
##################################################################################

# Reproducible code for "Emulation of greenhouse-gas sensitivities using variational autoencoders", 
# by Laura Cartwright, Andrew Zammit-Mangion, and Nicholas M. Deutscher.  
# Copyright (c) 2021 Laura Cartwright  
# Author: Laura Cartwright (lcartwri@uow.edu.au)

# This program is free software; you can redistribute it and/or modify it under the terms 
# of the GNU General Public License as published by the Free Software Foundation; either 
# version 2 of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
# See the GNU General Public License for more details.


##################################################################################
##################################################################################
##################################################################################
##################################################################################

### This script reads in FLEXPART output from a run. It builds the plume by 
### summing over the output and converting to ns/g. 

### You can supply this function with multiple simulation run dates/times,
### and it will produce a data frame where each column is one plume.

### INPUTS: sim_time_list: a text file with simulation times (one per line).
### They should be of the same format as the prefix naming the FP outputs (YYMMDDHH)
### locations: a text file where the first row gives the name of the location/
### measurement tower, and the second and third row are x and y coordinate resp.
### separate values by spaces.



### The filtered set will be saved as a list with info on the measurement site 
### and time point.

### Elements of output are named "FP_plumes", "FP_Labels", and "FP_time_stamps".

### Currently set up for Europe. 
### You'll need to change all the instances of "EU" to "UK", "Aus", or "Canada"
### to do other regions. 

##################################################################################
##################################################################################

library(RNetCDF)
library(dplyr)

# Set your working directory to be the folder where the FLEXPART simulations are

source("../src/estimate-dep-angle.R") # Might need to adjust these paths if you change the folder structure
source("../src/cart-to-polar.R")
source("../src/adjust-tower-locations.R")

## If you remember, change the name down the bottom of the script each time as well,
## so the data saves with a relevant name

output_name <- "FP-sims-EU.rdata"

sim_time_list <- "FLEXPART-sims/surface-EU/surface-EUnames"

time_stamps <- as.character(read.table(paste0(sim_time_list,".txt"), sep = "")$V1)
time_stamps <- time_stamps[-5001]

Plumes <- NULL
x <- c()
y <- c()
Time <- c()

ni <- length(time_stamps)

# Change this to mclapply when you have a lot of plumes maybe
for (i in 1:ni) {

    ds <- open.nc(con = time_stamps[i])
    FP_output <- read.nc(ncfile = ds)
    
    Lon <- FP_output$longitude
    Lat <- FP_output$latitude
    num_time_points <- length(FP_output$time)
    
    # Build empty matrix to put plume into before summing to get footprint
    vals <- matrix(nrow = num_time_points, ncol = length(Lat) * length(Lon))
    
    for (k in 1:num_time_points) {
      vals[k, ] <- as.vector(FP_output$spec001_mr[, , k])
    }
    s_orig_units <- colSums(vals) # units s m^3 kg^(-1)
    
    ## Transform
    
    # For Eu:
    #dy <- abs(FP_output$latitude[2] - FP_output$latitude[1]) * 111194.93 ## convert to m
    #dx <- abs(FP_output$longitude[2] - FP_output$longitude[1]) * 53948.58 ## convert to m
    
    # For Aus:
    #dy <- abs(FP_output$latitude[2] - FP_output$latitude[1]) * 111194.90 ## convert to m
    #dx <- abs(FP_output$longitude[2] - FP_output$longitude[1]) * 100756.90 ## convert to m
    
    # For Canada:
    #dy <- abs(FP_output$latitude[2] - FP_output$latitude[1]) * 111194.93 ## convert to m
    #dx <- abs(FP_output$longitude[2] - FP_output$longitude[1]) * 78659.12 ## convert to m
    
    # For UK:
    dy <- abs(FP_output$latitude[2] - FP_output$latitude[1]) * 111194.93 ## convert to m
    dx <- abs(FP_output$longitude[2] - FP_output$longitude[1]) * 70012.89 ## convert to m
    
    # Source: Haversine formula (see Rscript lat-lon-to-metres.R)
    
    vol <- dx * dy * 100 # m^3
    s_sec_kg <- s_orig_units / vol # seconds per kilogram
    s_sec_g <- s_sec_kg / 1000 # seconds per gram
    s_sec_g_ppb <- s_sec_g * 10^9 # nanoseconds per gram
    s_sec_g_ppbv <- s_sec_g_ppb * (28.9644 / 16.0425) # nanoseconds per gram
    
    Plumes <- cbind(Plumes, s_sec_g_ppbv)
    x <- cbind(x, FP_output$RELLNG1)
    y <- cbind(y, FP_output$RELLAT1)
    Time <- cbind(Time, time_stamps[i])
    
    print(i)
}







# Create gridded domain (will be needed for angle estimation)

grid_locations <- expand.grid(Lon, Lat)
names(grid_locations) <- c("x", "y")

save(grid_locations, file = "FLEXPART-sims/surface-EU/EU.rdata")

## Adjust tower locations

tower_locations_adj <- adjust_locations(locs_grid = grid_locations, 
                                        tower_locs = rbind(x, y))

## Now estimate departure angles of all plumes

Labels <- 1:ni

# Add x and y coords of tower

x_coord <- tower_locations_adj[1, ]
y_coord <- tower_locations_adj[2, ]

Dep_angle <- c()
for (i in 1:ncol(Plumes)) {
  Dep_angle[i] <- estimate_dep_angle(plume = Plumes[, i],
                                     tower_location = tower_locations_adj[, as.numeric(Labels[i])],
                                     locs_grid = grid_locations)
  print(i)
  print(Dep_angle[i])
}

FP_sims_EU <- list(Plumes = Plumes,
                   Labels = Labels,
                   time_stamps = Time,
                   dep_angle = Dep_angle,
                   x = x_coord,
                   y = y_coord,
                   x_orig = x,
                   y_orig = y)


save(FP_sims_EU, file = output_name)

# save


