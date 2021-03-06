library(xgboost)
library(lubridate)

train = read.csv("data/train.csv", header=TRUE, sep=",")
test = read.csv("data/test.csv", header=TRUE, sep=",")

train_t = read.csv("data/train_pickup.csv", header=TRUE, sep=",")
test_t = read.csv("data/test_pickup.csv", header=TRUE, sep=",")
train = cbind(train, train_t[,!names(train_t) %in% c("TID")])
test = cbind(test, test_t[,!names(test_t) %in% c("TID")])

train_t = read.csv("data/train_dropoff.csv", header=TRUE, sep=",")
test_t = read.csv("data/test_dropoff.csv", header=TRUE, sep=",")
train = cbind(train, train_t[,!names(train_t) %in% c("TID")])
test = cbind(test, test_t[,!names(test_t) %in% c("TID")])

train_t = read.csv("data/train_time_taken.csv", header=TRUE, sep=",")
test_t = read.csv("data/test_time_taken.csv", header=TRUE, sep=",")
train = cbind(train, time_taken=train_t[,!names(train_t) %in% c("TID")])
test = cbind(test, time_taken=test_t[,!names(test_t) %in% c("TID")])

train_t = read.csv("data/train_coordinates.csv", header=TRUE, sep=",")
test_t = read.csv("data/test_coordinates.csv", header=TRUE, sep=",")
train = cbind(train[,!names(train) %in% c("pickup_latitude","pickup_longitude","dropoff_latitude","dropoff_longitude")], 
              train_t[,!names(train_t) %in% c("TID")])
test = cbind(test[,!names(test) %in% c("pickup_latitude","pickup_longitude","dropoff_latitude","dropoff_longitude")], 
              test_t[,!names(test_t) %in% c("TID")])

train_t = read.csv("data/train_surcharge.csv", header=TRUE, sep=",")
test_t = read.csv("data/test_surcharge.csv", header=TRUE, sep=",")
train = cbind(train[,!names(train) %in% c("surcharge")], surcharge=train_t[,!names(train_t) %in% c("TID")])
test = cbind(test[,!names(test) %in% c("surcharge")], surcharge=test_t[,!names(test_t) %in% c("TID")])



# Factorizing 
getMap=function(df1_col, df2_col){
  all_values = unique(c(unique(as.character(df1_col)),unique(as.character(df2_col))))
  map = list()
  index = 1
  print(all_values)
  for(value in all_values){
    map[value] = index
    index = index + 1
  }
  print(map)
  map
}

getFromMap=function(key, map){
  if(key %in% names(map)){
    map[[key]]
  }else{
    NA
  }
}

map = getMap(train$vendor_id, test$vendor_id)
train$vendor_id_int = unlist(lapply(train$vendor_id, function(x) getFromMap(as.character(x), map)))
test$vendor_id_int = unlist(lapply(test$vendor_id, function(x) getFromMap(as.character(x), map)))



## Vendor ID
#train$vendor_id_int = as.numeric(unlist(train[,"vendor_id"]))
#test$vendor_id_int = as.numeric(unlist(test[,"vendor_id"]))
# check `Factoring section`



## New.User
#   Some of them are "" in both train and test
sum(train$new_user=="")
train[train$new_user=="","new_user"] = "NO"
train$new_user_int = as.numeric(unlist(train[,"new_user"]))

test[test$new_user=="","new_user"] = "NO"
test$new_user_int = as.numeric(unlist(test[,"new_user"]))
# YES = 3, NO=2



## toll_price
# Outliers ???
# quantile(c(train$tolls_amount, test$tolls_amount), probs=seq(0,1,by=0.00125))
train[train$tolls_amount<0,"tolls_amount"] = 0

test[test$tolls_amount<0,"tolls_amount"] = 0



## tip_amount
# Outliers ???
sum(is.na(train$tip_amount))
train[is.na(train$tip_amount),"tip_amount"] = 0

sum(is.na(test$tip_amount))
test[is.na(test$tip_amount),"tip_amount"] = 0



## mta_tax
# negative tax ???
# Outliers ???



## time taken
#   check extract_date_time_variables.R



### Distance
calculateDistance=function(x1,y1,x2,y2){
  if(is.na(x1) | x1==0 | is.na(y1) | y1==0 | is.na(x2) | x2==0 | is.na(y2) | y2==0 ){
    print("SHIT")
    0
  }else{ 
    sqrt((x1-x2)^2 + (y1-y2)^2)
  }
}

train$distance = mapply(calculateDistance, train$pickup_latitude, train$pickup_longitude, 
                        train$dropoff_latitude, train$dropoff_longitude)

test$distance = mapply(calculateDistance, test$pickup_latitude, test$pickup_longitude, 
                       test$dropoff_latitude, test$dropoff_longitude)



### Velocity
getVelocity = function(dist, time){
  if(time==0){
    0
  }else{
    dist/time
  }
}
train$velocity = mapply(getVelocity, train$distance, train$time_taken)
test$velocity = mapply(getVelocity, test$distance, test$time_taken)

mean_velocity = mean(c(train[train$velocity>0,"velocity"], test[test$velocity>0,"velocity"]))

train[train$velocity<=0,"velocity"] = mean_velocity
test[test$velocity<=0,"velocity"] = mean_velocity



### rate_code
# ???
  

### store_and_fwd 
train[train$store_and_fwd_flag=="","store_and_fwd_flag"] = "N"
train[train$store_and_fwd_flag==" ","store_and_fwd_flag"] = "N"

test[test$store_and_fwd_flag=="","store_and_fwd_flag"] = "N"
test[test$store_and_fwd_flag==" ","store_and_fwd_flag"] = "N"

map = getMap(train$store_and_fwd_flag, test$store_and_fwd_flag)
train$store_and_fwd_flag_int = unlist(lapply(train$store_and_fwd_flag, function(x) getFromMap(as.character(x), map)))
test$store_and_fwd_flag_int = unlist(lapply(test$store_and_fwd_flag, function(x) getFromMap(as.character(x), map)))



### payment type
#train$payment_type_int = as.numeric(unlist(train[,"payment_type"]))
#test$payment_type_int = as.numeric(unlist(test[,"payment_type"]))

map = getMap(train$payment_type, test$payment_type)
train$payment_type_int = unlist(lapply(train$payment_type, function(x) getFromMap(as.character(x), map)))
test$payment_type_int = unlist(lapply(test$payment_type, function(x) getFromMap(as.character(x), map)))



### surcharge
# outliers ??? 
# negative values ???
sum(is.na(train$surcharge))
train[is.na(train$surcharge),"surcharge"] = 0

test[is.na(test$surcharge),"surcharge"] = 0



## Extra Amount
train$extra_amt = train$tolls_amount + train$tip_amount + train$mta_tax + train$surcharge

test$extra_amt = test$tolls_amount + test$tip_amount + test$mta_tax + test$surcharge



## Difference from mean of passenger_count
calculateDifferenceFromMean=function(df1, df2, cat_column, column){
  #cat_column = "passenger_count"
  #column = "tolls_amount"
  #d1 = train
  #d2 = test
  
  all_ = rbind(df1[,c(cat_column,column)], df2[,c(cat_column,column)])
  form = as.formula(paste0(column,"~",cat_column))
  mean_value = as.data.frame(aggregate(form, all_, mean))
  rm(all_)
  
  mapply(function(category, value) value - mean_value[mean_value[,cat_column]==category, column] , 
         df1[,cat_column], df1[,column])
}

rm(mean)
train$tolls_amnt_diff_pcount = calculateDifferenceFromMean(train, test, "passenger_count", "tolls_amount")
test$tolls_amnt_diff_pcount = calculateDifferenceFromMean(test, train, "passenger_count", "tolls_amount")

train$tip_amnt_diff_pcount = calculateDifferenceFromMean(train, test, "passenger_count", "tip_amount")
test$tip_amnt_diff_pcount = calculateDifferenceFromMean(test, train, "passenger_count", "tip_amount")

train$surcharge_diff_pcount = calculateDifferenceFromMean(train, test, "passenger_count", "surcharge")
test$surcharge_diff_pcount = calculateDifferenceFromMean(test, train, "passenger_count", "surcharge")

train$time_taken_diff_pcount = calculateDifferenceFromMean(train, test, "passenger_count", "time_taken")
test$time_taken_diff_pcount = calculateDifferenceFromMean(test, train, "passenger_count", "time_taken")



## Difference from mean of payment_type_int
rm(mean)
train$tolls_amnt_diff_paytype = calculateDifferenceFromMean(train, test, "payment_type_int", "tolls_amount")
test$tolls_amnt_diff_paytype = calculateDifferenceFromMean(test, train, "payment_type_int", "tolls_amount")

train$tip_amnt_diff_paytype = calculateDifferenceFromMean(train, test, "payment_type_int", "tip_amount")
test$tip_amnt_diff_paytype = calculateDifferenceFromMean(test, train, "payment_type_int", "tip_amount")

train$surcharge_diff_paytype = calculateDifferenceFromMean(train, test, "payment_type_int", "surcharge")
test$surcharge_diff_paytype = calculateDifferenceFromMean(test, train, "payment_type_int", "surcharge")

train$time_taken_diff_paytype = calculateDifferenceFromMean(train, test, "payment_type_int", "time_taken")
test$time_taken_diff_paytype = calculateDifferenceFromMean(test, train, "payment_type_int", "time_taken")



## Difference from mean of rate_code
rm(mean)
train$tolls_amnt_diff_ratecode = calculateDifferenceFromMean(train, test, "rate_code", "tolls_amount")
test$tolls_amnt_diff_ratecode = calculateDifferenceFromMean(test, train, "rate_code", "tolls_amount")

train$tip_amnt_diff_ratecode = calculateDifferenceFromMean(train, test, "rate_code", "tip_amount")
test$tip_amnt_diff_ratecode = calculateDifferenceFromMean(test, train, "rate_code", "tip_amount")

train$surcharge_diff_ratecode = calculateDifferenceFromMean(train, test, "rate_code", "surcharge")
test$surcharge_diff_ratecode = calculateDifferenceFromMean(test, train, "rate_code", "surcharge")

train$time_taken_diff_ratecode = calculateDifferenceFromMean(train, test, "rate_code", "time_taken")
test$time_taken_diff_ratecode = calculateDifferenceFromMean(test, train, "rate_code", "time_taken")



## TODO
# tranform x
# outliers



## Factors
x = c("vendor_id_int", 
      #1"new_user_int", 
      "tolls_amount", 
      "tip_amount", 
      "mta_tax", 
      "time_taken", 
      #1"passenger_count", 
      
      "pickup_latitude",
      "pickup_longitude",
      "dropoff_latitude",
      "dropoff_longitude",
      
      "pickup_min",
      "pickup_hour",
      "pickup_yday",
      #1"pickup_week", 
      #1"pickup_month",
      #1"pickup_year",
      
      "dropoff_min",
      "dropoff_hour",
      "dropoff_yday",
      #"dropoff_week", 
      #"dropoff_month",
      #"dropoff_year",
      
      "rate_code",
      #1"store_and_fwd_flag_int",
      "payment_type_int", 
      "surcharge", 
      "distance", 
      "velocity",
      "extra_amt",
      
      "tolls_amnt_diff_pcount", 
      "tip_amnt_diff_pcount",
      "surcharge_diff_pcount", 
      "time_taken_diff_pcount",
      
      "tolls_amnt_diff_paytype", 
      "tip_amnt_diff_paytype",
      "surcharge_diff_paytype", 
      "time_taken_diff_paytype",
      
      "tolls_amnt_diff_ratecode", 
      "tip_amnt_diff_ratecode",
      "surcharge_diff_ratecode", 
      "time_taken_diff_ratecode"
      )

y = c("fare_amount")

rows = dim(train)[1]
train_rows = sample(1:rows, 0.80*rows, replace=F)

train_DM <- xgb.DMatrix(data = as.matrix(train[train_rows,x]), label=train[train_rows,y])
valid_DM <- xgb.DMatrix(data = as.matrix(train[-train_rows,x]), label=train[-train_rows,y])



## Parameter Tunning
for(param_1 in c(25,50,75,125,150,175)){                # min_child_weight
  for(param_2 in c(1)){                 # max_depth divider
    for(param_3 in c(0.8)){     # subsample
      for(param_4 in c(0.6)){   # colsample_bytree
        
        print(paste0("param1:", param_1, " and ", "param2:", param_2, 
                     " and ", "param3:", param_3," and ", "param4:", param_4))
        
        param = list(  objective           = "reg:linear", 
                       booster             = "gbtree",
                       eta                 = 0.5, #0.025,
                       max_depth           = as.integer(length(x)/param_2),
                       min_child_weight    = param_1,
                       subsample           = param_3,
                       colsample_bytree    = param_4
                       #alpha               = param_3
                       #lambda              = param_4
        )
        
        nrounds = 200
        model = xgb.cv(      params              = param, 
                             data                = train_DM,
                             nrounds             = nrounds, 
                             nfold               = 4,
                             early_stopping_rounds  = 20,
                             watchlist           = list(val=valid_DM),
                             maximize            = FALSE,
                             eval_metric         = "mae",
                             verbose             = FALSE
                             #print_every_n       = 50
        )
        print(model$evaluation_log[model$best_iteration]$test_mae_mean)
      
      }
    }
  }
}
# nrounds = 200, eta = 0.5
#   depth   min_child_weight  alpha   lambda  sample  colSample 
#   1       50              



## Training 
test_DM <- xgb.DMatrix(data = as.matrix(test[,x]))
seeds = c(1234,2345,3456)

for(i in c(1,2,3)){
  
  rows = dim(train)[1]
  train_rows = sample(1:rows, 0.80*rows, replace=F)
  
  train_DM <- xgb.DMatrix(data = as.matrix(train[train_rows,x]), label=train[train_rows,y])
  valid_DM <- xgb.DMatrix(data = as.matrix(train[-train_rows,x]), label=train[-train_rows,y])
  
  seed_used = seeds[i]
  param = list(  objective           = "reg:linear", 
                 booster             = "gbtree",
                 eta                 = 0.0125,
                 max_depth           = as.integer(length(x)),
                 min_child_weight    = 75,
                 subsample           = 0.80,
                 colsample_bytree    = 0.60,
                 seed                = seed_used
  )
  
  nrounds = 1000
  print(paste0("Round#", i, " with seed:", seed_used))
  
  model = xgb.train(   params              = param, 
                       data                = train_DM,
                       nrounds             = nrounds, 
                       early_stopping_rounds  = 20,
                       watchlist           = list(val=valid_DM),
                       maximize            = FALSE,
                       eval_metric         = "mae",
                       print_every_n = 25
  )
  # valid_DM mae = 1.54   -   98.37
  # valid_DM mae = 0.92   -   99.03
  # valid_DM mae = 0.90   -   99.05
  # valid_DM mae = 0.88   -   99.06
  # valid_DM mae = 0.80   -   99.13   
  # valid_DM mae = 0.78   -   99.19   (7.80, 4.20, 2.31, 1.40, 1.01)
  # valid_DM mae = 0.69   -   99.28   (7.80, 4.20, 2.31, 1.40, 1.01)
  
  # 0,0.69 - 1,0.69 - 2, 
  
  #imp = xgb.importance(feature_names = x, model = model)
  #imp
  
  
  ## Test Prediction
  test_pred = predict(model, test_DM)
  pred = data.frame("TID"=test$TID, "fare_amount"=test_pred)
  pred[pred$fare_amount<0,]$fare_amount = 0
  
  file_name = paste0("xgb_", "x", toString(length(x)), "_s",seed_used, ".csv")
  write.csv(pred, file_name, row.names = FALSE)
  
  pred_i = paste0("pred_",i)
  assign(pred_i, test_pred)
}



## Averaging the predictions
pred_final = data.frame(TID=test$TID, fare_amount=(pred_1+pred_2+pred_3)/3)
pred[pred_final$fare_amount<0,]$fare_amount = 0


file_name = "xgb_final.csv"
write.csv(pred_final, file_name, row.names = FALSE, quote = FALSE)
