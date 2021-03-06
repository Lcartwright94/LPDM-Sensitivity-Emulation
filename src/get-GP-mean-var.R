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

### This function obtains the posterior means and variances from the GP emulator.

### Eight arguments: observed_locs = locations of observation towers in data to 
###                                  use in the emulator
###                  time_obs = time points in data to use in emulator
###                  predicted_locs = locations of observation towers in the 
###                                   data to predict using emulator
###                  time_predict = time points of observations to be predicted
###                                 in the emulator
###                  ls = spatial length scale
###                  lt = temporal length scale
###                  sig_0 = signal variance
###                  z = coefficents/angles to emulate from (e.g. coeffs for one EOF)

##################################################################################
##################################################################################




##### ------------------ Get posterior mean and variance in GP emulator -------------------- ###

get_mean_var <- function(observed_locs, 
                         time_obs, 
                         predicted_locs, 
                         time_predict, 
                         ls, 
                         lt, 
                         sig_0, 
                         z) {
  
  cov_obs <- cov_small(X1 = observed_locs, 
                       X2 = observed_locs, 
                       Tp1 = time_obs,
                       Tp2 = time_obs, 
                       ls = ls, 
                       lt = lt, 
                       sig_0 = sig_0)
  
  # get inverse covariance matrix
  
  cov_obs_inv <- chol2inv(chol(cov_obs))
  
  # compute posterior means & covariance matrix
  
  post_mean <- cov_small(X1 = predicted_locs, 
                         X2 = observed_locs, 
                         Tp1 = time_predict, 
                         Tp2 = time_obs, 
                         ls = ls, 
                         lt = lt, 
                         sig_0 = sig_0) %*% 
                cov_obs_inv %*% 
                z
  
  post_cov_mat <- cov_small(X1 = predicted_locs, 
                            X2 = predicted_locs, 
                            Tp1 = time_predict, 
                            Tp2 = time_predict, 
                            ls = ls, 
                            lt = lt, 
                            sig_0 = sig_0) - 
    cov_small(X1 = predicted_locs, 
              X2 = observed_locs, 
              Tp1 = time_predict,
              Tp2 = time_obs, 
              ls = ls, 
              lt = lt, 
              sig_0 = sig_0) %*% 
    cov_obs_inv %*% 
    cov_small(X1 = observed_locs, 
              X2 = predicted_locs, 
              Tp1 = time_obs, 
              Tp2 = time_predict, 
              ls = ls, 
              lt = lt, 
              sig_0 = sig_0) 
  
  post_cov <- diag(post_cov_mat)
  
  return(data.frame(post_means = post_mean, post_covs = post_cov))
  
}

