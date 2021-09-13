# LPDM-Sensitivity-Emulation

This repository contains a number scripts and links to datasets required to reproduce results presented in "Emulation of greenhouse-gas sensitivities using variational autoencoders", by Laura Cartwright, Andrew Zammit-Mangion, and Nicholas M. Deutscher.

All scripts (except one shell script) are written in [R](https://www.r-project.org/), specifically, R 3.6.3. The easiest way to run them (and the way described below) is via the terminal/command line, and using the Conda environment included in this repository. The scripts can also easily be run via [RStudio](https://www.rstudio.com/). Note you must download and install R before RStudio.

## Downloading the repository

This can either be done by clicking the green "Clone or download" button, or by running the following in the command line/terminal:

git clone https://github.com/Lcartwright94/LPDM-Sensitivity-Emulation

## Creating the Conda environment

First ensure you have installed [Conda](https://docs.anaconda.com/anaconda/install/index.html). Then, check that the file "conda-environment.yml" has been downloaded when you cloned the repository. From a terminal/command line, run 

```diff
conda env create -n EnvName -f conda-environment.yml 
```

where "EnvName" is the name of the conda environment.

## Data files

There are a number of data files which accompany the scripts in this repository. You can access and download the data [here](https://hpc.niasra.uow.edu.au/ckan/dataset/r-data-lpdm-emulation). They are broken into three groups: 

#### FLEXPART simulations

These are the raw output files from FLEXPART. They are broken into four groups, based on the region over which the simulations were performed: Australia, Canada, Europe, or the UK. There are 5000 simulations per region, and a 5-6 month time period over which to perform the simulations was allocated to each region. Simulations were performed at randomly drawn spatial locations and time points (within the allocated time frame). There is one output file per simulation. In each group of files, there are also three R-datasets. Two contain the post-processed, cumulated sensitivy plumes both before and after translation and rotation, and the third contains the coordinates of the spatial grid over which the simulations were performed. 

Information on how to reproduce these FLEXPART outputs can be found within the FLEXPART folder in this repository. 

#### NAME simulations

These are the cumulated sensitivity plumes from NAME, simulated over the UK and Ireland from January to April 2014. Simulations were performed every 2-hours at four measurement sites. There is one .txt file per measurement site, and per month. There are also three R-datasets. Two contain the post-processed, cumulated sensitivy plumes both before and after translation and rotation, and the third contains the coordinates of the spatial grid over which the simulations were performed.

#### R Datasets created during pre/post-processing and emulation

This file contains the remaining datasets not included in the NAME and FLEXPART files, produced at each stage in the pre/post-processing and emulation.

## Scripts

There are a number of scripts included in this repository. Further details of their purpose can be found in "readme.md" contained in the src folder of this repository. 

## To reproduce results and final plots in the paper

* Open a terminal/command line, and navigate the working directory to the "Data" folder (ensure you have downloaded and extracted the R Datasets within this folder).  
* Activate the conda environment by running 

```diff
conda activate EnvName
```

where EnvName is the name you gave your conda environment when creating it. 

* Now open "main.R" and adjust the name of the conda environment at the top of the script to match the name of your conda environment. You will also likely need to adjust the number of cores to suit the machine you are using. Save and close the file.  

* In the activated conda environment, run 

```diff
Rscript Main.R
```

to perform the emulation, Monte Carlo sampling and rotation, calculation of metrics, and production of plots. The final metrics should match those given in the paper (provided you have not retrained the CVAE), and your final plots should look like these:

<a rel="results" href="https://github.com/Lcartwright94/LPDM-Sensitivity-Emulation/blob/main/IMG/facet-503.png"><img alt="Results plot" style="border-width:0" src="https://github.com/Lcartwright94/LPDM-Sensitivity-Emulation/blob/main/IMG/facet-503.png" /></a>

<a rel="results" href="https://github.com/Lcartwright94/LPDM-Sensitivity-Emulation/blob/main/IMG/facet-503-uncertainty.png"><img alt="Results plot" style="border-width:0" src="https://github.com/Lcartwright94/LPDM-Sensitivity-Emulation/blob/main/IMG/facet-503-uncertainty.png" /></a>



## Software license

Reproducible code for "Emulation of greenhouse-gas sensitivities using variational autoencoders", by Laura Cartwright, Andrew Zammit-Mangion, and Nicholas M. Deutscher.  
Copyright (c) 2021 Laura Cartwright  
Author: Laura Cartwright (lcartwri@uow.edu.au)

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
