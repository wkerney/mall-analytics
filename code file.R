install.packages("tidyverse")
install.packages("data.table")
install.packages("lubridate")
install.packages("ggplot2")
install.packages("caret")
install.packages("dplyr")
install.packages("sqldf")
install.packages("prophet")
install.packages("readr")

library(tidyverse)
library(data.table)
library(lubridate)
library(ggplot2)
library(caret)
library(dplyr)
library(sqldf)
library(prophet)
library(readr)

#loading and exploring dataset
data<- read.csv("Mall_Customers.csv")
str(data)
summary(data)

#correcting mistake found in raw data file
colnames(data)[2] <- "Gender"
head(data)

#using funnel to focus on customer behavior
funnel <- data %>% 
  mutate(
    high_income = Annual.Income..k.. > 75,
    high_spending = Spending.Score..1.100. > 75
  ) %>%
  summarize(
    total_customers = n(),
    high_income_count = sum(high_income),
    high_spending_count = sum(high_spending),
    high_income_spending = sum(high_income & high_spending)
  )

funnel_conversion_rate <- funnel %>%
  summarize(
    income_to_spending = high_income_spending / high_income_count
  )

#user segmentation
user_segments <- data %>%
  group_by(Gender) %>%
  summarize(
    average_income = mean(Annual.Income..k..),
    average_spending = mean(Spending.Score..1.100.)
  )

ggplot(user_segments, aes(x = Gender, y = average_spending)) +
  geom_bar(stat = "identity") +
  ggtitle("Average Spending Score by Gender")

#cohort analysis
cohort_analysis <- data %>%
  mutate(age_group = cut(Age, breaks = c(0, 20, 30, 40, 50, 60, 100), labels = c("Under 20", "20-29", "30-39", "40-49", "50-59", "60+"))) %>%
  group_by(age_group) %>%
  summarize(
    average_income = mean(Annual.Income..k..),
    average_spending = mean(Spending.Score..1.100.)
  )

ggplot(cohort_analysis, aes(x = age_group, y = average_spending)) +
  geom_point() +
  ggtitle("Average Spending Score by Age Group")

#time-series analysis
set.seed(123)
time_series <- data.frame(
  date = seq(as.Date("2023-01-01"), by = "month", length.out = 12),
  revenue = cumsum(runif(12, 10000, 50000))
)

m <- prophet(time_series %>% rename(ds = date, y = revenue))
forecast <- predict(m, make_future_dataframe(m, periods = 6))

plot(m, forecast)

#A/B testing and statistical analysis
set.seed(123)
ab_test <- data.frame(
  CustomerID = sample(1:200, 100),
  group = sample(c("Control", "Promotion"), 100, replace = TRUE),
  spending = rnorm(100, mean = 50, sd = 10)
)

ab_test$group_spending <- ifelse(ab_test$group == "Promotion", ab_test$spending * 1.2, ab_test$spending)

# Perform a t-test to compare spending between groups
t_test_result <- t.test(group_spending ~ group, data = ab_test)

#More visualizations
ggplot(cohort_analysis, aes(x = age_group, y = average_income)) +
  geom_bar(stat = "identity") +
  ggtitle("Average Income by Age Group")

ggplot(ab_test, aes(x = group, y = group_spending)) +
  geom_boxplot() +
  ggtitle("Spending by A/B Test Group")


