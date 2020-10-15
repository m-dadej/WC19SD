#-------------------- setup ---------------

# check if packages are available
required_packages <- c("httr", "jsonlite", "glue", "magrittr", "lubridate")

if(any(!(required_packages %in% installed.packages()[,"Package"]))){ 
  stop(paste("Required packages are not installed on local PC:", 
             required_packages[which(!(required_packages %in% installed.packages()[,"Package"]))]))
}

library(magrittr)

#--------------- lookup_country ---------------

# Function to get available countries and regions

# To get also available regions use region = TRUE

lookup_country <- function(region = TRUE){
  
  # different requests for countries alone and with regions
  path <- ifelse(region, 
                 "https://covidmap.umd.edu/api/region",
                 "https://covidmap.umd.edu/api/country")
  
  httr::GET(path) %>%                                   # request data from api
    httr::content(as = "text", encoding = "UTF-8") %>%  # make sure the content is encoded with 'UTF-8'
    jsonlite::fromJSON(flatten = TRUE) %>%              # now we can have a dataframe for use
    data.frame()
  
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
  
  httr::GET(path) %>%                                   # request data from api
    httr::content(as = "text", encoding = "UTF-8") %>%  # make sure the content is encoded with 'UTF-8'
    jsonlite::fromJSON(flatten = TRUE) %>%              # now we can have a dataframe for use
    data.frame()
}

#------------------ covid_survey -----------------

# Function to get data from World COVID-19 World Survey Data gathered by University of Maryland and Facebook

# Full list of arguments and more on API and its data here: https://covidmap.umd.edu/api.html
# tl;dr of the arguments:
# indicator - which data to use e.g. "covid", "flu", "mask", "contact", "finance" or "all"
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
  
  # nested function to get single indicator. (API does not allow many indicators at once)
  single_indicator <- function(indicator, 
                               type,
                               country,
                               region,
                               date_range){
    
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
    
    httr::GET(path) %>%                                                       # request data from api
      httr::content(as = "text", encoding = "UTF-8") %>%                      # make sure the content is encoded with 'UTF-8'
      jsonlite::fromJSON(flatten = TRUE) %>%                                  # now we can have a dataframe for use
      data.frame() %>%                                                        # use pre-defined function to connect to extract data
      dplyr::mutate(data.survey_date = lubridate::ymd(data.survey_date)) %>%  # convert date
      set_colnames(stringr::str_remove(colnames(.), "data."))                 # remove "data." from column names 
  }
  
  # if indicator = "all" then change it to the vector of every available indicator
  suppressWarnings(indicator <- if(indicator == "all") c("covid" , "flu" , "mask" ,"contact", "finance") else indicator)
  
  # get first df (or the only one)
  df <- single_indicator(indicator = indicator[1], 
                         type = type,
                         country = country,
                         region = region,
                         date_range = date_range)
  
  # if there are more indicators specified then loop and merge with single_indicator() nested function
  if (length(indicator) != 1) {
    
    for (indic_loop in indicator[2:length(indicator)]) {
      
      # data to merge to the previous one. Also delete some repetitive variables
      df0 <- single_indicator(indicator = indic_loop, 
                              type = type,
                              country = country,
                              region = region,
                              date_range = date_range) %>%
        dplyr::select(-c("gid_0", if(length(region) != 0) {"gid_1"}, "iso_code", "sample_size", "status"))
      
      
      # join these data frames by country, survey date and conditionally by region if specified.
      # and add indicator name to variables with the same name
      df <- dplyr::inner_join(df, df0, by = c("country", if(length(region) != 0){"region"}, "survey_date"), 
                              suffix = c("", glue::glue("_{indic_loop}")))
      
    }
  }
  
  # API wrongly names contact's standard error as dc_se, should call it mc_se. 
  if (indicator[1] == "all" | "contact" %in% indicator) { df <- dplyr::rename(df, "dc_se" = "mc_se_contact") }
  
  return(df)
}

rm(required_packages)
