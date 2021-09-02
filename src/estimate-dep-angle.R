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

### This function estimates the departure angle of a plume. It works using the 
### normalised values of the sensitivity.

### Arguments: locs_grid = the full gridded spatial domain
### plume = the plume of which to estimate the departure angle
### tower_location = the coordinates of the measurement site where the plume 
###   originates.
### max_dist = the max distance outward to search for plume "signal" which 
###   becomes influential in the calculation of the departure angle

### The function returns a single value which is the estimated departure angle 
### of the plume.

##################################################################################
##################################################################################

estimate_dep_angle <- function(plume, tower_location, locs_grid, max_dist = 2) {
  
  # find departure angle 
  
  plume_normalised <- (plume - min(plume)) / (max(plume) - min(plume))
  plume_normalised[plume_normalised <= 0.01] <- 0
  
  grid <- cbind(locs_grid, plume_normalised)
  
  ### zero location so angle doesn't mess up
  grid$x <- grid$x - tower_location[1]
  grid$y <- grid$y - tower_location[2]
  
  grid$dist <- as.vector(fields::rdist(grid[, 1:2], data.frame(0, 0)))

  sub_grid <- filter(grid, dist <= max_dist)
  sub_grid <- filter(sub_grid, plume_normalised > 0.01)

  annulus <- max_dist - 0.5 * max_dist # compute lower bound of annulus to search for first signal

  if (length(which(sub_grid$dist > annulus)) == 0) { 
  	est_angle_dep <- 0
  } else {
	  sub_grid <- cart_to_polar(sub_grid)
	  names(sub_grid)[3:4] <- c("sensitivity", "dist")
	  
	  # remove origin
	  
	  id <- which(sub_grid$r == 0 & sub_grid$theta == 0)
	  if (length(id) > 0){
	    sub_grid <- sub_grid[-id, ]
	  }
	  
	  # Find likely direction of tail
	  
	  largest_signal <- max(sub_grid$sensitivity[sub_grid$dist >= annulus]) # Find largest signal in annulus
	  id <- which(sub_grid$sensitivity == largest_signal) # Find the row number of the largest signal in annulus
	  
	  ## We search for signal within 45 degrees each side of the largest signal point in annulus
	  
	  # Build a "quadrant" for likely tail direction 
	  
	  tail_angle <- sub_grid$theta[id]
	  
	  angle_region <- c(tail_angle - 45, tail_angle + 45)
	  sub_grid$theta2 <- sub_grid$theta
	  if (angle_region[2] > 360){
	    angle_region[2] <- angle_region[2] - 360
	    sub_grid <- filter(sub_grid, (theta >= angle_region[1] & theta <= 360) | 
		                 (theta <= angle_region[2] & theta >= 0))
	  } else if (angle_region[1] >= -90 & 
		     angle_region[1] < 0 & 
		     angle_region[2] <= 180 & 
		     angle_region[2] >= 0) {
	    if (length(sub_grid$theta2[sub_grid$theta2 > 180]) > 0) {
	      sub_grid$theta2[sub_grid$theta2 > 180] <- sub_grid$theta2[sub_grid$theta2 > 180] - 360
	    }
	    sub_grid <- filter(sub_grid, (theta2 >= angle_region[1] & theta2 <= 0) | 
		                 (theta2 <= angle_region[2] & theta2 >= 0))
	  } else {
	    if (angle_region[1] < 0){
	      angle_region[1] <- angle_region[1] + 360
	      angle_region <- sort(angle_region)
	    }
	    sub_grid <- filter(sub_grid, theta >= angle_region[1] & theta <= angle_region[2])
	  }
	  
	  max_angle <- max(sub_grid$theta)
	  min_angle <- min(sub_grid$theta)
	  
	  # if one angle is in quad 1 and one in quad 4, then need to be careful
	  
	  if (max_angle >= 270 & min_angle <= 90){
	    sub_grid$theta[sub_grid$theta >= 270] <- sub_grid$theta[sub_grid$theta >= 270] - 360
	  }
	  
	  # Build weights
	  
	  weights <- sqrt(sub_grid$sensitivity)
	  weights <- weights / sum(weights)
	  
	  # estimate departure angle 
	  
	  est_angle_dep <- sum(weights * sub_grid$theta)
	  est_angle_dep <- (est_angle_dep * (pi / 180)) %% (2 * pi)
  }
  
  return(est_angle_dep)

}


