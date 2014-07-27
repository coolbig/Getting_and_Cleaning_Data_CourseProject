## At first, you should install packages of "data.table" and "reshape2"
## Loading packages

require("data.table")
require("reshape2")

## Getting Course Project's data path

path <- getwd()
dtpath <- file.path(path, "UCI HAR Dataset")

## Reading .txt files of "train" and "test"

dtTrainSub <- fread(file.path(dtpath, "train", "subject_train.txt"))
dtTestSub <- fread(file.path(dtpath, "test", "subject_test.txt"))
dtTrainY <- fread(file.path(dtpath, "train", "Y_train.txt"))
dtTestY <- fread(file.path(dtpath, "test", "Y_test.txt"))
filetoDT <- function(f) {
        df <- read.table(f)
        dt <- data.table(df)
}
dtTrainX <- filetoDT(file.path(dtpath, "train", "X_train.txt"))
dtTestX <- filetoDT(file.path(dtpath, "test", "X_test.txt"))

## 1.Merges the training and the test sets to create one data set.
## 1.1 Concatenate the data tables.
## 1.2 Merge columns and set the key.

dtSub <- rbind(dtTrainSub, dtTestSub)
setnames(dtSub, "V1", "subject")
dtY <- rbind(dtTrainY, dtTestY)
setnames(dtY, "V1", "activityNum")
dt <- rbind(dtTrainX, dtTestX)
dtSub <- cbind(dtSub, dtY)
dt <- cbind(dtSub, dt)
setkey(dt, subject, activityNum)

## 2.Extracts only the measurements on the mean and standard
##   deviation for each measurement. 
## ps. Read the features.txt file to know what colummns are measurements for the 
##    mean and standard deviation in dt.

dtFeatures <- fread(file.path(dtpath, "features.txt"))
setnames(dtFeatures, names(dtFeatures), c("featureNum", "featureName"))
dtFeatures <- dtFeatures[grepl("mean\\(\\)|std\\(\\)", featureName)]

## Convert the column numbers to a vector of variable names.

dtFeatures$featureCode <- dtFeatures[, paste0("V", featureNum)]
## You can test: head(dtFeatures)
## You can test: dtFeatures$featureCode

## Subsetting variables with variable names.
select <- c(key(dt), dtFeatures$featureCode)
dt <- dt[, select, with = FALSE]

## 3.Uses descriptive activity names to name the activities in the data set.
## ps. Read activity_labels.txt file to know how to add descriptive names
##     to the activities.

dtActivityNames <- fread(file.path(pathIn, "activity_labels.txt"))
setnames(dtActivityNames, names(dtActivityNames), c("activityNum", "activityName"))

## 4.Appropriately labels the data set with descriptive variable names.
## Merge activity labels and add activityName as a key

dt <- merge(dt, dtActivityNames, by = "activityNum", all.x = TRUE)
setkey(dt, subject, activityNum, activityName)
dt <- data.table(melt(dt, key(dt), variable.name = "featureCode"))
dt <- merge(dt, dtFeatures[, list(featureNum, featureCode, featureName)], 
            by = "featureCode", all.x = TRUE)

dt$activity <- factor(dt$activityName)
dt$feature <- factor(dt$featureName)

grepthis <- function(regex) {
        grepl(regex, dt$feature)
}
## Features with 2 categories
n <- 2
y <- matrix(seq(1, n), nrow = n)
x <- matrix(c(grepthis("^t"), grepthis("^f")), ncol = nrow(y))
dt$featDomain <- factor(x %*% y, labels = c("Time", "Freq"))
x <- matrix(c(grepthis("Acc"), grepthis("Gyro")), ncol = nrow(y))
dt$featInstrument <- factor(x %*% y, labels = c("Accelerometer", "Gyroscope"))
x <- matrix(c(grepthis("BodyAcc"), grepthis("GravityAcc")), ncol = nrow(y))
dt$featAcceleration <- factor(x %*% y, labels = c(NA, "Body", "Gravity"))
x <- matrix(c(grepthis("mean()"), grepthis("std()")), ncol = nrow(y))
dt$featVariable <- factor(x %*% y, labels = c("Mean", "SD"))
## Features with 1 category
dt$featJerk <- factor(grepthis("Jerk"), labels = c(NA, "Jerk"))
dt$featMagnitude <- factor(grepthis("Mag"), labels = c(NA, "Magnitude"))
## Features with 3 categories
n <- 3
y <- matrix(seq(1, n), nrow = n)
x <- matrix(c(grepthis("-X"), grepthis("-Y"), grepthis("-Z")), ncol = nrow(y))
dt$featAxis <- factor(x %*% y, labels = c(NA, "X", "Y", "Z"))

## Test to make sure all possible combinations of feature are accounted for 
## by all possible combinations of the factor class variables:
## r1 <- nrow(dt[, .N, by = c("feature")])
## r2 <- nrow(dt[, .N, by = c("featDomain", "featAcceleration", "featInstrument", 
                           "featJerk", "featMagnitude", "featVariable", "featAxis")])
## r1 == r2

## 5.Creates a second, independent tidy data set with the average of each variable 
##   for each activity and each subject. 

setkey(dt, subject, activity, featDomain, featAcceleration, featInstrument, 
       featJerk, featMagnitude, featVariable, featAxis)
dtTidy <- dt[, list(count = .N, average = mean(value)), by = key(dt)]

## write.csv(dtTidy, file = "./tidy.csv")
write.table(result.frame, file="tidy.txt", row.names = FALSE)

