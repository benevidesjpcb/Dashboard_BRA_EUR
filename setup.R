# Run this script once to install all required packages
pkgs <- c("shiny", "bslib", "dplyr", "tidyr", "ggplot2", "scales", "DT")
install.packages(pkgs[!pkgs %in% installed.packages()[, "Package"]])
