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

### This function rotates the emulated plume back to the original space.

### Nine arguments:  plume = the plume to rotate back to original space
###                  sin_theta = value of sin(theta) to use in rotation matrix
###                  cos_theta = value of cos(theta) to use in rotation matrix
###                  xloc_tower = x-coordinate of original origin of plume
###                  yloc_tower = y-coordinate of original origin of plume
###                  current_grid = the grid used in emulation (64 x 64)
###                  alpha = the inverse power applied to the weights. 
###                  original_grid = the grid over the original space (orig resol.)
###                  method = 1 for Matrix calcs, 2 for IDW


##################################################################################
##################################################################################

unrotate_plume_single <- function(plume, 
                            sin_theta, 
                            cos_theta, 
                            xloc_tower, 
                            yloc_tower, 
                            current_grid, 
                            original_grid,
                            alpha = 6,
			                      method = 1){
  # undo zero-ing of location
  
  trans_grid <- current_grid
  names(trans_grid) <- c("x", "y")
  
  # perform rotation
  
  trans_grid$rot_x <- trans_grid$x * cos_theta - trans_grid$y * sin_theta
  trans_grid$rot_y <- trans_grid$x * sin_theta + trans_grid$y * cos_theta

  Data_set <- data.frame(trans_grid$rot_x + xloc_tower, trans_grid$rot_y + yloc_tower, plume)
  names(Data_set) <- c("x", "y", "plume")
  
  # do IDW to get plume on original spatial coordinates
  # Method 1 for matrix calculations, method 2 for gstat::idw
  
  if (method == 1) {
  	  
	  dists <- fields::rdist(original_grid, Data_set[, 1:2])
	  
	  weights <- 1 / dists ^ alpha
	  weights_normalised <- weights / rowSums(weights)
	  
	  rotated <- as.numeric(weights_normalised %*% plume)

  } else {
	  rotated <- gstat::idw(formula = plume ~ 1, # dep. variable
		                locations = ~ x + y, # inputs
		                data = Data_set,
		                newdata = original_grid, # prediction grid
		                idp = 6,
				nmax = 25)$var1.pred
  }
  
  unrotated_plume <- rotated
  
  return(unrotated_plume)
}

