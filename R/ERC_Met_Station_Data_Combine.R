#R code for compiling ERC Met data

library(tidyverse)
library(openair) # timeAverage

print(sessionInfo())

print(getwd())

# read in all of the summary files to date
file.list <- list.files(path="./Current_summary_data", pattern='*.csv', full.names=TRUE)
print(length(file.list))

# function to check if csv is empty
read_csv_file <- function(file) {
  data <- read_csv(file, show_col_types=FALSE)
  if (nrow(data) == 0) {
    return(NULL)
  } else {
    return(data)
  }
}

# ensure timestamp is consistent format for date
normalize_dates <- function(df, date_col) {

  stopifnot(date_col %in% names(df))

  # Step 1: Clean and parse mixed formats
  parsed_dates <- str_trim(df[[date_col]])
  parsed_dates <- gsub(" AEST$", "", df[[date_col]])
  parsed_dates <- as.POSIXct(parsed_dates,
                             format = c("%d-%b-%y %I:%M:%S %p"),
                             tz = "Australia/Brisbane")
  df$date <- parsed_dates
  return(df)
}

# Read all CSV files and store in a list
df.list <- lapply(file.list, read_csv_file)

# bind all the data together
wrk <- bind_rows(df.list, .id = "id")

# rename columns appropriately
colnames(wrk) <- c("Data_id",
                   "timestamp",
                   "Air.Temp",
                   "RH",
                   "Dew.Point",
                   "Rainfall",
                   "Rainfall.Since.9am",
                   "Last.Hours.Evaporation",
                   "Wind.Direction",
                   "Current.Wind.Speed",
                   "Peak.Wind.Gust",
                   "Vector.Wind.Speed",
                   "Vector.Wind.Direction",
                   "Solar.Radiation")

# convert to datetime with
wrk = normalize_dates(wrk, "timestamp")

# check output
str(wrk)

# remove extraneous data from before the system was stable
wrk<-subset(wrk,date>=as.POSIXct("2021-07-20 00:00:00"))

# remove nonsense data
wrk$Solar.Radiation[wrk$Solar.Radiation >= 1500] <- NA
wrk$Air.Temp[wrk$Air.Temp >= 60|wrk$Air.Temp <= 10] <- NA

# rename datetime column to 'date' for timeAverage function 
#names(wrk)[names(wrk) == 'datetime'] <- 'date' # emg name col date initially

# workout rainfall separately
rain <- subset(wrk, select=c(date,Rainfall))
env <- subset(wrk, select=-c(timestamp,Rainfall,Rainfall.Since.9am)) # emg replace wrk varname

wrk_15min <- timeAverage(env, avg.time = "15 min", statistic = "mean")
rain_sum <- timeAverage(rain, avg.time = "15 min", statistic = "sum")

###########
## TBC need to work out how to summarize windfall
###########

# after timeAverage
str(wrk_15min)
str(rain_sum)

wrk_15min_comb <- merge(wrk_15min, rain_sum) # emg replace wrk_15min varname

# emg save 15 min data
# create timestamped filename and save output
wrk_15min_comb_filename = paste0('./ERC_Data_output/', substr(now(), 0, 10), '_Current_cleaned_15min.csv')
write.csv(wrk_15min_comb, file=wrk_15min_comb_filename, row.names=FALSE)

# plot 15min summary
png_wrk_15min_comb_filename = gsub('.csv', '_plot.png', wrk_15min_comb_filename)

png(pnd_wrk_15min_comb_filename)
print(
wrk_15min_comb %>%
  pivot_longer(cols = c(2:6), names_to = "variable", values_to = "value") %>%
    ggplot(aes(x = date, y = value, color = variable)) +
        geom_line(, show.legend = FALSE) +
        facet_wrap(~ variable, scales = "free_y") +
        theme_minimal() +
        labs(x = "Day", y = "Value")
)
dev.off()

###########
# summarize daily data sets
###########

# add column of just date (no time) to able to summarize daily
wrk_15min_comb$day <- as.POSIXct(
                strftime(wrk_15min_comb$date, format = "%Y-%m-%d %H:%M:%S"),
                format = "%Y-%m-%d")

Daily <- wrk_15min_comb %>%
  group_by(day) %>%
  summarise(
    Max_Temp = max(Air.Temp, na.rm = TRUE),
    Av_Temp = mean(Air.Temp, na.rm = TRUE),
    Min_Temp = min(Air.Temp, na.rm = TRUE),
    Radiant_exposure = sum(Solar.Radiation * 15 * 60, na.rm = TRUE) / 1000,
    Rainfall = sum(Rainfall, na.rm = TRUE),
    .groups = "drop"
)

print(warnings())

# 1: In max(Air.Temp, na.rm = TRUE) :
#   no non-missing arguments to max; returning -Inf

Daily[sapply(Daily, is.infinite)] <- NA

# create timestamped filename and save output - daily
daily_filename = paste0('./ERC_Data_output/', substr(now(), 0, 10), '_Current_cleaned_daily.csv')
write.csv(Daily, file=daily_filename, row.names=FALSE)

# plot daily
png_name_daily = gsub('.csv', '_plot.png', daily_filename)
png(png_name_daily)
print(
Daily %>%
  pivot_longer(cols = c(2:6), names_to = "variable", values_to = "value") %>%
    ggplot(aes(x = day, y = value, color = variable)) +
        geom_line(, show.legend = FALSE) +
        facet_wrap(~ variable, scales = "free_y") +
        theme_minimal() +
        labs(x = "Day", y = "Value")
)
dev.off()


