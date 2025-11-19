#R code for compiling ERC Met data

library(dplyr) # bind_rows
library(openair) # timeAverage
library(plyr) # ddply
library(lubridate) # now
library(tidyr) # pivot_longer
library(ggplot2)

print(sessionInfo())

print(getwd())

# read in all of the summary files to date
file.list <- list.files(path="./Current_summary_data", pattern='*.csv', full.names=TRUE)
print(length(file.list))

# function to check if csv is empty
read_csv_file <- function(file) {
  data <- read.csv(file)
  if (nrow(data) == 0) {
    return(NULL)
  } else {
    return(data)
  }
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
wrk$date <- as.POSIXct(strptime(wrk$timestamp, format="%d-%b-%y %I:%M:%S %p"))

# check output
str(wrk)

# remove extraneous data from before the system was stable
wrk<-subset(wrk,date>=as.POSIXct("2021-07-20 00:00:00"))
# emg remove all the older ones from directory!

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
pdf_wrk_15min_comb_filename = gsub('.csv', '_plot.pdf', wrk_15min_comb_filename)

pdf(pdf_wrk_15min_comb_filename)
wrk_15min_comb %>%
  pivot_longer(cols = c(2:6), names_to = "variable", values_to = "value") %>%
    ggplot(aes(x = date, y = value, color = variable)) +
        geom_line(, show.legend = FALSE) +
        facet_wrap(~ variable, scales = "free_y") +
        theme_minimal() +
        labs(x = "Day", y = "Value")
dev.off()

###########
# summarize daily data sets
###########

# add column of just date (no time) to able to summarize daily
wrk_15min_comb$day <- as.POSIXct(
                strftime(wrk_15min_comb$date, format = "%Y-%m-%d %H:%M:%S"),
                format = "%Y-%m-%d")

Daily<- ddply(wrk_15min_comb, .(day), summarise,
                      Max_Temp=max(Air.Temp,na.rm=TRUE),
                      Av_Temp=mean(Air.Temp,na.rm=TRUE),
                      Min_Temp=min(Air.Temp,na.rm=TRUE),
                      Radiant_exposure=sum(Solar.Radiation*15*60,na.rm=TRUE)/1000,
                      Rainfall =sum(Rainfall,na.rm=TRUE))

print(warnings())

# 1: In max(Air.Temp, na.rm = TRUE) :
#   no non-missing arguments to max; returning -Inf

Daily[sapply(Daily, is.infinite)] <- NA

# create timestamped filename and save output - daily
daily_filename = paste0('./ERC_Data_output/', substr(now(), 0, 10), '_Current_cleaned_daily.csv')
write.csv(Daily, file=daily_filename, row.names=FALSE)

# plot daily
pdf_name_daily = gsub('.csv', '_plot.pdf', daily_filename)
pdf(pdf_name_daily)
Daily %>%
  pivot_longer(cols = c(2:6), names_to = "variable", values_to = "value") %>%
    ggplot(aes(x = day, y = value, color = variable)) +
        geom_line(, show.legend = FALSE) +
        facet_wrap(~ variable, scales = "free_y") +
        theme_minimal() +
        labs(x = "Day", y = "Value")
dev.off()
