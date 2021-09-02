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

### This script fits & trains the VAE which will be used to send plumes onto a 
### 20-dim latent space. The dimension of the latent space can be changed by 
### altering "latent_dim" just below. 

### Note that altering anything in this script may require tweaks to the VAE model. 
### Even changing the data set may require tweaks. 

##################################################################################
##################################################################################

library(reticulate)
use_condaenv("flexpart", required = TRUE) # Change this to your own Conda environment, or comment out
set.seed(777)
library(keras)
library(tensorflow)

K <- keras::backend()


# Parameters --------------------------------------------------------------

batch_size <- 64
original_dim <- 4096
latent_dim <- 20
epochs <- 90
epsilon_std <- 1
lambda <- 1e-09

# Function to do the sampling via reparameterisation trick in latent space

sampling <- function(arg){
  z_mean <- arg[, 1:(latent_dim)]
  z_log_var <- arg[, (latent_dim + 1):(2 * latent_dim)]
  
  epsilon <- k_random_normal(
    shape = c(k_shape(z_mean)[[1]]), 
    mean = 0,
    stddev = epsilon_std
  )
  
  z_mean + k_exp(z_log_var / 2) * epsilon
}

## Encoder

x <- layer_input(shape = c(64, 64, 1))

encoder_1 <- layer_conv_2d(x,
                           kernel_size = c(3, 3), 
                           filters = 16,
                           strides = 1,
                           activation = "selu", 
                           padding = "same",
                           data_format = "channels_last") %>%
  layer_max_pooling_2d(pool_size = c(2, 2), padding = "same")

encoder_2 <- layer_conv_2d(encoder_1,
                           kernel_size = c(3, 3), 
                           filters = 32,
                           strides = 1,
                           activation = "selu", 
                           padding = "same",
                           data_format = "channels_last") %>%
  layer_max_pooling_2d(pool_size = c(2, 2), padding = "same")

encoder_3 <- layer_conv_2d(encoder_2,
                           kernel_size = c(3, 3), 
                           filters = 64, 
                           strides = 1,
                           activation = "selu", 
                           padding = "same",
                           data_format = "channels_last") %>%
  layer_max_pooling_2d(pool_size = c(2, 2), padding = "same") 

encoder_4 <- layer_conv_2d(encoder_3,
                           kernel_size = c(3, 3), 
                           filters = 128,
                           strides = 1,
                           activation = "selu", 
                           padding = "same",
                           data_format = "channels_last") %>%
  layer_max_pooling_2d(pool_size = c(2, 2), padding = "same")

encoder_5 <- layer_conv_2d(encoder_4,
                           kernel_size = c(3, 3), 
                           filters = 256,
                           strides = 1,
                           activation = "selu", 
                           padding = "same",
                           data_format = "channels_last") %>%
  layer_max_pooling_2d(pool_size = c(2, 2), padding = "same")

encoder_6 <- layer_conv_2d(encoder_5,
                           kernel_size = c(3, 3), 
                           filters = 512,
                           strides = 1,
                           activation = "selu", 
                           padding = "same",
                           data_format = "channels_last") %>%
  layer_max_pooling_2d(pool_size = c(2, 2), padding = "same")

encoder_flatten <- layer_flatten(encoder_6)

z_mean <- layer_dense(encoder_flatten, latent_dim) %>%
  layer_activation_leaky_relu() 
z_log_var <- layer_dense(encoder_flatten, latent_dim) %>%
  layer_activation_leaky_relu() 

## Latent vector
z <- layer_concatenate(list(z_mean, z_log_var)) %>%
  layer_lambda(sampling)


## Decoder layers. Make these layers without adding objects so they can be used
# to construct the stand-alone decoder as well. 

decoder_dense_1 <- layer_dense(units = 512, activation = NULL) 

decoder_image <- layer_reshape(target_shape = c(1, 1, 512)) 

decoder_1 <- layer_conv_2d_transpose(filters = 512, kernel_size = c(2, 2),
                                     strides = 2, padding = "same",
                                     activation = "selu") 

decoder_2 <- layer_conv_2d_transpose(filters = 256, kernel_size = c(2, 2),
                                     strides = 2, padding = "same",
                                     activation = "selu")

decoder_3 <- layer_conv_2d_transpose(filters = 128, kernel_size = c(2, 2),
                                     strides = 2, padding = "same",
                                     activation = "selu")

decoder_4 <- layer_conv_2d_transpose(filters = 64, kernel_size = c(2, 2),
                                     strides = 2, padding = "same",
                                     activation = "selu")

decoder_5 <- layer_conv_2d_transpose(filters = 32, kernel_size = c(2, 2),
                                     strides = 2, padding = "same",
                                     activation = "selu")

decoder_6 <- layer_conv_2d_transpose(filters = 16, kernel_size = c(2, 2),
                                     strides = 2, padding = "same",
                                     activation = "selu")

decoder_final <- layer_conv_2d_transpose(filters = 1, kernel_size = c(2, 2),
                                         strides = 1, padding = "same",
                                         activation = "selu")



## Now actual decoder to be part of full end-to-end model
decoded_512 <- decoder_dense_1(z)
decoded_image <- decoder_image(decoded_512) 
decoded_1 <- decoder_1(decoded_image) 
decoded_2 <- decoder_2(decoded_1) 
decoded_3 <- decoder_3(decoded_2) 
decoded_4 <- decoder_4(decoded_3) 
decoded_5 <- decoder_5(decoded_4) 
decoded_6 <- decoder_6(decoded_5)
x_decoded <- decoder_final(decoded_6)

## end-to-end autoencoder
vae <- keras_model(x, x_decoded)


## encoder, from inputs to latent space
encoder_mean <- keras_model(x, z_mean)
encoder_log_var <- keras_model(x, z_log_var)


## Define loss function
vae_loss <- function(x, x_decoded){
  MSE = k_mean(keras::loss_mean_squared_error(x, x_decoded))
  kl_loss = -0.5 * k_sum(1 + z_log_var - k_square(z_mean) - k_exp(z_log_var), axis = -1)
  return(MSE + lambda * kl_loss)
}

## Compile full end-to-end model


vae %>% compile(optimizer = optimizer_adam(lr = 0.001),  
                loss = vae_loss, 
                metrics = c('mean_squared_error')
)


# Data preparation --------------------------------------------------------

load("FLEXPART-sims/surface-EU/FP-sims-EU-rotated.rdata")
load("FLEXPART-sims/surface-Aus/FP-sims-Aus-rotated.rdata")
load("FLEXPART-sims/surface-Canada/FP-sims-Canada-rotated.rdata")
load("FLEXPART-sims/surface-UK/FP-sims-UK-rotated.rdata")

Plumes <- cbind(FP_sims_EU_rotated$Plumes,
                FP_sims_Aus_rotated$Plumes,
                FP_sims_Canada_rotated$Plumes,
                FP_sims_UK_rotated$Plumes)

rm(FP_sims_EU_rotated)
rm(FP_sims_Aus_rotated)
rm(FP_sims_Canada_rotated)
rm(FP_sims_UK_rotated)

### Remove weak signal plumes
Plumes_normalised <- Plumes / max(Plumes)
ids <- NULL

for (i in 1:ncol(Plumes)) {
  if (sum(Plumes_normalised[, i] > 0.005) < 10) {
    ids <- c(ids, i)
  }
}

Plumes <- Plumes[, -ids]

### Create training and test sets
RNGkind(sample.kind = "Rounding")
set.seed(1365)

n_plumes <- ncol(Plumes)
n_dim_test <- 0.3 * n_plumes

### Remove plumes to use in independent validation
to_test <- sort(sample(1:n_plumes, round(n_dim_test, 0)))
x_test <- Plumes[, to_test]

### Create training set
ids <- sort(c(to_test))
to_train <- (1:n_plumes)[-ids]
x_train <- Plumes[, to_train]

# Transpose and reshape
x_train <- t(x_train)
x_test <- t(x_test)
x_train <- array_reshape(x_train, c(nrow(x_train), 64, 64, 1), order = "F")
x_test <- array_reshape(x_test, c(nrow(x_test), 64, 64, 1), order = "F")

# Model training ----------------------------------------------------------

history <- vae %>% fit(x_train, x_train, 
                       shuffle = TRUE, 
                       epochs = 450, 
                       batch_size = batch_size, 
                       validation_data = list(x_test, x_test)
)


history2 <- vae %>% fit(x_train_centred, x_train_centred, 
                       shuffle = TRUE, 
                       epochs = 50, 
                       batch_size = batch_size, 
                       validation_data = list(x_test_centred, x_test_centred)
)



# generator, from latent space to reconstructed inputs

decoder_input <- layer_input(shape = latent_dim)
decoded_512_2 <- decoder_dense_1(decoder_input)
decoded_image_2 <- decoder_image(decoded_512_2)
decoded_1_2 <- decoder_1(decoded_image_2)
decoded_2_2 <- decoder_2(decoded_1_2)
decoded_3_2 <- decoder_3(decoded_2_2)
decoded_4_2 <- decoder_4(decoded_3_2)
decoded_5_2 <- decoder_5(decoded_4_2)
decoded_6_2 <- decoder_6(decoded_5_2)
x_decoded_2 <- decoder_final(decoded_6_2)

## Build generator
generator <- keras_model(decoder_input, x_decoded_2)


### To save

save_model_hdf5(encoder_mean, 
                filepath = "../src/encoder-mean.h5", 
                overwrite = TRUE, 
                include_optimizer = TRUE)
save_model_hdf5(encoder_log_var, 
                filepath = "../src/encoder-log-var.h5", 
                overwrite = TRUE, 
                include_optimizer = TRUE)
save_model_hdf5(generator, 
                filepath = "../src/generator.h5", 
                overwrite = TRUE, 
                include_optimizer = TRUE)

VAE_vals_training <- list(
  history = history,
  history2 = history2,
  metrics = metrics_VAE_training)

save(VAE_vals_training, file = "VAE-vals-training.rdata")



### Plotting plumes

library(ggplot2)
library(gridExtra)
source("../src/plot-plume.R")
load("grid-new.rdata")
load("EOF-basis.rdata")

# Build EOF reconstructions to compare

U <- EOF_basis$U
V <- EOF_basis$V
D <- EOF_basis$D

EOF_plumes <- V %*% D %*% t(U)

# undo normalising of EOF plumes
for (k in 1:ncol(EOF_plumes)) {
  EOF_plumes[, k] <- EOF_plumes[, k] + EOF_basis$spatial_means
}


true_plume1 <- array_reshape(x_train[3, , , ], c(1, 64, 64, 1))
pred_plume_EOF1 <- EOF_plumes[, 3]

true_plume2 <- array_reshape(x_train[6, , , ], c(1, 64, 64, 1))
pred_plume_EOF2 <- EOF_plumes[, 6]

lats1 <- encoder_mean %>% predict(true_plume1)
lats2 <- encoder_mean %>% predict(true_plume2)

# look at latent means 
lats1
lats2

pred_plume_VAE1 <- generator %>% predict(lats1)
pred_plume_VAE2 <- generator %>% predict(lats2)


P1 <- plot_comparison_plumes(true_plume = true_plume_1, 
                             pred_plume_EOF1,
                             pred_plume_VAE1,
                             plot_labels = c("True", "EOF", "CVAE"),
                             Types = c("T", "P", "P"),
                             grid = grid_new,
                             rows = 1
                             )

P2 <- plot_comparison_plumes(true_plume = true_plume2, 
                             pred_plume_EOF2,
                             pred_plume_VAE2,
                             plot_labels = c("True", "EOF", "CVAE"),
                             Types = c("T", "P", "P"),
                             grid = grid_new,
                             rows = 1
)

grid.arrange(P1, P2, nrow = 2)



### FLEXPART reconstruction metrics

source("metrics.R")

encoded <- encoder_mean %>% predict(x_train)
VAE_plumes <- generator %>% predict(encoded)

FLEXPART_VAE_metrics <- get_metrics(x_train, VAE_plumes)
FLEXPART_EOF_metrics <- get_metrics(x_train, EOF_plumes)

metrics_VAE_training$sum_mses
metrics_EOF_training$sum_mses

training_reconstruction_metrics <- list(
  FLEXPART_EOF_metrics = FLEXPART_EOF_metrics,
  FLEXPART_VAE_metrics = FLEXPART_VAE_metrics)
save(training_reconstruction_metrics, file = "training-reconstruction-metrics.rdata")


