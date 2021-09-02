# LPDM-Sensitivity-Emulation

This repository contains a number of datasets and accompanying scripts required to reproduce results presented in "Emulation of greenhouse-gas sensitivities using variational autoencoders", by Laura Cartwright, Andrew Zammit-Mangion, and Nicholas M. Deutscher.

All scripts (except one shell script) are written in [R](https://www.r-project.org/), specifically, R 3.6.3. The easiest way to run them (and the way described below) is via the terminal/command line, and using the Conda environment included in this repository. The scripts can also easily be run via [RStudio](https://www.rstudio.com/). Note you must download and install R before RStudio.

## Downloading the repository

This can either be done by clicking the green "Clone or download" button, or by running the following in the command line/terminal:

git clone https://github.com/Lcartwright94/LPDM-Sensitivity-Emulator

## Creating the Conda environment

First ensure you have installed [Conda](https://docs.anaconda.com/anaconda/install/index.html). Then, check that the file "conda-environment.yml" has been downloaded when you cloned the repository. From a terminal/command line, run 

```diff
conda env create -n EnvName -f conda-environment.yml 
```

where "EnvName" is the name of the conda environment.

## Data files

There are a number of data files which accompany the scripts in this repository. They are broken into three groups: 

### FLEXPART simulations

### NAME simulations

### R Datasets created during pre/post-processing and emulation

## To reproduce results and final plots in the paper

* Open a terminal/command line, and navigate the working directory to the "Data" folder (ensure you have downloaded and extracted the R Datasets within this folder).  
* Activate the conda environment by running 

```diff
conda activate EnvName
```

where EnvName is the name you gave your conda environment when creating it. 

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


## Data license

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br />All data in this repository is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a> (Geoscience Australia).

