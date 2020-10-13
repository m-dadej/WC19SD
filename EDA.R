library(ggplot2)
library(hrbrthemes)
library(gridExtra)
library(cowplot)
library(tidyverse)

#covid , flu , mask ,contact or finance
caption <- "twitter: @mateusz_dadej | ¬ród³o: COVID-19 World Survey API | ¶rednia dzienna ilo¶æ respondentów to ~ 2000"

'%!in%' <- Negate('%in%')

source("api_functions.R")

#----------------- covid -----------------

df_covid <- covid_survey(indicator = "covid", 
                         type = "daily",
                         country = "Poland",
                         region = "all",
                         date_range = "all")

df_covid_total <- covid_survey(indicator = "covid", 
                               type = "daily",
                               country = "Poland",
                               region = c(),
                               date_range = "all")


cli_plot <- select(df_covid, region, survey_date, percent_cli) %>%
              filter(region %!in% c("Warmiñsko-Mazurskie", "Lubelskie", "Lubuskie", "Podkarpackie")) %>%
              pivot_longer(cols = -c(region, survey_date)) %>%
                ggplot(aes(x = survey_date, y = value, color = region )) +
                geom_point(size = 0.8) +
                geom_smooth(span = 1, alpha = 0.5) +
                scale_y_continuous(labels = scales::percent) +
                theme_minimal() +
                labs(title = "Ile osób deklarujê objawy COVID-19?", subtitle = "Procent osób deklaruj±ca objawy COVID-19 (ang. COVID-like-ilness). Wed³ug ankiety COVID-19 World Survey publikowanej na facebook'u",
                     caption = caption, x = "", y = "") +
                scale_colour_viridis_d(option = "D") +
                facet_wrap(~ region) +
                theme(plot.margin = unit(c(1,1,1,1), "cm"), legend.position = "none")


covid_plot1 <- ggplot(df_covid_total) +
                geom_line(aes(x = survey_date, y = percent_cli)) +
                geom_ribbon(aes(x = survey_date, ymin = percent_cli - cli_se, ymax = percent_cli + cli_se),
                            alpha = 0.4, fill = "steelblue3") +
                scale_y_continuous(labels = scales::percent) +
                labs(title = "Ile osób deklarujê objawy COVID-19?", 
                     subtitle = "Procent osób deklaruj±ca objawy COVID-19 (ang. COVID-like-ilness). Wed³ug ankiety COVID-19 World Survey publikowanej na facebook'u.",
                     y = "", x = "") +
                theme_minimal()


covid_plot2 <- ggplot(df_covid_total) +
  geom_area(aes(x = survey_date, y = sample_size), alpha = 0.5, fill = "steelblue3") +
  labs(caption = caption,
       x = "", y = "n respondentów") +
  theme_minimal()

cli_plot_total <- plot_grid(covid_plot1, covid_plot2, rel_heights = c(1/2, 1/2.5), align = "v", nrow = 2) +
                    theme(plot.margin = unit(c(1,1,1,1), "cm"))


#-------------------- flu ----------------------


df_finance <- covid_survey(indicator = "finance", 
                           type = "daily",
                           country = "Poland",
                           region = "all",
                           date_range = "all")

df_finance_total <- covid_survey(indicator = "finance", 
                                 type = "daily",
                                 country = "Poland",
                                 region = c(),
                                 date_range = "all")%>%
                            filter(percent_hf != 0)

finance_plot <- select(df_finance, region, survey_date, percent_hf) %>%
                  filter(region %!in% c("Warmiñsko-Mazurskie", "Lubelskie", "Lubuskie", "Podkarpackie")) %>%
                  pivot_longer(cols = -c(region, survey_date)) %>%
                    ggplot(aes(x = survey_date, y = value, color = region )) +
                    geom_point(size = 0.8) +
                    geom_smooth(span = 1, alpha = 0.5) +
                    scale_y_continuous(labels = scales::percent) +
                    theme_minimal() +
                    labs(title = "Ile osób deklarujê objawy COVID-19?", subtitle = "Procent osób deklaruj±ca objawy COVID-19 (ang. COVID-like-ilness). Wed³ug ankiety COVID-19 World Survey publikowanej na facebook'u",
                         caption = caption, x = "", y = "") +
                    scale_colour_viridis_d(option = "D") +
                    facet_wrap(~ region) +
                    theme(plot.margin = unit(c(1,1,1,1), "cm"), legend.position = "none")


finance_plot_total1 <- ggplot(df_finance_total) +
                        geom_line(aes(x = survey_date, y = percent_hf)) +
                        geom_ribbon(aes(x = survey_date, ymin = percent_hf - hf_se, ymax = percent_hf + hf_se),
                                    alpha = 0.4, fill = "steelblue3") +
                        scale_y_continuous(labels = scales::percent) +
                        labs(title = "Ile osób deklarujê objawy COVID-19?", 
                             subtitle = "Procent osób deklaruj±ca objawy COVID-19 (ang. COVID-like-ilness). Wed³ug ankiety COVID-19 World Survey publikowanej na facebook'u. Niebieskie przedzia³y to b³±d standardowy",
                             y = "", x = "") +
                        theme_minimal()


finance_plot_total2 <- ggplot(df_finance_total) +
                        geom_area(aes(x = survey_date, y = sample_size), alpha = 0.5, fill = "steelblue3") +
                        labs(caption = caption,
                             x = "", y = "n respondentów") +
                        theme_minimal()

finance_plot_total <- plot_grid(covid_plot1, covid_plot2, rel_heights = c(1/2, 1/2.5), align = "v", nrow = 2) +
                        theme(plot.margin = unit(c(1,1,1,1), "cm"))

#----------------- masks -----------------

df_mask <- covid_survey(indicator = "mask", 
                        type = "daily",
                        country = "Poland",
                        region = "all",
                        date_range = "all")

df_mask_total <- covid_survey(indicator = "mask", 
                              type = "daily",
                              country = "Poland",
                              region = c(),
                              date_range = "all")

# grid z procentami ile osob nosi maski w roznych województwach

masks_plot <- select(df_mask, region, survey_date, percent_mc) %>%
                filter(region != "Lubuskie") %>%
                pivot_longer(cols = -c(region, survey_date)) %>%
                  ggplot(aes(x = survey_date, y = value, color = region )) +
                  geom_point(size = 0.8) +
                  geom_smooth(span = 1, alpha = 0.5) +
                  scale_y_continuous(labels = scales::percent) +
                  theme_minimal() +
                  labs(title = "Ile osób nosi maski?", subtitle = "Procent osób deklaruj±ca korzystanie z masek. Wed³ug ankiety COVID-19 World Survey publikowanej na facebook'u",
                       caption = caption, x = "", y = "") +
                  scale_colour_viridis_d(option = "D") +
                  facet_wrap(~ region) +
                  theme(plot.margin = unit(c(1,1,1,1), "cm"), legend.position = "none")


masks_plot1 <-  ggplot(df_mask_total) +
                  geom_line(aes(x = survey_date, y = percent_mc)) +
                  geom_ribbon(aes(x = survey_date, ymin = percent_mc - mc_se, ymax = percent_mc + mc_se),
                              alpha = 0.4, fill = "steelblue3") +
                  scale_y_continuous(labels = scales::percent) +
                  labs(title = "Procent osób deklaruj±cych korzystanie z maski ochronnej", 
                       subtitle = "Wed³ug ankiety COVID-19 World Survey publikowanej na facebook'u. niebieskie t³o to b³±d standardowy.",
                       y = "", x = "") +
                  theme_minimal()


masks_plot2 <- ggplot(df_mask_total) +
  geom_area(aes(x = survey_date, y = sample_size), alpha = 0.5, fill = "steelblue3") +
  labs(caption = caption,
       x = "", y = "n respondentów") +
  theme_minimal()

masks_plot_total <- plot_grid(masks_plot1, masks_plot2, rel_heights = c(1/2, 1/2.5), align = "v", nrow = 2) +
                      theme(plot.margin = unit(c(1,1,1,1), "cm"))