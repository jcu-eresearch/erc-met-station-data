# erc-met-station-data
R code for compiling ERC Met data

The [Environmental Research Complex](https://www.jcu.edu.au/environmental-research-complex) (ERC) is a cutting edge research facility for biological and environmental sciences at James Cook University, Cairns. Facilities include research quality growth facilities for examining the implications of climate change on tropical vegetation as well as the space and resources to conduct a diverse array of experimental projects.

## Features
- Daily cleaned datasets
- Automated summary generation
- Visual plots for temperature, humidity, etc.
- Jekyll-based website for easy browsing

## Data
A weather station inside the ERC continuously collects data about the environmental conditions:
  * Air.Temp
  * RH
  * Dew.Point
  * Rainfall
  * Rainfall.Since.9am
  * Last.Hours.Evaporation
  * Wind.Direction
  * Current.Wind.Speed
  * Peak.Wind.Gust
  * Vector.Wind.Speed
  * Vector.Wind.Direction
  * Solar.Radiation

## Methods
The data is initially cleaned and uploaded to the ERC OneDrive. When new files are pushed to this repository, it triggers a github action to execute the R summary script which produces plots and a summary csv file. The most recent outputs are presented on the github pages site.

# License
[CC BY-NC-SA](https://creativecommons.org/licenses/by-nc-sa/4.0/)
