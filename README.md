# erc-met-station-data
R code for compiling ERC Met data

The [Environmental Research Complex](https://www.jcu.edu.au/environmental-research-complex) (ERC) is a cutting edge research facility for biological and environmental sciences at James Cook University, Cairns. Facilities include research quality growth facilities for examining the implications of climate change on tropical vegetation as well as the space and resources to conduct a diverse array of experimental projects.

## Features
- Daily cleaned datasets
- Automated summary generation
- Visual plots for temperature, humidity, etc.
- Jekyll-based website for easy browsing

## Data
The Environdata Weather Master 3000 is an automatic weather station designed to suit a variety research, agricultural, commercial and industrial applications.  Its powerful data logger is able to perform complex calculations along with remote communications. Data collected include:
  * Air.Temp (°C)
  * Relative.Humidity (%RH)
  * Dew.Point (°C)
  * Rainfall (mm)
  * Rainfall.Since.9am (mm)
  * Last.Hours.Evaporation (mm)
  * Wind.Direction (deg)
  * Current.Wind.Speed (km/hr)
  * Peak.Wind.Gust (km/hr)
  * Vector.Wind.Speed (km/hr)
  * Vector.Wind.Direction (deg)
  * Solar.Radiation (W-hr/m^2)

## Methods
The data is initially cleaned by Bonlec and emailed to the ERC who adds the new csv data to exising OneDrive folders. When new files are pushed to this repository, it triggers a github action to execute [Alex Cheeseman](https://portfolio.jcu.edu.au/researchers/alex.cheesman)'s R summary script which produces plots and a combined summary csv file.

# License
[CC BY-NC-SA](https://creativecommons.org/licenses/by-nc-sa/4.0/)
