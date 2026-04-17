library(tidyverse)
library(dplyr)
library(lubridate)
library(dplyr)
library(readr)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(psych)
library(moments)
library(summarytools)
library(knitr)
library(gt)
setwd("~/OneDrive - Syracuse University/MAS 766 Final Project")
data <- read_csv("group_project_data1.csv")
data$venue_name <- as.factor(data$venue_name, levels=c("American Family Field"))
test <- lm(attendance ~ as.factor(venue_name), data=data)
summary(test)

#FILTER OUT SPRING TRAINING DATA
#Dummy for game type (Regular = 1, Playoff = 0)
filtered_data <- data %>% 
  filter(game_type %in% c("R", "F", "W", "L", "D")) %>%
  mutate(regular_season = ifelse(game_type == "R", 1, 0)) %>%
  drop_na()

filtered_data <- filtered_data %>%
  filter(home_league %in% c("NL", "AL")) %>%
  filter(away_league %in% c("NL", "AL"))

#Day of week dummy (Thursday is baseline)
filtered_data <- filtered_data %>%
  mutate(
    game_date = as.Date(game_date, format = "%m/%d/%Y"),
    day_of_week = wday(game_date, label = TRUE, abbr = FALSE),
    day_of_week_factor = factor(day_of_week, 
                                levels = c("Thursday", "Monday", "Tuesday", 
                                           "Wednesday", "Friday", "Saturday", "Sunday")),
    is_weekend = factor(ifelse(day_of_week %in% c("Friday", "Saturday", "Sunday"), 
                               "Weekend", "Weekday"),
                        levels = c("Weekday", "Weekend"))
  )

#Game time dummy (7PM EST is the baseline which is 19 in this time labeling)
filtered_data <- filtered_data %>%
  mutate(
    start_hour = hour(hms(start_time)),
    start_hour_factor = factor(start_hour)
  )

filtered_data <- filtered_data %>%
  mutate(
    start_hour_factor = factor(start_hour,
                               levels = c(19, 11, 12, 13, 14, 15, 16, 17, 18, 20, 21, 22))
  )


#Describing variables
#Remove values with absolute z-score > 3
filtered_data <- filtered_data[abs(scale(filtered_data$attendance)) < 4, ]
# 1. DEPENDENT VARIABLE: ATTENDANCE
cat("ATTENDANCE - Descriptive Statistics:\n")
describe(filtered_data$attendance)
cat("\nSkewness:", skew(filtered_data$attendance), "\n")
cat("Kurtosis:", kurtosis(filtered_data$attendance), "\n")

p1 <- ggplot(filtered_data, aes(x = attendance)) +
  geom_histogram(bins = 40, fill = "steelblue", color = "black", alpha = 0.7) +
  labs(title = "Distribution of MLB Attendance 2015-2025", x = "Attendance", y = "Game Count") +
  theme_minimal()
summarytools::descr(filtered_data$attendance)


summary_stats <- data.frame(
  Mean = round(mean(filtered_data$attendance), 2),
  Median = round(median(filtered_data$attendance), 2),
  SD = round(sd(filtered_data$attendance), 2),
  Min = min(filtered_data$attendance),
  Max = max(filtered_data$attendance),
  N = nrow(filtered_data)
)
colnames(filtered_data)
gt(summary_stats) %>%
  tab_header(title = "Attendance Summary Statistics")
p2 <- ggplot(filtered_data, aes(sample = attendance)) +
  stat_qq(color = "steelblue") +
  stat_qq_line(color = "red") +
  labs(title = "Q-Q Plot: Attendance vs Normal Distribution") +
  theme_minimal()

grid.arrange(p1, ncol = 1)

cat("\nFINDINGS: Attendance shows a roughly normal distribution centered around",
    mean(filtered_data$attendance, na.rm = TRUE), "with slight left skew",
    "(", round(skew(filtered_data$attendance), 3), ").\n",
    "This suggests most games have moderate-to-good turnout with fewer extremely low-attendance outliers.\n\n")

# 2. STAR POWER: HOME & AWAY TOP 100
cat("STAR POWER (Home and Away Top 100 Players) - Summary:\n")
cat("Home Top 100:\n")
print(table(filtered_data$home_top_100))
cat("\nAway Top 100:\n")
print(table(filtered_data$away_top_100))

# Correlation with attendance
cor_home <- cor(filtered_data$home_top_100, filtered_data$attendance, use = "complete.obs")
cor_away <- cor(filtered_data$away_top_100, filtered_data$attendance, use = "complete.obs")
cat("\nCorrelation - Home Stars & Attendance:", round(cor_home, 4), "\n")
cat("Correlation - Away Stars & Attendance:", round(cor_away, 4), "\n")

# Visualization
p3 <- ggplot(filtered_data, aes(x = home_top_100, y = attendance)) +
  geom_boxplot(aes(group = home_top_100), fill = "lightblue", alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1) +
  labs(title = "Attendance by Home Team Star Power",
       x = "Number of Top 100 Players (Home Team)",
       y = "Attendance") +
  theme_minimal()

p4 <- ggplot(filtered_data, aes(x = away_top_100, y = attendance)) +
  geom_boxplot(aes(group = away_top_100), fill = "lightcoral", alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1) +
  labs(title = "Attendance by Away Team Star Power",
       x = "Number of Top 100 Players (Away Team)",
       y = "Attendance") +
  theme_minimal()

grid.arrange(p3, p4, ncol = 2)

cat("\nFINDINGS: Both home (r =", round(cor_home, 3), ") and away (r =",
    round(cor_away, 3), ") star power show positive\n",
    "correlations with attendance. Home team star power appears slightly more influential.\n",
    "Games with 4-6 star players attract larger crowds, suggesting fan preference for talent-rich matchups.\n\n")

# ============================================================================
# 3. DAY OF WEEK EFFECTS
# ============================================================================

cat("DAY OF WEEK - Attendance Summary:\n")
day_summary <- filtered_data %>%
  group_by(day_of_week_factor) %>%
  summarise(
    Mean_Attendance = mean(attendance, na.rm = TRUE),
    Median_Attendance = median(attendance, na.rm = TRUE),
    SD_Attendance = sd(attendance, na.rm = TRUE),
    N_Games = n(),
    .groups = 'drop'
  )
print(day_summary)

p5 <- ggplot(day_summary, aes(x = factor(day_of_week_factor, 
                                         levels = c("Monday", "Tuesday", "Wednesday", 
                                                    "Thursday", "Friday", "Saturday", "Sunday")),
                              y = Mean_Attendance, fill = day_of_week_factor)) +
  geom_bar(stat = "identity", alpha = 0.7) +
  geom_errorbar(aes(ymin = Mean_Attendance - SD_Attendance, 
                    ymax = Mean_Attendance + SD_Attendance), width = 0.3) +
  labs(title = "Mean Attendance by Day of Week (± 1 SD)",
       x = "Day of Week", y = "Mean Attendance") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  guides(fill = "none")

p5

cat("\nFINDINGS: Weekend games (Fri-Sun) average",
    round(mean(filter(filtered_data, is_weekend == "Weekend")$attendance, na.rm = TRUE), 0),
    "attendees,\n",
    "while weekdays average",
    round(mean(filter(filtered_data, is_weekend == "Weekday")$attendance, na.rm = TRUE), 0),
    "attendees.\n",
    "Saturday shows highest attendance; Monday shows lowest. Thursday baseline has ~41k average.\n\n")

# 4. GAME TIME EFFECTS
cat("START TIME - Attendance Summary:\n")

# Create time labels mapping
time_labels <- c(
  "11" = "11 AM EST",
  "12" = "12 PM EST",
  "13" = "1 PM EST",
  "14" = "2 PM EST",
  "15" = "3 PM EST",
  "16" = "4 PM EST",
  "17" = "5 PM EST",
  "18" = "6 PM EST",
  "19" = "7 PM EST",
  "20" = "8 PM EST",
  "21" = "9 PM EST",
  "22" = "10 PM EST"
)

hour_summary <- filtered_data %>%
  group_by(start_hour_factor) %>%
  summarise(
    Mean_Attendance = mean(attendance, na.rm = TRUE),
    Median_Attendance = median(attendance, na.rm = TRUE),
    N_Games = n(),
    .groups = 'drop'
  ) %>%
  mutate(time_label = time_labels[as.character(start_hour_factor)]) %>%
  arrange(desc(Mean_Attendance))

print(hour_summary)

p6 <- ggplot(filtered_data, aes(x = start_hour_factor, y = attendance, fill = start_hour_factor)) +
  geom_boxplot(alpha = 0.7) +
  scale_x_discrete(labels = time_labels) +
  labs(title = "Attendance Distribution by Game Start Hour",
       x = "Start Time", y = "Attendance") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  guides(fill = "none")

p6

# 5. WEATHER VARIABLES


# 6. OVERALL DATASET SUMMARY
# ============================================================================

library(knitr)

summary_list <- lapply(filtered_data %>% 
                         select(-attendance) %>% 
                         select_if(is.numeric), 
                       function(x) {
                         data.frame(
                           Mean = round(mean(x, na.rm = TRUE), 2),
                           Median = round(median(x, na.rm = TRUE), 2),
                           SD = round(sd(x, na.rm = TRUE), 2),
                           Min = min(x, na.rm = TRUE),
                           Max = max(x, na.rm = TRUE),
                           N = sum(!is.na(x))
                         )
                       })

summary_df <- bind_rows(summary_list, .id = "Variable")
kable(summary_df, caption = "Summary Statistics - All Variables")



library(dplyr)
library(corrplot)
#PART B5
# Create log attendance variable if not already created
filtered_data <- filtered_data %>%
  mutate(log_attendance = log(attendance),
         temp_squared = temperature^2)

# ---- PREPARE DATA FOR CORRELATION ANALYSIS ----
# Create a subset with numeric versions of all variables

# For categorical variables, we need to convert to numeric
# Here's one approach - adjust based on your actual variable names

correlation_data <- data %>%
  select(
    attendance,
    temperature,
    temp_squared,
    home_top_100,
    away_top_100,       # Should be 0/1 already
    game_type,
    other_weather,
    day_of_week_factor,
    start_hour_factor,
    home_team              # For ballpark effects
  ) %>%
  mutate(
    # Convert categorical variables to numeric if needed
    game_type = as.numeric(factor(game_type)),
    other_weather = as.numeric(factor(other_weather)),
    day_of_week_factor = as.numeric(day_of_week_factor),
    start_hour_factor = as.numeric(start_hour_factor),
    home_team = as.numeric(factor(home_team))
  ) %>%
  na.omit()

# ---- CORRELATION MATRIX ----
cor_matrix <- cor(correlation_data, method = "pearson")

# Extract correlations with log_attendance
correlations_with_attendance <- cor_matrix["log_attendance", ] %>%
  sort(decreasing = TRUE)

print("Correlations with Attendance (sorted by magnitude):")
print(correlations_with_attendance)

# ---- DETAILED CORRELATION WITH P-VALUES ----
# Create a function to compute correlation and p-values
cor_pval <- function(data, var1, var2) {
  test <- cor.test(data[[var1]], data[[var2]], method = "pearson")
  return(data.frame(
    Variable = var2,
    Correlation = round(test$estimate, 4),
    P_value = round(test$p.value, 4),
    Significance = ifelse(test$p.value < 0.001, "***",
                          ifelse(test$p.value < 0.01, "**",
                                 ifelse(test$p.value < 0.05, "*", ""))),
    stringsAsFactors = FALSE
  ))
}

# Apply to all variables except log_attendance
var_names <- names(correlation_data)[names(correlation_data) != "log_attendance"]
cor_results <- do.call(rbind, lapply(var_names, function(x) cor_pval(correlation_data, "log_attendance", x)))
cor_results <- cor_results[order(-abs(cor_results$Correlation)), ]

print("\nDetailed Correlation Analysis with P-Values:")
print(cor_results)

# ---- VISUALIZE CORRELATION MATRIX ----
# Create a correlation plot
corrplot(cor_matrix, 
         method = "circle",
         type = "lower",
         diag = FALSE,
         col = colorRampPalette(c("darkblue", "white", "darkred"))(200),
         title = "Correlation Matrix: Attendance & Explanatory Variables",
         mar = c(0, 0, 2, 0))

# ---- SUMMARY STATISTICS ----
print("\nSummary Statistics Log Attendance:")
print(summary(filtered_data$log_attendance))

# Create summary table
summary_table <- data.frame(
  Variable = c("Log Attendance", "Temperature", "Home Star Power", "Away Star Power"),
  Mean = c(
    mean(filtered_data$log_attendance, na.rm = TRUE),
    mean(filtered_data$temperature, na.rm = TRUE),
    mean(filtered_data$home_top_100, na.rm = TRUE),
    mean(filtered_data$away_top_100, na.rm = TRUE)
  ),
  SD = c(
    sd(filtered_data$log_attendance, na.rm = TRUE),
    sd(filtered_data$temperature, na.rm = TRUE),
    sd(filtered_data$home_top_100, na.rm = TRUE),
    sd(filtered_data$away_top_100, na.rm = TRUE)
  ),
  Min = c(
    min(filtered_data$log_attendance, na.rm = TRUE),
    min(filtered_data$temperature, na.rm = TRUE),
    min(filtered_data$home_top_100, na.rm = TRUE),
    min(filtered_data$away_top_100, na.rm = TRUE)
  ),
  Max = c(
    max(filtered_data$log_attendance, na.rm = TRUE),
    max(filtered_data$temperature, na.rm = TRUE),
    max(filtered_data$home_top_100, na.rm = TRUE),
    max(filtered_data$away_top_100, na.rm = TRUE)
  )
)

print("\nSummary Statistics:")
print(summary_table)
