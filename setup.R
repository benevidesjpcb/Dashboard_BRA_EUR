pkgs <- c("dplyr", "tidyr", "ggplot2", "lubridate", "scales",
          "plotly", "DT", "crosstalk", "zoo", "htmltools", "knitr")
install.packages(pkgs[!pkgs %in% installed.packages()[, "Package"]])
