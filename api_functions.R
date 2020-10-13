#-------------------- setup ---------------

# check if packages are available
required_packages <- c("httr", "jsonlite", "glue", "magrittr", "lubridate")

if(any(!(required_packages %in% installed.packages()[,"Package"]))){ 
  stop(paste("Required packages are not installed on local PC:", 
             required_packages[which(!(required_packages %in% installed.packages()[,"Package"]))]))
}

library(magrittr)

# miscellaneous function to get data from path - used for further functions

get_from_path <- function(path){
  
  httr::GET(path) %>%                                   # request data from api
    httr::content(as = "text", encoding = "UTF-8") %>%  # make sure the content is encoded with 'UTF-8'
    jsonlite::fromJSON(flatten = TRUE) %>%              # now we can have a dataframe for use
    data.frame()
  
}

#--------------- lookup_country ---------------

# Function to get available countries and regions

# To get also available regions use region = TRUE

lookup_country <- function(region = TRUE){
  
  # different requests for countries alone and with regions
  path <- ifelse(region, 
                 "https://covidmap.umd.edu/api/region",
                 "https://covidmap.umd.edu/api/country")
  
  get_from_path(path)
  
}


#--------------- lookup_dates -------------------

# Function to lookup available dates of observations for country and region

# For only country e.g. - country = "Poland"
# For country and region e.g. - country = c("Poland", "Pomorskie")

lookup_dates <- function(country){
  
  # if region is also specified then country variable will be of length equal to 2
  path <- ifelse(length(country) == 1,
                 glue::glue("https://covidmap.umd.edu/api/datesavail?country={country}"),
                 glue::glue("https://covidmap.umd.edu/api/datesavail?country={country[1]}&region={country[2]}"))
  
  get_from_path(path)
}

#------------------ covid_survey -----------------

# Function to get data from World COVID-19 World Survey Data gathered by University of Maryland and Facebook

# Full list of arguments and more on API and its data here: https://covidmap.umd.edu/api.html
# tl;dr of the arguments:
# indicator - which data to use e.g. "covid", "flu", "mask", "contact" or "finance"
# type - "daily" or "smoothed"
# country - string of a country e.g. "Poland". FOR COUNTRIES WITH WORD "UNITED" USE ONLY "United%" ! (api problem)
# region - string of region of given country e.g. "Pomorskie" or c() for none
# date_range - a) single date e.g. "2020-04-30"; 
#   b) range of dates in a format like c("2020-04-30", "2020-10-01");
#   c) "all" for every available date

covid_survey <- function(indicator = "covid",
                         type = "daily", 
                         country = "all",
                         region = c(),
                         date_range = "all"){
  
  # use lookup_dates to get most recent dates if date_range == "all"
  if (date_range[1] == "all") { 
    
    date_path <- "&daterange="
    date_range <- paste(min(lookup_dates(country)$data.survey_date), "-", max(lookup_dates(country)$data.survey_date), sep = "") 
    
  } else {
    
    # change c(yyyy-mm-dd, yyyy-mm-dd) to yyyymmdd-yyyymmdd
    date_path <- ifelse(length(date_range) == 1, "&date=", "&daterange=")
    date_range <-  as.Date(date_range) %>% 
      format("%Y%m%d") %>%
      ifelse(length(date_range) == 1, ., paste(.[1], "-", .[2], sep = ""))
  }
  
  region_path <- ifelse(length(region) == 0, "", paste("&region=", region, sep = ""))
  
  # glue every parts of path
  path <- glue::glue("https://covidmap.umd.edu/api/resources?indicator={indicator}&type={type}&country={country}{region_path}{date_path}{date_range}")
  
  get_from_path(path) %>%                                                   # use pre-defined function to connect to extract data
    dplyr::mutate(data.survey_date = lubridate::ymd(data.survey_date)) %>%  # convert date
    set_colnames(stringr::str_remove(colnames(.), "data."))                 # remove "data." from column names 
}

rm(required_packages)

covid_survey(indicator = "mask", 
             type = "daily",
             country = "Poland",
             region = c(),
             date_range = "all")