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

### These functions will produce various plots of the plumes, depending on arguments.

### Arguments specific to each function: 

### plot_plume:
### plume_data = a dataframe with cols "x", "y", and "s"
### map_underlay = the data from "mapdata" specifying what country to draw 
###                underneath plumes.
### tower_locs = a dataframe with one column per measurement tower. 
###              Each column should have an x and y coordinate for that tower.
### x_lab = label on x-axis
### y_lab = label on y-axis
### void = use theme_void()
### colours = change the colour palette. If not set, will use the default white--blue one.
### legend_label = give the legend a label. Default is set. 
###                If "s" is in units other than ns/g, you will need to specify "legend_label"
### scale_lims = set the scale for "fill" (good if plotting multiple plumes one after another)
### xlims = limits of the x-axis
### ylims = limits of the y-axis


### plot_comparison_plumes:
### This function will plot a collection of plumes in the same window
### plot_labels = the labels to put below the x-axis
### Types = a vector, one for each plume to plot. If set to "P", the MSE will be
###         computed. If set to "V", the colour palette will change to white--brown.
###         to produce the uncertainty plot.
### grid = the common grid to plot all plumes on.
### rows = number of rows to organise the plots into
### Other arguments = same description as above. 

### To match the comparison plots given in the paper, either plot the "plumes" and 
### "uncertainty plumes" separately, or plot each plume one at a time and use facet_wrap.

##################################################################################
##################################################################################

plot_plume <- function(plume_data, 
                       map_underlay = NULL,
                       tower_locs = NULL,
                       x_lab = "longitude (degrees E)",
                       y_lab = "latitude (degrees N)",
                       void = TRUE,
                       colors = c("white", 
                                  "dodgerblue", 
                                  "mediumblue", 
                                  "midnightblue"),
                       legend_label = expression(paste(bold("b")[i]," (ns/g)")),
                       scale_lims = NULL,
                       xlims = NULL,
                       ylims = NULL) {
  if (is.null(scale_lims) == TRUE) {
    P <- ggplot(plume_data)  + 
      geom_tile(aes(x = x, y = y, fill = s)) +
      scale_fill_gradientn(colors = colors) +
      theme_bw()
  } else {
    P <- ggplot(plume_data)  + 
      geom_tile(aes(x = x, y = y, fill = s)) + 
      scale_fill_gradientn(colors = colors, limits = scale_lims) + 
      theme_bw()
  } 
  
  if (void == TRUE) {
    P <- P + theme_void() 
  }
  P <- P + ylab(y_lab) + 
    xlab(x_lab) +
    labs(fill = legend_label)
  if (is.null(map_underlay) == FALSE) {
    P <- P + geom_path(data = map_underlay, 
                       aes(x = long, 
                           y = lat, 
                           group = group),
                       color = "black")
  }
  if (is.null(tower_locs) == FALSE) {
    tower_locs <- as.data.frame(t(tower_locs))
    names(tower_locs) <- c("x", "y")
    P <- P + geom_point(data = tower_locs, shape = 4,
                        aes(x = tower_locs$x, y = tower_locs$y), 
                        colour = "red")
  }
  if (is.null(xlims) == FALSE) {
    P <- P + xlim(xlims)
  }
  if (is.null(ylims) == FALSE) {
    P <- P + ylim(ylims)
  }
  return(P)
}


################################## Compare multiple plumes

plot_comparison_plumes <- function(true_plume, 
                                   ..., 
                                   plot_labels,
                                   Types,
                                   grid, 
                                   rows = 2,
                                   xlims = c(min(grid[, 1]), max(grid[, 1])),
                                   ylims = c(min(grid[, 2]), max(grid[, 2])),
                                   map_underlay = NULL,
                                   tower_locs = NULL,
                                   legend_label = bquote(paste(bold("b*")," (ns/g)"))) {
  plots <- list()
  temp_plumes <- cbind(true_plume, ...)
  
  vars_ids <- which(Types == "V")
  if (length(vars_ids) >= 1 & length(vars_ids) < length(plot_labels)) {
    lims_plumes <- c(min(temp_plumes[, -vars_ids]), max(temp_plumes[, -vars_ids]))
    lims_vars <- c(min(temp_plumes[, vars_ids]), max(temp_plumes[, vars_ids]))
  } else if (length(vars_ids) == length(plot_labels)) {
    lims_vars <- c(min(temp_plumes), max(temp_plumes))
  } else {
    lims_plumes <- c(min(temp_plumes), max(temp_plumes))
  }
  
  temp_plumes <- cbind(grid, temp_plumes)
  
  for (k in 1:length(plot_labels)) {
    plume_data <- cbind(grid, temp_plumes[, k + 2])
    names(plume_data) <- c("x", "y", "s")
    if (Types[k] == "P") {
      truth_temp <- temp_plumes[, 3]
      emulated_temp <- temp_plumes[, k + 2]
      SqE_val <- paste0(": MSE = ", round(mean((truth_temp - emulated_temp) ^ 2), 8))
    } else {
      SqE_val <- " "
    }
    if (Types[k] == "V") {
      plots[[k]] <- plot_plume(plume_data = plume_data,
                               void = FALSE,
                               xlims = xlims, 
                               ylims = ylims,
                               map_underlay = map_underlay,
                               scale_lims = lims_vars,
                               tower_locs = tower_locs,
                               colors = c("white", 
                                          "darkgoldenrod",
                                          "goldenrod4",
                                          "tan4"))  + 
        ggtitle(paste0(plot_labels[k], SqE_val)) + 
        theme(plot.title = element_text(hjust = 0.5))
    } else {
      plots[[k]] <- plot_plume(plume_data = plume_data,
                               void = FALSE,
                               scale_lims = lims_plumes,
                               xlims = xlims,
                               ylims = ylims,
                               map_underlay = map_underlay,
                               tower_locs = tower_locs) + 
        ggtitle(paste0(plot_labels[k], SqE_val)) + 
        theme(plot.title = element_text(hjust = 0.5))
    }
  }
  
  P <- grid.arrange(grobs = plots, nrow = rows)
  return(P)
}



### Comparison plot without truth

plot_comparison_plumes_no_truth <- function(true_plume, 
                                   ..., 
                                   plot_labels,
                                   Types,
                                   grid, 
                                   rows = 2,
                                   xlims = c(min(grid[, 1]), max(grid[, 1])),
                                   ylims = c(min(grid[, 2]), max(grid[, 2])),
                                   map_underlay = NULL,
                                   tower_locs = NULL,
                                   legend_label = bquote(paste(bold("b*")," (ns/g)"))) {
  plots <- list()
  temp_plumes <- cbind(true_plume, ...)
  
  vars_ids <- which(Types == "V")
  if (length(vars_ids) >= 1 & length(vars_ids) < length(plot_labels)) {
    lims_plumes <- c(min(temp_plumes[, -vars_ids]), max(temp_plumes[, -vars_ids]))
    lims_vars <- c(min(temp_plumes[, vars_ids]), max(temp_plumes[, vars_ids]))
  } else if (length(vars_ids) == length(plot_labels)) {
    lims_vars <- c(min(temp_plumes), max(temp_plumes))
  } else {
    lims_plumes <- c(min(temp_plumes), max(temp_plumes))
  }
  
  temp_plumes <- cbind(grid, temp_plumes)
  
  for (k in 1:length(plot_labels)) {
    plume_data <- cbind(grid, temp_plumes[, k + 3])
    names(plume_data) <- c("x", "y", "s")
    if (Types[k + 1] == "P") {
      truth_temp <- temp_plumes[, 3]
      emulated_temp <- temp_plumes[, k + 3]
      SqE_val <- paste0(": MSE = ", round(mean((truth_temp - emulated_temp) ^ 2), 8))
    } else {
      SqE_val <- " "
    }
    if (Types[k + 1] == "V") {
      plots[[k]] <- plot_plume(plume_data = plume_data,
                               void = FALSE,
                               xlims = xlims, 
                               ylims = ylims,
                               map_underlay = map_underlay,
                               scale_lims = lims_vars,
                               tower_locs = tower_locs,
                               colors = c("white", 
                                          "darkgoldenrod",
                                          "goldenrod4",
                                          "tan4"))  + 
        ggtitle(paste0(plot_labels[k], SqE_val)) + 
        theme(plot.title = element_text(hjust = 0.5))
    } else {
      plots[[k]] <- plot_plume(plume_data = plume_data,
                               void = FALSE,
                               scale_lims = lims_plumes,
                               xlims = xlims,
                               ylims = ylims,
                               map_underlay = map_underlay,
                               tower_locs = tower_locs) + 
        ggtitle(paste0(plot_labels[k], SqE_val)) + 
        theme(plot.title = element_text(hjust = 0.5))
    }
  }
  
  P <- grid.arrange(grobs = plots, nrow = rows)
  return(P)
}

