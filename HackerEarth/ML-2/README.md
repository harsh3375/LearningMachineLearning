* Competition Link : https://www.hackerearth.com/challenge/competitive/machine-learning-challenge-2/  
***

* Final Leaderboard Standing #6 : https://www.hackerearth.com/challenge/competitive/machine-learning-challenge-2/leaderboard/
***

* Code Flow
	* missing_data.R
	* feature_engineering.R
	* xgboost.R
	* ensemble.R
***

* Techniques :  
	* word2vec : n=500  
	* Engineered features  
		- One hot encoding of top words in 'desc' of train and test - stopwords removed  length of each of the string features
		- difference between timestamp features in seconds  
		- month/year/day of the timestamp features  
		- converted goal to USD and used the log form of it  
	* Classifier : hyper-parameter tuned xgboost using GridSearch
(Tried KNN and LASSO regression, didn't give a promissing results)  
	*	Majority Voting from 3 xboosts  

