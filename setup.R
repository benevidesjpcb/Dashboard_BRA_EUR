pkgs <- c("shiny", "bslib", "dplyr", "tidyr", "ggplot2", "lubridate",
          "scales", "DT", "zoo")
install.packages(pkgs[!pkgs %in% installed.packages()[, "Package"]])
