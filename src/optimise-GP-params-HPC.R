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

### This function finds the optimised spatial length scales, temporal length scales, 
### and signal variances for each coefficient, as well as sin theta and cos theta.

### Three arguments: build_data = data to use to build the emulator,
###                   coeff_inits = initial values for coefficients
###                   angle_inits = initial values for sin theta and cos theta.

##################################################################################
##################################################################################



optim_params <- function(build_data, 
                         coeff_inits = log(c(4, 3)), 
                         angle_inits = log(c(1.1, 1.1)),
                         filename = "MLE-parameters.rdata") {
    
    N = nrow(build_data)
    num_coeffs <- ncol(build_data) - 5
    
    X <- build_data[, 1]
    Y <- build_data[, 2]
    Tp <- build_data$time
    
    Z <- cbind(build_data[, 6:(num_coeffs + 5)], 
               sin(build_data$dep_angle), 
               cos(build_data$dep_angle))
  
    MLE_params <- mclapply(1:(num_coeffs + 2), function(m){
      
      if (m <= num_coeffs) { # We use different initial params for coefficients to angles
        params <- get_MLE_params(z = Z[, m], 
                                 inits = coeff_inits, 
                                 X = X, 
                                 Y = Y, 
                                 Tp = Tp, 
                                 N = N)
      } else {
        params <- get_MLE_params(z = Z[, m], 
                                 inits = angle_inits, 
                                 X = X, 
                                 Y = Y, 
                                 Tp = Tp, 
                                 N = N)
     }
      
      
      return(params)
      
    }, mc.cores = cores)
    
    ###################### Save MLE values
    
    coefficient <- c(1:num_coeffs, "angle_sin", "angle_cos")
    spatial_ls <- c()
    temporal_ls <- c()
    sigma <- c()
    
    for (i in 1:(num_coeffs + 2)) {
      spatial_ls[i] <- MLE_params[[i]]$ls
      temporal_ls[i] <- MLE_params[[i]]$lt
      sigma[i] <- MLE_params[[i]]$sigma
    }

    #################### Build final set of MLE params and save as csv
    
    MLE_parameters <- data.frame(coefficient = coefficient, 
                                 spatial_ls = spatial_ls, 
                                 temporal_ls = temporal_ls, 
                                 sigma = sigma)
    
    print(MLE_parameters)
    save(MLE_parameters, file = filename)
    return(MLE_parameters)
  
}





