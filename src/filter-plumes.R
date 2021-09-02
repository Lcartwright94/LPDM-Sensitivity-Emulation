##################################################################################
##################################################################################

### This function removes any plumes which go off the grid
### By that, I mean more than 3 values above the 5th percentile on the grid border.

##################################################################################
##################################################################################

filter_plumes <- function(plumes, border_ids) {
  
  ## Transform to [0, 1] so percentages make sense
  plumes_normalised <- plumes
  
  for (i in 1:ncol(plumes)) {
    max_val <- max(plumes[, i])
    min_val <- min(plumes[, i])
    plumes_normalised[, i] <- (plumes[, i] - min_val) / (max_val - min_val) 
  }
  plumes_normalised <- round(plumes_normalised, 4)
  
  
  ## Remove plumes with "signal" on the border of the grid
  
  rem_ids <- c()
  for (i in 1:ncol(plumes)){
    S <- sum(plumes_normalised[border_ids, i] > 0.05) # Count how many bordering cells have "signal"
    rem_ids[i] <- ifelse (S > 3, i, 0) # If more than 3 have signal, we will remove the plume
  }
  
  rem_ids <- rem_ids[rem_ids > 0]
  plumes_filtered <- plumes[, -rem_ids]
  
  return(list(plumes_filtered = plumes_filtered, rem_ids = rem_ids))
  
}

