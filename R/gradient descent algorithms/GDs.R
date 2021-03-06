library(rgl)
library(fields)



### Function
f=function(x, betas){
  sin(betas[1]*x[,1] + betas[2]*x[,2])
}



### Loss Function
lossFunction=function(y, betas, x){
  y_hat = f(x, betas)
  errors = sum(abs((y - y_hat)))
  errors
}



## Generating Data
n = 100

betas = c(3,1)
x = sort(runif(n, 0, 10))
df = data.frame("x_1"=rep(1,n),"x_2"=x)
X = as.matrix(df)
y = f(X, betas)

plot(x,y)



### Plot error vs betas
beta_1 = vector('double')
beta_2 = vector('double')
z = vector('double')

start = 0.03125
end = 5
step = 0.03125

for(i in seq(start, end, step)){
  for(j in seq(start, end, step)){
    beta_1 = c(beta_1, i)
    beta_2 = c(beta_2, j)
    z = c(z, lossFunction(y, c(i,j), X))
  }
}

nColors = 128
colindex = as.integer(cut(z,breaks=nColors))
plot3d(beta_1, beta_2, z,col=tim.colors(nColors)[colindex])



### Stochastic Gradient Descent
sgd=function(X, y, learn_rate=0.001, niter=100, starting=c(0,0)){
  m = 2
  n = dim(X)[1]
  betas = starting
  
  for(iter in 1:niter){
    for(i in 1:n){
      for(j in 1:m){
        y_hat = f(matrix(X[i,], nrow=1, ncol=2), betas)
        #print(y_hat)
        
        delta_J = ( X[[i,j]] * (y_hat - y[i]) * cos(betas[1]*X[[i,1]]+betas[2]*X[[i,2]]) )
        #print(step)
        
        step = learn_rate * delta_J
        #print(step)
        
        betas[j] = betas[j] - step
        #print(betas)
      }
    }
    y_hats = f(X, betas)
    E = lossFunction(y, betas, X)
    print(paste("Iternation:", iter, "Error:", E))
    points3d(betas[1], betas[2], E, col="red")
  }

  betas
}

#plot3d(beta_1, beta_2, z,col=tim.colors(nColors)[colindex])
sgd(X, y, learn_rate=0.0005, niter=1000, starting=c(3,3.25))



### Stochastic Gradient Descent with momentum
sgdm=function(X, y, learn_rate=0.001, niter=100, starting=c(0,0)){
  m = 2
  n = dim(X)[1]
  betas = starting
  print(betas)
  
  gamma = 0.9
  v = 0
  
  for(iter in 1:niter){
    for(i in 1:n){
      for(j in 1:m){
        y_hat = f(matrix(X[i,], nrow=1, ncol=2), betas)
        #print(y_hat)
        
        delta_J = ( X[[i,j]] * (y_hat - y[i]) * cos(betas[1]*X[[i,1]]+betas[2]*X[[i,2]]) )
        #print(step)
        
        step = learn_rate * delta_J
        #print(step)
        
        v = (gamma*v) + step 
        #print(v)
        
        betas[j] = betas[j] - v
        #print(betas)
      }
    }
    y_hats = f(X, betas)
    E = lossFunction(y, betas, X)
    print(paste("Iternation:", iter, "Error:", E))
    points3d(betas[1], betas[2], E, col="black")
  }
  
  betas
}

plot3d(beta_1, beta_2, z,col=tim.colors(nColors)[colindex])
sgdm(X, y, learn_rate=0.0005, niter=1000, starting=c(3,3.25))
# starting at 3,3.25 SGD with momentum moves faster downhill



