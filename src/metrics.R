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

### This function computes the sum of the mean squared errors for all plumes given,
### or the individual mean absolute errors between the EOF and VAE approaches. 
### The get_mses function also returns the individual MSEs per plume, and the 
### average MSE for the largest 10% of MSEs.

### get_mses has 2 arguments: truth = a matrix of the true plumes, one column per plume.
###                           emulated = a matrix of the emulated plumes, one column per plume.

### get_maes has 2 arguments: mse_eof = the MSEs for each plume emulated via EOFs as a vector.
###                           mse_vae = the MSEs for each plume emulated via CVAE as a vector.

##################################################################################
##################################################################################



### Get sum of mean squared errors

get_metrics <- function(truth, emulated) {
  mses <- c()
  if (length(dim(emulated)) > 2) {
    for (i in 1:ncol(truth)) {
      truth_temp <- truth[, i]
      emulated_temp <- as.vector(emulated[i, , , ])
      mses[i] <- mean((truth_temp - emulated_temp) ^ 2)
    }
  } else {
    for (i in 1:ncol(truth)) {
      truth_temp <- truth[, i]
      emulated_temp <- emulated[, i]
      mses[i] <- mean((truth_temp - emulated_temp) ^ 2)
    }
  }
  quant_90 = quantile(mses, 0.90)
  qm <- mean(mses[mses >= quant_90])
  return(list(mses = mses, 
              sum_mses = sum(mses),
              upper_10_mean = qm))
}


### Get mean absolute errors

get_maes <- function(mse_eof, mse_vae) {
  maes <- c()
  for (i in 1:length(mse_eof)) {
    maes[i] <- (mse_eof[i] - mse_vae[i]) / mse_eof[i]
  }
  return(maes)
}
