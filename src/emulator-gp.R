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

### This function uses a Gaussian Process emulator to emulate values for 
### the coefficients, sin(theta), and cos(theta). 

### Five arguments: build_data = data to use to build the emulator,
###                 predict_data = data to find emulated values for
###                 hyperparams = the MLE estimates for the length scales and signal
###                               variances. If none provided, the MLE will be done as
###                               part of this function.
###                 num_days = number of days either side of data point of interest
###                            in which to emulate (good if you have a very large 
###                            amount of data. That is, too big for the calcs).
###                 cores = number of cores to use for parallel processing.

### Note that the emulator is A LOT faster if you do not subset by day. This is 
### because when we do not subset by day, we can compute all emulated values 
### for each coefficient in one hit (matrix multiplication). We can't do this
### when subsetting as each subset will contain different observations. Thus in 
### this case, the emulation has to be done one point at a time.

### Second note: To get this to work, I had to add epsilon to diagonal of the 
### first covariance matrix built (the covariance between the observed locs, 
### and the observed locs).

##################################################################################
##################################################################################


emulate_gp <- function(build_data, # data to use to build emulators
                       predict_data, # data to use to emulate new plumes
                       hyperparams = optim_params(build_data), # length scales and sigmas for GPs
                       num_days = NA, # Number of days to subset by if wanted
                       cores = 1 # Number of computer cores to use in parallel parts
                       ){

  num_coeffs <- ncol(build_data) - 5
  
  # -------------------- Set hyperparameters (length scales and amplitude) -------------------- #
  
  spatial_ls <- hyperparams$spatial_ls
  temporal_ls <- hyperparams$temporal_ls
  sigma_0 <- hyperparams$sigma
  
  predicted_locs <- data.frame(predict_data$x_loc, predict_data$y_loc)
  time_predict <- predict_data$time
  
  ### If not subsetting, then parallelise by coefficient
  ### If subsetting the dataset to only use data +- num_days, then parallelise by row in data_to_emulate
  
  
  if (is.na(num_days) == TRUE) {
    observed_locs <- data.frame(build_data$x_loc, build_data$y_loc)
    time_obs <- build_data$time
    
    Z <- cbind(build_data[, 6:(num_coeffs + 5)], 
               sin(build_data$dep_angle), 
               cos(build_data$dep_angle))
    
    # Compute posterior means and covariances for coeeficients
    
    em_res <- mclapply(1:ncol(Z), function(m) {
        
      lss <- spatial_ls[m]
      lst <- temporal_ls[m]
      sig_0 <- sigma_0[m]
      z <- Z[, m]
      
      # Get cov matrix for observed data
      
      pred_vals <- get_mean_var(observed_locs = observed_locs, 
                                time_obs = time_obs, 
                                predicted_locs = predicted_locs, 
                                time_predict = time_predict, 
                                ls = lss, 
                                lt = lst, 
                                sig_0 = sig_0, 
                                z = z)
       
      return(pred_vals)
      
    }, mc.cores = cores)
    
    post_means <- NULL
    post_covs <- NULL
    
    for (i in 1:num_coeffs) {
      post_means <- rbind(post_means, em_res[[i]]$post_means)
      post_covs <- rbind(post_covs, em_res[[i]]$post_covs)
    }
    
    post_means_sin <- em_res[[num_coeffs + 1]]$post_means
    post_covs_sin <- em_res[[num_coeffs + 1]]$post_covs
    post_means_cos <- em_res[[num_coeffs + 2]]$post_means
    post_covs_cos <- em_res[[num_coeffs + 2]]$post_covs
    
    ### Put everything together
    
    emulated_data <- list(post_means = post_means, 
                          post_covs = post_covs,
                          post_means_sin = post_means_sin,
                          post_covs_sin = post_covs_sin,
                          post_means_cos = post_means_cos,
                          post_covs_cos = post_covs_cos)
    
  } else {
  
  em_res <- mclapply(1:nrow(predict_data), function(m){
    
    time_id <- predict_data$time[m]
    ids <- which(build_data$time >= time_id - (24 * num_days) & 
                   build_data$time <= time_id + (24 * num_days))
    build_data_sub <- build_data[ids, ]
    observed_locs <- data.frame(build_data_sub$x_loc,
                                build_data_sub$y_loc)
    time_obs <- build_data_sub$time
    
    Z <- cbind(build_data_sub[, 6:(num_coeffs + 5)], 
               sin(build_data_sub$dep_angle), 
               cos(build_data_sub$dep_angle))
    
    if (nrow(build_data) > 0) {
      
      ### Emulate coefficients
        
        post_means <- c()
        post_covs <- c()
        
        predicted_locs <- data.frame(predict_data$x_loc[m], 
                                     predict_data$y_loc[m])
        
        for (i in 1:ncol(z)) {
          
          lss <- spatial_ls[i]
          lst <- temporal_ls[i]
          sig_0 <- sigma_0[i]
          z <- Z[, i]
          
          pred_vals <- get_mean_var(observed_locs = observed_locs, 
                                    time_obs = time_obs, 
                                    predicted_locs = predicted_locs, 
                                    time_predict = time_id, 
                                    ls = lss, 
                                    lt = lst, 
                                    sig_0 = sig_0, 
                                    z = z)
            
          post_means[i] <- as.numeric(pred_vals$post_mean)
          post_covs[i] <- as.numeric(pred_vals$post_cov)
          
          print(paste0("coeff ", i))
          
        }
        
        post_means_sin <- post_means[num_coeffs + 1]
        post_covs_sin <- post_covs[num_coeffs + 1]
        post_means_cos <- post_means[num_coeffs + 2]
        post_covs_cos <- post_covs[num_coeffs + 1]
        
        post_means <- post_means[1:num_coeffs]
        post_covs <- post_covs[1:num_coeffs]
        
        ### Save results
        
        Res <- list(post_means = post_means,
                    post_covs = post_covs,
                    post_means_sin = post_means_sin,
                    post_covs_sin = post_covs_sin,
                    post_means_cos = post_means_cos,
                    post_covs_cos = post_covs_cos)
        
        print(m)
        return(Res)
        
    }
  
  }, mc.cores = cores)

  
  post_mean_sin <- c()
  post_cov_sin <- c()
  post_mean_cos <- c()
  post_cov_cos <- c()
  
  post_means <- NULL
  post_covs <- NULL
  
  for (i in 1:nrow(predict_data)) {
    post_means <- cbind(post_means, em_res[[i]]$post_means)
    post_covs <- cbind(post_covs, em_res[[i]]$post_covs)
    post_means_sin[i] <- em_res[[i]]$post_means_sin
    post_covs_sin[i] <- em_res[[i]]$post_covs_sin
    post_means_cos[i] <- em_res[[i]]$post_means_cos
    post_covs_cos[i] <- em_res[[i]]$post_covs_cos
  }
  
  ### Put everything together
  
  emulated_data <- list(post_means = t(post_means), 
                        post_covs = t(post_covs),
                        post_means_sin = post_means_sin,
                        post_covs_sin = post_covs_sin,
                        post_measn_cos = post_means_cos,
                        post_covs_cos = post_covs_cos)
  
  
  }

  return(emulated_data)
  
}



    
    
