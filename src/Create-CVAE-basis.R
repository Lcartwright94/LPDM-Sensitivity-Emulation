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

### This script creates the VAE basis by running the data to use in the emulation
### through a pre-trained and loaded in Encoder.

### It will save the output as a list, with the encoded means (coefficients),
### encoded log variances (just in case they are wanted), and the min and max
### value used in the normalisation process.

### Each row of the encoded means represents the set of coefficients for 1 
### plume.

##################################################################################
##################################################################################

library(reticulate)
use_condaenv("flexpart", required = TRUE) # Change to your own Conda environment or comment out
library(keras)
library(tensorflow)

# set working directory

encoder_mean <- load_model_hdf5("../src/encoder-mean.h5", compile = FALSE)
encoder_log_var <- load_model_hdf5("../src/encoder-log-var.h5", compile = FALSE)

load("training-plumes.rdata")

### Normalise training plumes

x_train <- training_plumes$Plumes

min_val <- min(x_train) 
max_val <- max(x_train) 

x_train <- t(x_train)
x_train <- array_reshape(x_train, c(nrow(x_train), 64, 64, 1), order = "F")

## Build emulator basis

VAE_means <- encoder_mean %>% predict(x_train)
VAE_log_vars <- encoder_log_var %>% predict(x_train)
VAE_basis <- list(VAE_means = VAE_means, 
                  VAE_log_vars = VAE_log_vars, 
                  min_val = min_val, 
                  max_val = max_val)

save(VAE_basis, file = "VAE-basis.rdata")

