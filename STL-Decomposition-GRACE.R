# Library ----
## Uncomment install.packages() to install
# install.packages("ggfortify")
# install.packages("xts")
# install.packages("stats")
# install.packages("tidyr")
# install.packages("ggplot2")
# install.packages("reshape2")
# install.packages("car")
# install.packages("dplyr")
# install.packages("lubridate")
# install.packages("purrr")
# install.packages("sf")
# install.packages("zoo")
# install.packages("mblm")
library(ggfortify)
library(xts)
library(stats)
library(tidyr)
library(ggplot2)
library(reshape2)
library(car)
library(dplyr)
library(lubridate)
library(purrr)
library(sf)
library(zoo)
library(mblm)

# Set directory ----
setwd("D:\\01. RIZKA\\Repo__GitHub\\1_STL")

# Call hydrology data ----
## Data is in CSV 
grace_gsfc <- read.csv(file = "GRACE-GSFC_2002.04_2017.06.csv", sep=",")

## View data structure
str(grace_gsfc)

## Convert 'time' column into Date format
grace_gsfc$time <- as.Date(grace_gsfc$time)

## View first 5 rows and last 5 rows of data
head(grace_gsfc)
tail(grace_gsfc)

# Create time-series object ----
## Find unique grids (longitude-latitude pairs)
unique_coords <- unique(coredata(grace_gsfc)[,c("lon","lat")])
nrow(unique_coords)

## Create an empty list to store the results of time-series object of each grid
ts_list <- list()

## Create time-series object for each grid
for (i in 1:nrow(unique_coords)) {
  
  # Read unique longitude-latitude pairs
  lon_val <- unique_coords[i, "lon"]
  lat_val <- unique_coords[i, "lat"]
  
  # Create grid data from DataFrame
  grid_data <- grace_gsfc[grace_gsfc$lon == lon_val & grace_gsfc$lat == lat_val, ]
  
  # Create time-series object for each grid
  StartYear <- 2002 # Adjustable
  StartMonth <- 4   
  ts_data <- ts(data = coredata(grid_data[, 4]), 
                # 4 is the column of variable that will be decomposed
                start = c(2002, 4), 
                frequency = 12) 
  
  # Store time-series object
  ts_list[[paste(lon_val, lat_val, sep = "_")]] <- ts_data
}

## Example of time-series object format of the first longitude-latitude pair from the ts_list
ts_list[1]

# STL decomposition ----
## Create an empty list to store the results of STL decomposition of each grid
stl_list <- list()

# STL decomposition
for (key in names(ts_list)) {
  
  # Extract ts object from each grid (key) 
  ts_data <- ts_list[[key]]
  
  # Decomposition
  fit <- stl(ts_data, s.window = "periodic")
  
  # Store the results of decomposition
  stl_list[[key]] <- fit
}

## Example of a visualization of decomposed signals from the first lon-lat pair in the stl_list
autoplot(object = stl_list[1],ncol = 1)

# Convert stl_list to DataFrame ----
## Extract decomposition results
for (key in names(stl_list)) {
  
  # Call each grid's decomposed signal
  fit <- stl_list[[key]]
  
  # Extract each component
  trend <- fit$time.series[, "trend"]
  seasonal <- fit$time.series[, "seasonal"]
  remainder <- fit$time.series[, "remainder"]
}

## Create an empty list to store the DataFrame 
df_list <- list()

## Convert to DataFrame
for (key in names(stl_list)) {
  
  # Set key column from longitude-latitude
  lon_lat <- unlist(strsplit(key, "_"))
  lon <- as.numeric(lon_lat[1])
  lat <- as.numeric(lon_lat[2])
  
  # Call each grid's decomposed signal
  fit <- stl_list[[key]]
  
  # Create time index
  time_index <- as.Date(as.yearmon(time(fit$time.series)))
  
  # Create a DataFrame
  temp_df <- data.frame(
    time = time_index,
    lon = lon,
    lat = lat,
    trend = as.numeric(fit$time.series[, "trend"]),
    seasonal = as.numeric(fit$time.series[, "seasonal"]),
    remainder = as.numeric(fit$time.series[, "remainder"])
  )
  
  # Append the dataframe to the list
  df_list[[key]] <- temp_df
}

# Combine decomposed signals with the original hydrology signal ----
## Merge all lists in df_list into a DataFrame
final_df <- do.call(rbind, df_list)

## Combine
grace_gsfc_decomposed <- merge(final_df, grace_gsfc, by=c("lon","lat","time"))

## View first 5 rows and last 5 rows of grace_gsfc_decomposed
head(grace_gsfc_decomposed)
tail(grace_gsfc_decomposed)