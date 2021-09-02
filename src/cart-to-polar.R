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

### This function converts the data frame used in departure angle estimation from 
### Cartesian coordinates to polar coordinates on [0, 360).

### Argument: Points = data frame with cols "x" and "y".

##################################################################################
##################################################################################



cart_to_polar <- function(Points){
  Points_polar <- Points
  names(Points_polar) <- c("r", "theta")
  Points_polar$r <- sqrt((Points$x ^ 2) + (Points$y ^ 2))
  Points_polar$theta <- atan2(Points$y, Points$x)
  Points_polar$theta[Points_polar$theta < 0] <- Points_polar$theta[Points_polar$theta < 0] + 2 * pi
  Points_polar$theta <- Points_polar$theta * 180 / pi # convert to degrees
  return(Points_polar)
}
