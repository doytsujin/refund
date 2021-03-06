#' Prediction for fast bivariate \emph{P}-spline (fbps)
#'
#' Produces predictions given a \code{\link{fbps}} object and new data 
#'
#' @param object an object returned by \code{\link{fbps}}
#' @param newdata a data frame or list consisting of x and z values for which predicted values are desired. 
#' vectors of x and z need to be of the same length.
#' @param ... additional arguments.
#' @return A list with components \item{x}{a vector of x given in newdata}
#' \item{z}{a vector of z given in newdata} \item{fitted.values}{a vector of
#'  fitted values corresponding to x and z given in newdata} 
#' @author Luo Xiao \email{lxiao@@jhsph.edu}
#' @export
#' @importFrom Matrix kronecker as.matrix
#' @references Xiao, L., Li, Y., and Ruppert, D. (2013). Fast bivariate
#' \emph{P}-splines: the sandwich smoother. \emph{Journal of the Royal
#' Statistical Society: Series B}, 75(3), 577--599.
#' @examples
#' ##########################
#' #### True function   #####
#' ##########################
#' n1 <- 60
#' n2 <- 80
#' x <- (1: n1)/n1-1/2/n1
#' z <- (1: n2)/n2-1/2/n2
#' MY <- array(0,c(length(x),length(z)))

#' sigx <- .3
#' sigz <- .4
#' for(i in 1: length(x))
#'   for(j in 1: length(z))
#'  {
#'     #MY[i,j] <- .75/(pi*sigx*sigz) *exp(-(x[i]-.2)^2/sigx^2-(z[j]-.3)^2/sigz^2)
#'     #MY[i,j] <- MY[i,j] + .45/(pi*sigx*sigz) *exp(-(x[i]-.7)^2/sigx^2-(z[j]-.8)^2/sigz^2)
#'     MY[i,j] = sin(2*pi*(x[i]-.5)^3)*cos(4*pi*z[j])
#'   }
#' 
#' ##########################
#' #### Observed data   #####
#' ##########################
#' sigma <- 1
#' Y <- MY + sigma*rnorm(n1*n2,0,1)
#' 
#' ##########################
#' ####   Estimation    #####
#' ##########################
#' est <- fbps(Y,list(x=x,z=z))
#' mse <- mean((est$Yhat-MY)^2)
#' cat("mse of fbps is",mse,"\n")
#' cat("The smoothing parameters are:",est$lambda,"\n")
#' 
#' ########################################################################
#' ########## Compare the estimated surface with the true surface #########
#' ########################################################################
#' 
#' par(mfrow=c(1,2))
#' persp(x,z,MY,zlab="f(x,z)",zlim=c(-1,2.5), phi=30,theta=45,expand=0.8,r=4,
#'       col="blue",main="True surface")
#' persp(x,z,est$Yhat,zlab="f(x,z)",zlim=c(-1,2.5),phi=30,theta=45,
#'       expand=0.8,r=4,col="red",main="Estimated surface")
#' 
#' ##########################
#' ####   prediction    #####
#' ##########################
#' 
#' # 1. make prediction with predict.fbps() for all pairs of x and z given in the original data
#' #    ( it's expected to have same results as Yhat obtianed using fbps() above )
#' newdata <- list(x= rep(x, length(z)), z = rep(z, each=length(x)))
#' pred1 <- predict(est, newdata=newdata)$fitted.values
#' pred1.mat <- matrix(pred1, nrow=length(x))
#' par(mfrow=c(1,2))
#' image(pred1.mat); image(est$Yhat)
#' all.equal(as.numeric(pred1.mat), as.numeric(est$Yhat))
#' 
#' # 2. predict for pairs of first 10 x values and first 5 z values
#' newdata <- list(x= rep(x[1:10], 5), z = rep(z[1:5], each=10))
#' pred2 <- predict(est, newdata=newdata)$fitted.values
#' pred2.mat <- matrix(pred2, nrow=10)
#' par(mfrow=c(1,2))
#' image(pred2.mat); image(est$Yhat[1:10,1:5])
#' all.equal(as.numeric(pred2.mat), as.numeric(est$Yhat[1:10,1:5]))

#' # 3. predict for one pair 
#' newdata <- list(x=x[5], z=z[3])
#' pred3 <- predict(est, newdata=newdata)$fitted.values
#' all.equal(as.numeric(pred3), as.numeric(est$Yhat[5,3]))

predict.fbps <- function(object, newdata,...){
  
  stopifnot(length(newdata$x)==length(newdata$z))
  stopifnot(class(object)=="fbps")
  
  set <- object$setting
  
  xknots <- set$x$knots
  p1 <- set$x$p
  m1 <- set$x$m
  
  zknots <- set$z$knots
  p2 <- set$z$p
  m2 <- set$z$m
  
  B1 <- spline.des(knots = xknots, x = newdata$x, ord = p1+1, outer.ok=TRUE)$design
  B2 <- spline.des(knots = zknots, x = newdata$z, ord = p2+1, outer.ok=TRUE)$design
  
  Theta <- object$Theta
  
  KH = function(A,B){
    C = matrix(0,dim(A)[1],dim(A)[2]*dim(B)[2])
    for(i in 1:dim(A)[1])
      C[i,] = kronecker(A[i,],B[i,])
    return(C)
  }
  
  Yhat <-  KH(B2,B1)%*% as.vector(Theta)
  return(list(x = newdata$x, z = newdata$z, fitted.values = Yhat))
}

