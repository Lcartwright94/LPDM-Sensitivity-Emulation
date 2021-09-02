##################################################################################
##################################################################################

### This script reads in the NAME output from Anita. It then puts the plumes
### all together with one column per plume. The order will be all MHD plumes, 
### all RGL plumes, all TAC plumes, all TTA plumes (so time will cycle 4 times).

### Next, any plume with a substantial amount of tail going off the grid is removed.

### The filtered set will be saved as a list with info on the measurement tower 
### and time point.

### Elements of output are named "NAME_plumes", "NAME_Labels", and "NAME_time_stamps".

##################################################################################
##################################################################################

library(dplyr)

source("../src/filter-plumes.R")
source("../src/estimate-dep-angle.R")
source("../src/adjust-tower-locations.R")
source("../src/cart-to-polar.R")

##################################################################################

MHD_sims <- cbind(read.table("NAME-sims/MHD_model_012014.txt", sep = "", skip = 15),
                  read.table("NAME-sims/MHD_model_022014.txt", sep = "", skip = 15),
                  read.table("NAME-sims/MHD_model_032014.txt", sep = "", skip = 15),
                  read.table("NAME-sims/MHD_model_042014.txt", sep = "", skip = 15))

RGL_sims <- cbind(read.table("NAME-sims/RGL_model_012014.txt", sep = "", skip = 15),
                  read.table("NAME-sims/RGL_model_022014.txt", sep = "", skip = 15),
                  read.table("NAME-sims/RGL_model_032014.txt", sep = "", skip = 15),
                  read.table("NAME-sims/RGL_model_042014.txt", sep = "", skip = 15))

TAC_sims <- cbind(read.table("NAME-sims/TAC_model_012014.txt", sep = "", skip = 15),
                  read.table("NAME-sims/TAC_model_022014.txt", sep = "", skip = 15),
                  read.table("NAME-sims/TAC_model_032014.txt", sep = "", skip = 15),
                  read.table("NAME-sims/TAC_model_042014.txt", sep = "", skip = 15))

TTA_sims <- cbind(read.table("NAME-sims/TTA_model_012014.txt", sep = "", skip = 15),
                  read.table("NAME-sims/TTA_model_022014.txt", sep = "", skip = 15),
                  read.table("NAME-sims/TTA_model_032014.txt", sep = "", skip = 15),
                  read.table("NAME-sims/TTA_model_042014.txt", sep = "", skip = 15))

All_sims <- cbind(MHD_sims, RGL_sims, TAC_sims, TTA_sims)

ndim <- ncol(MHD_sims)
rm(MHD_sims)
rm(RGL_sims)
rm(TAC_sims)
rm(TTA_sims)

Labels <- c(rep("MHD", ndim), 
            rep("RGL", ndim),
            rep("TAC", ndim),
            rep("TTA", ndim))

mintime <- as.POSIXct(paste0(2014,"/",01,"/",01," ",00,":",00), tz = "UTC")
maxtime <- as.POSIXct(paste0(2014,"/",04,"/",30," ",22,":",00), tz = "UTC")

## Create an array of time points (every five minutes) from min time to max time
two_hour_cuts <- as.POSIXct(seq(from = mintime, to = maxtime, by = 7200))
head(two_hour_cuts)
tail(two_hour_cuts)
Time <- rep(two_hour_cuts, 4)

################################################

## Create grid

dx <- 0.352
x_min <- -14.124
x_max <- x_min + 127 * dx

dy <- 0.234
y_min <- 36.469
y_max <- y_min + 127 * dy

x_locs <- seq(x_min, x_max, dx)
y_locs <- seq(y_min, y_max, dy)

# Create gridded domain (will be needed for angle estimation)

Locs <- expand.grid(x_locs, y_locs)
Locs <- arrange(Locs, Var1)
names(Locs) <- c("x", "y")

## Add locations of measurement towers

MHD_loc <- c(-9.9, 53.33)
RGL_loc <- c(-2.54, 52.00)
TAC_loc <- c(1.14, 52.52)
TTA_loc <- c(-2.99, 56.56)
locations <- data.frame(MHD_loc, RGL_loc, TAC_loc, TTA_loc)


## Find which coordinates in the full grid are on the border (find indexes)

grid_border <- data.frame(c(rep(x_min, length(y_locs)), rep(x_max, length(y_locs)), x_locs, x_locs),
                          c(y_locs, y_locs, rep(y_min, length(x_locs)), rep(y_max, length(x_locs))))
names(grid_border) <- c("x", "y")


# Find which rows correspond to x and y vals on the border (this is what ids represents)

ids <- c()
for (i in 1:nrow(grid_border)) {
  ids[i] <- which(Locs$x == grid_border$x[i] & Locs$y == grid_border$y[i])
}


##############################################

## Filter out plumes which go off the grid

Filtered <- filter_plumes(plumes = All_sims, border_ids = ids)

NAME_plumes <- Filtered$plumes_filtered

rem_ids <- Filtered$rem_ids
NAME_Labels <- Labels[-rem_ids]
NAME_Labels <- as.factor(NAME_Labels) # So we can index them by number as well

# Add x and y coords of tower
x_coord <- c()
y_coord <- c()
for (i in 1:length(NAME_Labels)) {
  x_coord[i] <- locations[1, as.numeric(NAME_Labels[i])]
  y_coord[i] <- locations[2, as.numeric(NAME_Labels[i])]
}

# Create time stamps
NAME_time_stamps <- Time[-rem_ids]


## Adjust tower locations

locations_adj <- adjust_locations(locs_grid = Locs, tower_locs = locations)

## Now estimate departure angles of all plumes

Dep_angle <- c()
for (i in 1:ncol(NAME_plumes)) {
  Dep_angle[i] <- estimate_dep_angle(plume = NAME_plumes[, i],
                                     tower_location = locations_adj[, as.numeric(NAME_Labels[i])],
                                     locs_grid = Locs)
  print(i)
  print(Dep_angle[i])
}





NAME_UK_2014 <- list(Plumes = NAME_plumes,
                     Labels = NAME_Labels,
                     time_stamps = NAME_time_stamps,
                     dep_angle = Dep_angle,
                     x = x_coord,
                     y = y_coord)

save(NAME_UK_2014, file = "NAME-sims/NAME-UK-2014.rdata")


