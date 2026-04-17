library(tidyverse)  

library(lubridate)  

library(readr)  

library(gridExtra)  

library(psych)  

library(moments) 

library(broom) 

library(ggcorrplot) 

library(scales) 

library(patchwork) 



#set the working directory 

setwd("C:/Users/nymet/OneDrive/Syracuse/Fall 2025/MAS 766/final_project") 



#prep the data for proper data types and such 

data <- read_csv("group_project_data_good.csv") %>%  
  
  mutate( 
    
    venue_name = ifelse(venue_name == "Rate Field", "Guaranteed Rate Field", venue_name), 
    
    venue_name = ifelse(venue_name == "Daikin Park", "Minute Maid Park", venue_name), 
    
  ) %>%  
  
  filter(!venue_name %in% c("Bristol Motor Speedway", "George M. Steinbrenner Field", "Journey Bank Ballpark")) %>%  
  
  mutate( 
    
    game_type = factor(game_type) %>% fct_relevel("R"), 
    
    part_of_season = factor(part_of_season) %>% fct_relevel("1"), 
    
    other_weather = factor(other_weather) %>% fct_relevel("Clear"), 
    
    venue_name = factor(venue_name) %>% fct_relevel("Citi Field"), 
    
    start_time = factor(start_time) %>% fct_relevel("7 PM"), 
    
    day_of_week = factor(day_of_week, ordered = FALSE) %>% fct_relevel("Thu"), 
    
    ln_attendance = log(attendance) 
    
  ) %>% 
  
  filter(!is.na(attendance)) 



##### Figure 1 - Distribution of Attendance ##### 

ggplot(data, aes(x = attendance)) +  
  
  geom_histogram(bins = 40, fill = "steelblue", color = "black", alpha = 0.7) +  
  
  labs(title = "Distribution of Attendance", x = "Attendance", y = "Frequency") +  
  
  theme_minimal() + 
  
  theme( 
    
    plot.title = element_text(size = 18, face = "bold"), 
    
    axis.title.x = element_text(size = 14), 
    
    axis.title.y = element_text(size = 14), 
    
    axis.text.x  = element_text(size = 12), 
    
    axis.text.y  = element_text(size = 12) 
    
  ) 



##### Figure 2 - Day of Week vs. Attendance ##### 

day_summary <- data %>%  
  
  group_by(day_of_week) %>%  
  
  summarise( Mean_Attendance = mean(attendance, na.rm = TRUE),  
             
             Median_Attendance = median(attendance, na.rm = TRUE),  
             
             SD_Attendance = sd(attendance, na.rm = TRUE),  
             
             N_Games = n(),  
             
             .groups = 'drop' ) %>%  
  
  mutate(day_of_week = factor(day_of_week,levels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"))) 



ggplot(day_summary, aes(x = day_of_week, y = Mean_Attendance, fill = day_of_week)) +  
  
  geom_bar(stat = "identity", alpha = 0.7) +  
  
  geom_errorbar(aes(ymin = Mean_Attendance - SD_Attendance, ymax = Mean_Attendance + SD_Attendance), width = 0.3) +  
  
  labs(title = "Mean Attendance by Day of Week (± 1 SD)", x = "Day of Week", y = "Mean Attendance") +  
  
  theme_minimal() +  
  
  theme( 
    
    plot.title = element_text(size = 18, face = "bold"), 
    
    axis.title.x = element_text(size = 14), 
    
    axis.title.y = element_text(size = 14), 
    
    axis.text.x  = element_text(size = 12), 
    
    axis.text.y  = element_text(size = 12) 
    
  ) +  
  
  guides(fill = "none")  



##### Figure 3 - Start Hour vs. Attendance ##### 



#temp table to order the labels for the graph 

temp <- data %>%  
  
  mutate( 
    
    start_time = factor(start_time, levels = c("11 AM", "12 PM", "1 PM", "2 PM", "3 PM", "4 PM", "5 PM", 
                                               
                                               "6 PM", "7 PM", "8 PM", "9 PM", "10 PM", "11 PM")) 
    
  ) 



ggplot(temp, aes(x = start_time, y = attendance, fill = start_time)) +  
  
  geom_boxplot(alpha = 0.7) +  
  
  labs(title = "Attendance Distribution by Game Start Hour", x = "Start Time (EST)", y = "Attendance") +  
  
  theme_minimal() +  
  
  theme( 
    
    plot.title = element_text(size = 18, face = "bold"), 
    
    axis.title.x = element_text(size = 14), 
    
    axis.title.y = element_text(size = 14), 
    
    axis.text.x  = element_text(size = 12), 
    
    axis.text.y  = element_text(size = 12) 
    
  ) +  
  
  guides(fill = "none")  



##### Prep the Building and Validation Data ##### 



#get validation data 

build_data <- data %>%  
  
  filter(year(game_date) != 2025) 



vald_data <- data %>%  
  
  filter(year(game_date) == 2025)  



#prep for later time series 

#gets the monthly average attendance for each ballpark 

avg_attendance <- data %>% 
  
  mutate( 
    
    year = year(game_date), 
    
    month = month(game_date) 
    
  ) %>% 
  
  group_by(venue_name, year, month) %>% 
  
  summarize(avg_attendance_lag = mean(attendance, na.rm = TRUE), .groups = "drop") %>% 
  
  # filter(venue_name == "Yankee Stadium") %>% 
  
  mutate(year_month = make_date(year, month, 1)) 



#adds to old dataset and removes first year with no lag 

seasonal_data_build <- build_data %>%  
  
  mutate( 
    
    prev_year = year(game_date) - 1, 
    
    month = month(game_date)) %>%  
  
  inner_join(avg_attendance, by=c("prev_year" = "year", "month"="month", "venue_name"="venue_name")) %>%  
  
  mutate( 
    
    game_type = factor(game_type) %>% fct_relevel("R"), 
    
    part_of_season = factor(part_of_season) %>% fct_relevel("1"), 
    
    other_weather = factor(other_weather) %>% fct_relevel("Clear"), 
    
    venue_name = factor(venue_name) %>% fct_relevel("Citi Field"), 
    
    start_time = factor(start_time) %>% fct_relevel("7 PM"), 
    
    day_of_week = factor(day_of_week, ordered = FALSE) %>% fct_relevel("Thu"), 
    
    ln_attendance = log(attendance) 
    
  ) 



seasonal_data_vald <- vald_data %>%  
  
  mutate( 
    
    prev_year = year(game_date) - 1, 
    
    month = month(game_date)) %>%  
  
  inner_join(avg_attendance, by=c("prev_year" = "year", "month"="month", "venue_name"="venue_name")) %>%  
  
  mutate( 
    
    game_type = factor(game_type) %>% fct_relevel("R"), 
    
    part_of_season = factor(part_of_season) %>% fct_relevel("1"), 
    
    other_weather = factor(other_weather) %>% fct_relevel("Clear"), 
    
    venue_name = factor(venue_name) %>% fct_relevel("Citi Field"), 
    
    start_time = factor(start_time) %>% fct_relevel("7 PM"), 
    
    day_of_week = factor(day_of_week, ordered = FALSE) %>% fct_relevel("Thu"), 
    
    ln_attendance = log(attendance) 
    
  ) 





##### Model 1 - Base Model ##### 



#base model, only quantitative variables 

model_1 <- lm(attendance ~ home_top_100 + away_top_100 + pre_pct_home + pre_pct_away +  
                
                temperature, data=build_data) 



r2_1 <- summary(model_1)$adj.r.squared 



##### Figure 4 - Temperature ##### 



ggplot(data, aes(x = temperature, y = attendance)) +  
  
  geom_point(alpha = 0.6, color = "steelblue") +  
  
  geom_smooth(method = "loess", se = FALSE, color = "red", linewidth = 1) + 
  
  labs( title = "Attendance vs Temperature", x = "Temperature (°F)", y = "Attendance" ) + 
  
  theme_minimal() + 
  
  theme( 
    
    plot.title = element_text(size = 18, face = "bold"), 
    
    axis.title.x = element_text(size = 14), 
    
    axis.title.y = element_text(size = 14), 
    
    axis.text.x  = element_text(size = 12), 
    
    axis.text.y  = element_text(size = 12) 
    
  )  



##### Figure 5a and 5b - Correlation ##### 



temp <- seasonal_data_build %>% 
  
  select(temperature, home_top_100, away_top_100, pre_pct_home, pre_pct_away, 
         
         division_game, al_nl_game, home_game_number, venue_name,  
         
         game_type, other_weather, start_time, day_of_week, home_game_number, avg_attendance_lag) %>% 
  
  mutate(across(where(is.factor), as.numeric)) 



#calculate correlation matrix 

cor_matrix <- cor(temp, use = "complete.obs") 



#correlation matrix plot 

ggcorrplot(cor_matrix, 
           
           hc.order = TRUE, 
           
           type = "upper", 
           
           outline.col = "white", 
           
           ggtheme = ggplot2::theme_minimal(), 
           
           colors = c("blue", "white", "red"), 
           
           lab = TRUE, 
           
           lab_size = 3) + 
  
  labs(title = "Correlation Matrix: MLB Game Data (2015-2024)", 
       
       subtitle = "Numeric Variables Only") 



#prep data for the correlation table 

temp <- data %>% 
  
  select(temperature, home_top_100, away_top_100, pre_pct_home, pre_pct_away, 
         
         division_game, al_nl_game, home_game_number, 
         
         game_type, other_weather, start_time, day_of_week, venue_name) %>% 
  
  mutate(across(where(is.factor), as.numeric)) %>% 
  
  map_dfr( 
    
    ~ tidy(cor.test(.x, data$attendance)), 
    
    .id = "Variable" 
    
  ) %>% 
  
  select( 
    
    Variable, 
    
    Correlation = estimate, 
    
    t_value = statistic, 
    
    P_Value = p.value 
    
  )     



#correlation table with Attendance 

gt(temp) %>% 
  
  tab_header( 
    
    title = "Correlation with Attendance", 
    
    subtitle = "MLB Game Data 2015-2025" 
    
  ) %>% 
  
  cols_label( 
    
    Variable = "Variable", 
    
    Correlation = "Correlation", 
    
    t_value = "T-Value", 
    
    P_Value = "P-Value" 
    
  ) %>% 
  
  fmt_number(columns = Correlation, decimals = 3) %>% 
  
  fmt_number(columns = t_value, decimals = 3) %>% 
  
  fmt_number(columns = P_Value, decimals = 3) %>% 
  
  tab_style( 
    
    style = cell_fill(color = "#4575b4"), 
    
    locations = cells_column_labels() 
    
  ) %>% 
  
  tab_style( 
    
    style = cell_text(color = "white"), 
    
    locations = cells_column_labels() 
    
  ) %>% 
  
  data_color( 
    
    columns = Correlation, 
    
    colors = scales::col_numeric( 
      
      palette = c("blue", "white", "red"),  #blue is negative, red is positive correlations 
      
      domain = c(-1, 1) 
      
    ) 
    
  ) %>% 
  
  tab_options(table.font.size = "small") 



##### Figure 6 - Continuous Variables vs. Attendance ##### 



#plots of continuous variables vs attendance 

variables <- c("home_top_100", "away_top_100", "pre_pct_home", "pre_pct_away") 



par(mfrow = c(2, 2)) 



for (i in variables) { 
  
  plot(data[[i]], data$attendance, 
       
       main = paste("Attendance vs", i), 
       
       xlab = i, 
       
       ylab = "Attendance", 
       
       pch = 19, 
       
       col = "blue", 
       
       cex = 0.5, 
       
       cex.main = 2,      
       
       cex.lab = 1.75,       
       
       cex.axis = 1.5, 
       
       ylim = c(0,60000)) 
  
  
  
  # abline(lm(attendance ~ data[[i]]), 
  
  #        col = "red", lwd = 2) 
  
} 



par(mfrow = c(1, 1)) 



##### Figure 7 - Continuous Variables vs. Residuals of Base Model ##### 

#plots of continuous variables vs residuals 

variables <- c("home_top_100", "away_top_100", "pre_pct_home", "pre_pct_away") 



par(mfrow = c(2, 2)) 



for (i in variables) { 
  
  model <- lm(build_data$attendance ~ build_data[[i]]) 
  
  residuals <- resid(model_1) 
  
  plot(build_data[[i]], residuals, 
       
       main = paste("Residuals vs", i), 
       
       xlab = i, 
       
       ylab = "Residuals", 
       
       pch = 19, 
       
       col = "blue", 
       
       cex = 0.5, 
       
       cex.main = 2,      
       
       cex.lab = 1.6,       
       
       cex.axis = 1.5, 
       
       ylim = c(-40000,40000)) 
  
  
  
  # abline(lm(attendance ~ data[[i]]), 
  
  #        col = "red", lwd = 2) 
  
} 



par(mfrow = c(1, 1)) 

##### Model 2 - Logging Attendance ##### 

model_2 <- lm(ln_attendance ~ home_top_100 + away_top_100 + pre_pct_home + pre_pct_away +  
                
                temperature, data=build_data) 



r2_2 <- summary(model_2)$adj.r.squared  



r2_2 >= r2_1 #doesn't improve so don't log 



##### Model 3 - Stepwise Addition of Categorical Variables ##### 



#add in the categorical and dummy variables 

#did this one by one but they all improved, other than the COVID dummy variable 

model_3 <- lm(attendance ~ home_top_100 + away_top_100 + pre_pct_home + pre_pct_away +  
                
                temperature + other_weather + division_game + al_nl_game + game_type +  
                
                venue_name + day_of_week + start_time, data=build_data) 



r2_3 <- summary(model_3)$adj.r.squared  

r2_3 >= r2_2 #improvement 



##### Model 4 - Squaring Temperature ##### 

model_4 <- lm(ln_attendance ~ home_top_100 + away_top_100 + pre_pct_home + pre_pct_away +  
                
                temperature + I(temperature) + other_weather + division_game + al_nl_game + game_type +  
                
                venue_name + day_of_week + start_time, data=build_data) 



r2_4 <- summary(model_4)$adj.r.squared  

r2_4 >= r2_3 #doesn't improve so don't squared 



##### Model 5 - Adding in the Home Game Number ##### 

model_5 <- lm(attendance ~ home_top_100 + away_top_100 + pre_pct_home + pre_pct_away +  
                
                temperature + other_weather + division_game + al_nl_game + game_type +  
                
                venue_name + day_of_week + start_time + home_game_number, data=build_data) 



r2_5 <- summary(model_5)$adj.r.squared  



r2_5 >= r2_4 #improves so keep 

##### Model 6 - Interaction of Home Game Number and Divisional Game Dummy ##### 

model_6 <- lm(attendance ~ home_top_100 + away_top_100 + pre_pct_home + pre_pct_away +  
                
                temperature + other_weather + division_game + al_nl_game + game_type +  
                
                venue_name + day_of_week + start_time  + home_game_number + 
                
                home_game_number*division_game, data = seasonal_data_build) 



r2_6 <- summary(model_6)$adj.r.squared  

r2_6 >= r2_5 #improves so keep 



##### Figure 8 - Seasonality Example Graph ##### 



#yankee stadium plot 

temp <- data %>%  
  
  mutate( date = mdy(game_date), year = year(game_date), month = month(game_date) ) %>%  
  
  group_by(venue_name, year, month) %>%  
  
  summarize(attendance = mean(attendance), .groups = "drop") %>%  
  
  filter(venue_name == "Citi Field") %>%  
  
  mutate(year_month = make_date(year, month, 1))  



label_months <- temp %>%  
  
  filter(month(year_month) %in% c(4, 9)) %>%  
  
  pull(year_month)  



ggplot(temp, aes(x = year_month, y = attendance)) + geom_line(linewidth = 1.1, color = "steelblue") +  
  
  geom_point(size = 2, color = "steelblue") +  
  
  labs( title = "Monthly Average Attendance at Yankee Stadium", x = "Month", y = "Average Attendance" ) +  
  
  scale_x_date( labels = date_format("%b %Y"), breaks = label_months ) +  
  
  theme_minimal() +  
  
  theme( 
    
    plot.title = element_text(size = 18, face = "bold"), 
    
    axis.title.x = element_text(size = 14), 
    
    axis.title.y = element_text(size = 14), 
    
    axis.text.x  = element_text(size = 12, angle = 45, hjust = 1), 
    
    axis.text.y  = element_text(size = 12), 
    
  )  





##### Model 7 - Seasonal Lag ##### 

model_7 <- lm(attendance ~ home_top_100 + away_top_100 + pre_pct_home + pre_pct_away +  
                
                temperature + other_weather + division_game + al_nl_game + game_type +  
                
                venue_name + day_of_week + start_time  +  
                
                home_game_number*division_game + home_game_number + avg_attendance_lag, data = seasonal_data_build) 



r2_7 <- summary(model_7)$adj.r.squared  

r2_7 >= r2_6 #improves so keep 



##### Figure 9 a and b - Game Number Relationship ##### 



scatter_plot <- ggplot(seasonal_data_build, aes(x = home_game_number, y = attendance)) + 
  
  geom_point(color = "blue", size = 1.5) + 
  
  labs(title = "Attendance vs Game Number", 
       
       x = "Game Number", 
       
       y = "Attendance") + 
  
  ylim(0, 60000) + 
  
  theme_minimal() + 
  
  theme( 
    
    plot.title = element_text(size = 18), 
    
    axis.title = element_text(size = 16), 
    
    axis.text = element_text(size = 14) 
    
  ) 



# 2. Average attendance line plot 

avg_temp <- data %>%  
  
  group_by(home_game_number) %>%  
  
  summarize(avg_attendance = mean(attendance), .groups = "drop") 



line_plot <- ggplot(avg_temp, aes(x = home_game_number, y = avg_attendance)) + 
  
  geom_line(linewidth = 1.1, color = "blue") + 
  
  geom_point(size = 2, color = "blue") + 
  
  labs(title = "Average Attendance per Game Number", 
       
       x = "Game Number", 
       
       y = "Average Attendance") + 
  
  theme_minimal() + 
  
  theme(plot.title = element_text(size = 18), 
        
        axis.title = element_text(size = 16), 
        
        axis.text = element_text(size = 14)) 



# 3. Combine side by side 

scatter_plot + line_plot 



##### Model 8 - Cubing the Game Number Variable ##### 

model_8 <- lm(attendance ~ home_top_100 + away_top_100 + pre_pct_home + pre_pct_away +  
                
                temperature + other_weather + division_game + al_nl_game + game_type +  
                
                venue_name + day_of_week + start_time  +  
                
                home_game_number*division_game + home_game_number + I(home_game_number^2) +  
                
                I(home_game_number^3) + avg_attendance_lag, data = seasonal_data_build) 



r2_8 <- summary(model_8)$adj.r.squared  

r2_8 >= r2_7 #improves so keep 



##### Model Evaluation Metrics ##### 



#predictions 

preds_1 <- predict(model_1, vald_data) 

preds_2 <- predict(model_2, vald_data) 

preds_3 <- predict(model_3, vald_data) 

preds_4 <- predict(model_4, vald_data) 

preds_5 <- predict(model_5, vald_data) 

preds_6 <- predict(model_6, seasonal_data_vald) 

preds_7 <- predict(model_7, seasonal_data_vald) 

preds_8 <- predict(model_8, seasonal_data_vald) 



#errors 

error_1 <- vald_data$attendance - preds_1 

error_2 <- vald_data$attendance - preds_2 

error_3 <- vald_data$attendance - preds_3 

error_4 <- vald_data$attendance - preds_4 

error_5 <- vald_data$attendance - preds_5 

error_6 <- seasonal_data_vald$attendance - preds_6 

error_7 <- seasonal_data_vald$attendance - preds_7 

error_8 <- seasonal_data_vald$attendance - preds_8 



#mse and mae for each model 

mse_1  <- mean(error_1^2) 

mae_1  <- mean(abs(error_1)) 

evaluation_1 <- c(mse_1, mae_1, r2_1) 



mse_2  <- mean(error_2^2) 

mae_2  <- mean(abs(error_2)) 

evaluation_2 <- c(mse_2, mae_2, r2_2) 



mse_3  <- mean(error_3^2) 

mae_3  <- mean(abs(mse_3)) 

evaluation_3 <- c(mse_2, mae_3, r2_3) 



mse_4  <- mean(error_4^2) 

mae_4  <- mean(abs(error_4)) 

evaluation_4 <- c(mse_4, mae_4, r2_4) 



mse_5  <- mean(error_5^2) 

mae_5  <- mean(abs(error_5)) 

evaluation_5 <- c(mse_5, mae_5, r2_5) 



mse_6  <- mean(error_6^2) 

mae_6  <- mean(abs(error_6)) 

evaluation_6 <- c(mse_6, mae_6, r2_6) 



mse_7  <- mean(error_7^2) 

mae_7  <- mean(abs(error_7)) 

evaluation_7 <- c(mse_7, mae_7, r2_7) 



mse_8  <- mean(error_8^2) 

mae_8  <- mean(abs(error_8)) 

evaluation_8 <- c(mse_8, mae_8, r2_8) 



rows <- c("MSE", "MAE", "R^2") 

eval_df <- data.frame(evaluation_1, evaluation_2, evaluation_3, evaluation_4, evaluation_5, 
                      
                      evaluation_6, evaluation_7, evaluation_8, row.names = rows) 



#put in dataframe 

eval_df <- format(round(eval_df, 3), big.mark = ",") 

eval_df 



##### Final Model Results ##### 



# for visualisation purposes in the paper and slideshow, the tables having these results 

# were not made in R, and were instead created in excel 



summary(model_8) 

f_stat <- summary(model_8)$fstatistic 



##### 

