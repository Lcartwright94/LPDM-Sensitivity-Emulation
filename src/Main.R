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

### This script is the main wrapper for the emulation. Within this script, 
### the emulation occurs, MLE if needed, the unrotation, and construction of
### some basic comparison plots. 

### Currently set up for the 2014 UK NAME plumes.

##################################################################################
##################################################################################


library(reticulate)
use_condaenv("flexpart", required = TRUE)
library(parallel)
library(gstat)
library(fields)
library(tidyr)
library(dplyr)
library(tensorflow)
library(keras)
library(ggplot2)
library(gridExtra)
library(parallel)


K <- keras::backend()

####################################################################################

cores <- 60
num_plumes <- 1 # Number of plumes to average over in GP rotation
MLE_EOF <- 1 # If 1, then MLE will occur within the GP emulator. If 0, you need to change the 
# name of the MLE params file just below, and also its name in R (the next lines down).
MLE_VAE <- 1

if (MLE_EOF == 0) {
  load("MLE-parameters-GP-EOF.rdata")
  MLE_vals_EOF <- MLE_parameters_GP_EOF
} else {
  MLE_vals_EOF <- NULL
}

if (MLE_VAE == 0) {
  load("MLE-parameters-GP-VAE.rdata")
  MLE_vals_VAE <- MLE_parameters_GP_VAE
} else {
  MLE_vals_VAE <- NULL
}

load("EOF-basis.rdata")
load("VAE-basis.rdata")
load("training-plumes.rdata")
load("validation-plumes-rotated.rdata")
load("NAME-UK-2014-grid.rdata")
load("grid-new.rdata")
load("VAE-vals.rdata")

source("../src/emulator-gp.R")
source("../src/optimise-GP-params-HPC.R")
source("../src/get-MLE-params.R")
source("../src/time-to-numeric.R")
source("../src/neg-log-like.R")
source("../src/covariances.R")
source("../src/get-GP-mean-var.R")
source("../src/unrotate-plumes.R")
source("../src/plot-plume.R")
source("../src/metrics.R")

coeffs_EOF <- EOF_basis$U
coeffs_VAE <- VAE_basis$VAE_means

Training_plumes <- training_plumes$Plumes
Training_time_stamps <- training_plumes$time_stamps
Training_labels <- training_plumes$Labels
Training_dep_angle <- training_plumes$dep_angle
Training_x <- training_plumes$x
Training_y <- training_plumes$y

Validation_plumes <- validation_plumes_rotated$Plumes
Validation_time_stamps <- validation_plumes_rotated$time_stamps
Validation_labels <- validation_plumes_rotated$Labels
Validation_dep_angle <- validation_plumes_rotated$dep_angle
Validation_x <- validation_plumes_rotated$x
Validation_y <- validation_plumes_rotated$y

# Change time stamps to numeric values
Training_time_stamps_numeric <- time_to_numeric(Training_time_stamps)
Validation_time_stamps_numeric <- time_to_numeric(Validation_time_stamps)


# -------------------- Get data to use in emulation ------------------- #

# column 5 is estimated departure angle
# columns 6:25 are the coefficients for EOFs 1:20 resp. or CVAE dimensions 1-20.

data_to_use_EOF <- data.frame(x_loc = Training_x, 
                              y_loc = Training_y, 
                              time = Training_time_stamps_numeric,
                              label = Training_labels,
                              dep_angle = Training_dep_angle,
                              coeffs_EOF)

data_to_use_VAE <- data.frame(x_loc = Training_x, 
                              y_loc = Training_y, 
                              time = Training_time_stamps_numeric,
                              label = Training_labels,
                              dep_angle = Training_dep_angle,
                              coeffs_VAE)

# ---------------------  Get data to emulate ------------------- #
# This is only 4 columns: x, y, time, and label

data_to_emulate <- data.frame(x_loc =  Validation_x,
                              y_loc = Validation_y,
                              time = Validation_time_stamps_numeric,
                              label = Validation_labels)



#################### ---------------------------------------------------- ####################

#################### ------ Emulate plume coefficients ------ ####################

#################### ---------------------------------------------------- ####################

# EOF
if (is.null(MLE_vals_EOF) == TRUE) {
  GP_emulated_EOF <- emulate_gp(build_data = data_to_use_EOF, 
                                predict_data = data_to_emulate,
                                cores = cores)
} else {
  GP_emulated_EOF <- emulate_gp(build_data = data_to_use_EOF, 
                                predict_data = data_to_emulate, 
                                hyperparams = MLE_vals_EOF,
                                cores = cores)
}

# VAE
if (is.null(MLE_vals_VAE) == TRUE) {
  GP_emulated_VAE <- emulate_gp(build_data = data_to_use_VAE, 
                                predict_data = data_to_emulate,
                                cores = cores)
} else {
  GP_emulated_VAE <- emulate_gp(build_data = data_to_use_VAE, 
                                predict_data = data_to_emulate, 
                                hyperparams = MLE_vals_VAE,
                                cores = cores)
}

# This will return a list called gp_emulated with the following items:

###    - post_means: Means for the posterior distributions of each EOF coefficient/CVAE dimension, and for
##       emulated plume. One row per coefficient, and one column per plume which is emulated.
##     - post_covs: Same as post_means but returns the variance of each coefficient.
##     - post_means_sin: The posterior means for the distribution of sin(theta). A vector with one
##       entry per plume which is emulated. 
##     - post_covs_sin: Same as post_mean_sin but returns the posterior variances of each sin(theta).
##     - post_means_cos: Same as post_mean_sin but for cos(theta).
##     - post_covs_cos: Same as post_cov_sin but for cos(theta).


## Save emulated vals 

save(GP_emulated_EOF, file = "GP-emulated-EOF.rdata")
save(GP_emulated_VAE, file = "GP-emulated-VAE.rdata")


#################### ---------------------------------------------------- ####################

#################### ------------------- Build plumes ------------------- ####################

#################### ---------------------------------------------------- ####################


### Get values

GP_coeffs_EOF <- GP_emulated_EOF$post_means
GP_vars_EOF <- GP_emulated_EOF$post_covs
GP_sin_means_EOF <- GP_emulated_EOF$post_means_sin
GP_sin_covs_EOF <- GP_emulated_EOF$post_covs_sin
GP_cos_means_EOF <- GP_emulated_EOF$post_means_cos
GP_cos_covs_EOF <- GP_emulated_EOF$post_covs_cos

# Now CVAE

GP_coeffs_VAE <- GP_emulated_VAE$post_means
GP_vars_VAE <- GP_emulated_VAE$post_covs
GP_sin_means_VAE <- GP_emulated_VAE$post_means_sin
GP_sin_covs_VAE <- GP_emulated_VAE$post_covs_sin
GP_cos_means_VAE <- GP_emulated_VAE$post_means_cos
GP_cos_covs_VAE <- GP_emulated_VAE$post_covs_cos

### Build plumes EOF

V <- EOF_basis$V
D <- EOF_basis$D

GP_plumes_EOF <- V %*% D %*% GP_coeffs_EOF
# equal to t(t(GP_coeffs_EOF) %*% D %*% t(V)), gives dimensions the right way for us

# Undo normalising which occurred in training
for (k in 1:ncol(GP_plumes_EOF)) {
  GP_plumes_EOF[, k] <- GP_plumes_EOF[, k] + EOF_basis$spatial_means
}


### Build plumes VAE
generator <- load_model_hdf5("../src/generator.h5", compile = FALSE)

GP_plumes_VAE <- generator %>% predict(t(GP_coeffs_VAE))
# Note shape is Num_plumes, 64, 64, 1

## set negative vals to zero

GP_plumes_EOF[GP_plumes_EOF < 0] <- 0
GP_plumes_VAE[GP_plumes_VAE < 0] <- 0



#######-------------------------------------------#############
#######-------------------------------------------#############
### Rotate GP plumes EOF (here sin(theta) and cos(theta) are described by Gaussian dists, so 
### we do multiple rotations and find MC average plume and MC uncertainty plume)
#######-------------------------------------------#############

ss <- 1:ncol(GP_coeffs_EOF) # Select which plumes to rotate & translate. Currently ALL

Rots <- mclapply(ss, function(m) {
  
  plumes_m <- NULL
  if (num_plumes > 1) {
    sines <- rnorm(num_plumes, mean = GP_sin_means_EOF[m], sd = sqrt(GP_sin_covs_EOF[m]))
    cosines <- rnorm(num_plumes, mean = GP_cos_means_EOF[m], sd = sqrt(GP_cos_covs_EOF[m]))
  } else {
    sines <- GP_sin_means_EOF[m]
    cosines <- GP_cos_means_EOF[m]
  }
  
  if (num_plumes > 1) { 
    for (k in 1:num_plumes) {
      coeffs <- rnorm(nrow(GP_vars_EOF), mean = GP_coeffs_EOF[, m], sd = sqrt(GP_vars_EOF[, m]))
      built_plume <- V %*% D %*% coeffs
      built_plume <- built_plume + EOF_basis$spatial_means
      built_plume[built_plume < 0] <- 0
      plumes_m <- cbind(plumes_m, unrotate_plume_single(plume = built_plume,
                                                        sin_theta = sines[k],
                                                        cos_theta = cosines[k],
                                                        xloc_tower = Validation_x[m],
                                                        yloc_tower = Validation_y[m],
                                                        current_grid = grid_new,
                                                        original_grid = NAME_UK_2014_grid))
      print(k)
    }
    av_plume <- rowMeans(plumes_m)
    var_plume <- apply(plumes_m, 1, function(x) {var(x)})
  } else {
    plumes_m <- unrotate_plume_single(plume = GP_plumes_EOF[, m],
                                      sin_theta = sines,
                                      cos_theta = cosines,
                                      xloc_tower = Validation_x[m],
                                      yloc_tower = Validation_y[m],
                                      current_grid = grid_new,
                                      original_grid = NAME_UK_2014_grid)
    av_plume <- plumes_m
    var_plume <- rep(0, length(plumes_m))
  }
  
  print(paste0("plume ", m, " done"))
  return(list(av_plume = av_plume,
              var_plume = var_plume))
  
}, mc.cores = cores)

# Put them all together
GP_unrotated_plumes_means <- NULL
GP_unrotated_plumes_vars <- NULL

for (i in 1:length(ss)) {
  GP_unrotated_plumes_means <- cbind(GP_unrotated_plumes_means, Rots[[i]]$av_plume)
  GP_unrotated_plumes_vars <- cbind(GP_unrotated_plumes_vars, Rots[[i]]$var_plume)
  print(i)
}


if (num_plumes > 1) {
  GP_emulated_unrotated_EOF_uncertainty <- list(Plumes_means = GP_unrotated_plumes_means,
                                    Plumes_vars = GP_unrotated_plumes_vars,
                                    Labels = Validation_labels[ss],
                                    time_stamps = Validation_time_stamps[ss],
                                    x_loc = Validation_x[ss],
                                    y_loc = Validation_y[ss])
} else {
  GP_emulated_unrotated_EOF <- list(Plumes_means = GP_unrotated_plumes_means,
                                    Plumes_vars = GP_unrotated_plumes_vars,
                                    Labels = Validation_labels,
                                    time_stamps = Validation_time_stamps,
                                    x_loc = Validation_x,
                                    y_loc = Validation_y)
}


#######-------------------------------------------#############
#######-------------------------------------------#############
### Rotate plumes VAE (here sin(theta) and cos(theta) are described by Gaussian dists, so 
### we do multiple rotations and find MC average plume and MC uncertainty plume)
#######-------------------------------------------#############

Params <- mclapply(ss, function(m) {
  
  if (num_plumes > 1) {
    sines <- rnorm(num_plumes, mean = GP_sin_means_VAE[m], sd = sqrt(GP_sin_covs_VAE[m]))
    cosines <- rnorm(num_plumes, mean = GP_cos_means_VAE[m], sd = sqrt(GP_cos_covs_VAE[m]))
  } else {
    sines <- GP_sin_means_VAE[m]
    cosines <- GP_cos_means_VAE[m]
  }
  angle_params <- list(sines = sines, 
                       cosines = cosines)
}, mc.cores = cores)

temp_plumes <- NULL

for (m in 1:ncol(GP_vars_VAE)) {
  coeffs <- matrix(rnorm(nrow(GP_vars_VAE) * num_plumes, mean = GP_coeffs_VAE[, m], sd = sqrt(GP_vars_VAE[, m])),
                   nrow = nrow(GP_vars_VAE), 
                   ncol = num_plumes)
  temp_plumes[[m]] <- generator %>% predict(t(coeffs))
  temp_plumes[[m]][temp_plumes[[m]] < 0] <- 0
}

Rots <- mclapply(ss, function(m) {
  
  plumes_m <- NULL
  for (k in 1:num_plumes) {
    plumes_m <- cbind(plumes_m, unrotate_plume_single(plume = as.vector(temp_plumes[[m]][k, , , ]),
                                                      sin_theta = Params[[m]]$sines[k],
                                                      cos_theta = Params[[m]]$cosines[k],
                                                      xloc_tower = Validation_x[m],
                                                      yloc_tower = Validation_y[m],
                                                      current_grid = grid_new,
                                                      original_grid = NAME_UK_2014_grid))
    print(k)
  }
  if (num_plumes > 1) {
    av_plume <- rowMeans(plumes_m)
    var_plume <- apply(plumes_m, 1, function(x) {var(x)})
  } else {
    av_plume <- as.vector(plumes_m)
    var_plume <- rep(0, length(plumes_m))
  }
  
  
  print(paste0("plume ", m, " done"))
  return(list(av_plume = av_plume,
              var_plume = var_plume))
  
}, mc.cores = cores)


# Put them all together
GP_unrotated_plumes_means <- NULL
GP_unrotated_plumes_vars <- NULL

for (i in 1:length(ss)) {  
  GP_unrotated_plumes_means <- cbind(GP_unrotated_plumes_means, Rots[[i]]$av_plume)
  GP_unrotated_plumes_vars <- cbind(GP_unrotated_plumes_vars, Rots[[i]]$var_plume)
  print(i)
}

if (num_plumes > 1) {
  GP_emulated_unrotated_VAE_uncertainty <- list(Plumes_means = GP_unrotated_plumes_means,
                                    Plumes_vars = GP_unrotated_plumes_vars,
                                    Labels = Validation_labels[ss],
                                    time_stamps = Validation_time_stamps[ss],
                                    x_loc = Validation_x[ss],
                                    y_loc = Validation_y[ss])
} else {
  GP_emulated_unrotated_VAE <- list(Plumes_means = GP_unrotated_plumes_means,
                                    Plumes_vars = GP_unrotated_plumes_vars,
                                    Labels = Validation_labels,
                                    time_stamps = Validation_time_stamps, 
                                    x_loc = Validation_x,
                                    y_loc = Validation_y)
}



### Save unrotated plumes

save(GP_emulated_unrotated_EOF_uncertainty, file = "GP-emulated-unrotated-EOF-uncertainty.rdata")
save(GP_emulated_unrotated_VAE_uncertainty, file = "GP-emulated-unrotated-VAE-uncertainty.rdata")
























### Get metrics & create same comparison plot as paper
## If you want more plots, either change ss to a single number manually, 
## or create a for loop to build plots for multiple different plumes, 
## indexed by a vector ss. 

load("validation-plumes.rdata")
ss <- 503

load("validation-plumes-unrotated.rdata")
UK_map <- map_data(map = "world", region = c("UK", "Ireland"))

MHD_loc <- c(-9.9, 53.33)
RGL_loc <- c(-2.54, 52.00)
TAC_loc <- c(1.14, 52.52)
TTA_loc <- c(-2.99, 56.56)
locations <- data.frame(MHD_loc, RGL_loc, TAC_loc, TTA_loc)


true_plume <- validation_plumes_unrotated$Plumes[, ss]

png(paste0("../Comparison plot.png"), width = 900, height = 600)
P_comp <- plot_comparison_plumes(true_plume,
                                 GP_emulated_unrotated_EOF$Plumes_means[, ss],
                                 GP_emulated_unrotated_VAE$Plumes_means[, ss],
                                 GP_emulated_unrotated_EOF$Plumes_vars[, ss],
                                 GP_emulated_unrotated_VAE$Plumes_vars[, ss],
                                 plot_labels = c("True", "EOF", "CVAE", "EOF uncertainty", "CVAE uncertainty"),
                                 Types = c("T", "P", "P", "V", "V"),
                                 grid = NAME_UK_2014_grid,
                                 xlims = c(-12, 4),
                                 ylims = c(47, 62),
                                 rows = 2,
                                 map_underlay = UK_map,
                                 tower_locs = locations)
dev.off()





GP_EOF_metrics <- get_metrics(validation_plumes_unrotated$Plumes, GP_emulated_unrotated_EOF_uncertainty$Plumes_means)
GP_VAE_metrics <- get_metrics(validation_plumes_unrotated$Plumes, GP_emulated_unrotated_VAE_uncertainty$Plumes_means)


c(GP_EOF_metrics$sum_mses, GP_EOF_metrics$upper_10_mean)
c(GP_VAE_metrics$sum_mses, GP_VAE_metrics$upper_10_mean)

global_maes <- get_maes(GP_EOF_metrics$mses, GP_VAE_metrics$mses)
mean(global_maes)

emulation_metrics_unrotated <- list(
  GP_EOF_metrics = GP_EOF_metrics,
  GP_VAE_metrics = GP_VAE_metrics,
  global_maes = global_maes)
save(emulation_metrics_unrotated, file = "emulation-metrics-unrotated.rdata")

png(file = "../unrotated-maes.png", width = 600, height = 300)
hist(global_maes, col = "cadetblue2", xlab = "Normalised error",
main = "Normalised error of emulated NAME plumes")
dev.off()




