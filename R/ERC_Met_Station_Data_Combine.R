#R code for compiling ERC Met data

library(dplyr) # bind_rows
library(openair) # timeAverage
library(lubridate) # now

print(sessionInfo())

print(getwd())

# read in all of the summary files to date
file.list <- list.files(path="./Current_summary_data", pattern='*.csv', full.names=TRUE)
print(length(file.list))

read_and_correct <- function(file) {
    df <- read.csv(file)

    # Convert logical columns to character (if necessary)
    df <- df %>%
        mutate_if(is.logical, as.character)

    return(df)
}

read_and_convert_to_character <- function(file) {
    df <- read.csv(file)

    # Convert all columns to character
    df <- df %>%
        mutate_all(as.character)

    return(df)
}


# Read all CSV files and store in a list
df.list <- lapply(file.list, read.csv)
#or
df.list <- lapply(file.list, read_and_correct)
#or
df.list<-lapply(file.list,read_and_convert_to_character)

#bind all the data together
wrk <- bind_rows(df.list, .id = "id")

#rename columns appropriately
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
str(wrk)
wrk <- wrk %>%
    mutate_at(vars(3:14), as.numeric)

#convert to datetime with
wrk$datetime <- as.POSIXct(strptime(wrk$timestamp, format="%d-%b-%y %I:%M:%S %p"))

# check output
str(wrk)

#convert anything that should be numeric
#wrk$Air.Temp <- as.numeric(paste(wrk$Air.Temp)) # emg already numeric

#remove extraneous data from before the system was stable
wrk<-subset(wrk,datetime>=as.POSIXct("2021-07-20 00:00:00"))

#remove nonsense data
wrk$Solar.Radiation[wrk$Solar.Radiation >= 1500] <- NA
wrk$Air.Temp[wrk$Air.Temp >= 60|wrk$Air.Temp <= 10] <- NA

#summarize to 5min data
names(wrk)[names(wrk) == 'datetime'] <- 'date'

print('after summarize to 5min...')
str(wrk)

#workout rainfall separately
rain <- subset(wrk, select=c(date,Rainfall))
wrk <- subset(wrk, select=-c(timestamp,Rainfall,Rainfall.Since.9am))

wrk_15min <- timeAverage(wrk, avg.time = "15 min", statistic = "mean")
rain_sum <- timeAverage(rain, avg.time = "15 min", statistic = "sum")

# after timeAverage
str(wrk_15min)
str(rain_sum)

wrk_15min <- merge(wrk_15min, rain_sum)

#Summarize daily data sets # emg removed daily section of code
# add column of just date (not time)
wrk_15min$day <- as.POSIXct(
                strftime(wrk_15min$date, format = "%Y-%m-%d %H:%M:%S"),
                format = "%Y-%m-%d")

# view output
print('after smmarize daily...')
str(wrk_15min)

print(warnings())

# create timestamped filename and save output
ts_filename = paste0('ERC_Data_output/Current_cleaned_dplyr190_',
                     substr(now(), 0, 10), '.csv')
write.csv(wrk_15min, file=ts_filename, row.names=FALSE)

head(wrk_15min)
library(ggplot2)
library(plotly)
plot<-ggplot()+
    geom_line(data=wrk_15min,aes(x=date,y=Air.Temp))+
    scale_y_continuous(limits=c(0,45))
ggplotly(plot)
