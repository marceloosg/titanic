library(caret)
library(MASS)
library(ggplot2)
library(data.table)
library(randomForest)
library(doMC)
plot_grid_search=function(mtry_grid=seq(70,110,2)/10,ntree_grid=seq(150,300,10),results,corte=15 ,degree=1){
  m = loess(Accuracy ~ mtry*ntree, span=0.5,degree=degree,data=results)
  ndata=expand.grid(mtry = mtry_grid , ntree = ntree_grid)
  y=predict(m, newdata = ndata)
  contourplot(y ~ ndata$mtry*ndata$ntree)
  cm.rev <- function(...) rev(cm.colors(...))
  levelplot(y ~ ndata$mtry * ndata$ntree, asp = 1,contour=TRUE,cuts=corte)
}

load_custom_RF = function(){
  customRF <- list(type = "Classification", library = "randomForest", loop = NULL)
  customRF$parameters <- data.frame(parameter = c("mtry", "ntree"), class = rep("numeric", 2), label = c("mtry", "ntree"))
  customRF$grid <- function(x, y, len = NULL, search = "grid") {}
  customRF$fit <- function(x, y, wts, param, lev, last, weights, classProbs, ...) {
    randomForest(x, y, mtry = param$mtry, ntree=param$ntree, ...)
  }
  customRF$predict <- function(modelFit, newdata, preProc = NULL, submodels = NULL)
    predict(modelFit, newdata)
  customRF$prob <- function(modelFit, newdata, preProc = NULL, submodels = NULL)
    predict(modelFit, newdata, type = "prob")
  customRF$sort <- function(x) x[order(x[,1]),]
  customRF$levels <- function(x) x$classes
  customRF <- list(type = "Classification", library = "randomForest", loop = NULL)
  customRF$parameters <- data.frame(parameter = c("mtry", "ntree"), class = rep("numeric", 2), label = c("mtry", "ntree"))
  customRF$grid <- function(x, y, len = NULL, search = "grid") {}
  customRF$fit <- function(x, y, wts, param, lev, last, weights, classProbs, ...) {
    randomForest(x, y, mtry = param$mtry, ntree=param$ntree, ...)
  }
  customRF$predict <- function(modelFit, newdata, preProc = NULL, submodels = NULL)
    predict(modelFit, newdata)
  customRF$prob <- function(modelFit, newdata, preProc = NULL, submodels = NULL)
    predict(modelFit, newdata, type = "prob")
  customRF$sort <- function(x) x[order(x[,1]),]
  customRF$levels <- function(x) x$classes
  customRF
}

customRF=load_custom_RF()

extract_ticket_category=function(ticket){
  has_category=grepl(" ",ticket)
  options(warn=-1)
  if(has_category){
    if (is.na(as.integer(ticket))){
      ret=data.table(ticket_category=T,ticket_value=0)  
    }else{
      ret=data.table(ticket_category=T,ticket_value=as.integer(sub(".* ","",ticket)))
    }}
  else{
    if (is.na(as.integer(ticket))){
      ret=data.table(ticket_category=T,ticket_value=0)  
    }else{
      ret=data.table(ticket_category=F,ticket_value=as.integer(ticket))
    }
  }
  options(warn=0)
  ret
}


addfeatures=function(data,train_data,is_train=T){
  title=train_data[,.(title=sub("\\..*","", sub(".*, ","",name)))]
  title_categories=getCategories('title',title,6)$category
  title=data[,.(title=sub("\\..*","", sub(".*, ","",name)))]
  dummy_title=dummyfy('title',title,title_categories)
  pclass_categories=getCategories('pclass',train_data,4)$category
  dummy_pclass=dummyfy('pclass',data,pclass_categories)
  embarked_categories=getCategories('embarked',train_data,3)$category
  dummy_embarked=dummyfy('embarked',data,embarked_categories)
  parch_categories=getCategories('parch',train_data,3)$category
  dummy_parch=dummyfy('parch',data,parch_categories)
  data=cbind(data,dummy_title,dummy_pclass,dummy_embarked,dummy_parch)
  data[,has_nick:=grepl("(\\(|\\\")",name,fixed=F)]
  data[,is_male:=grepl("^m",sex,ignore.case = T)]
  data[,is_female:=grepl("^(w|f)",sex,ignore.case = T)]
  data[,is_sex_unknown:=!is_male & !is_female]
  data[,has_cabin:= cabin==""]
  ticket=rbindlist(lapply(data$ticket,extract_ticket_category))
  data=cbind(data,ticket)
  data$no_age=FALSE
  data[is.na(age)]$no_age=TRUE
  data[is.na(age)]$age=0
  data=data[,-c("sex","name","cabin","pclass","embarked","ticket", "passengerid","parch")]
  if(is_train){
    target=data.table(target=data$survived)
    transformed_data=data[,-"survived"]
    transformed_data=transformed_data[,-c( "pclass_other",   "embarked_other"),with=F]
    print(names(transformed_data))
    list("target"=target,"data"=transformed_data)  
  }else{
    transformed_data=data
    transformed_data=transformed_data[,-c( "pclass_other",   "embarked_other"),with=F]
    print(names(transformed_data))
    list("data"=transformed_data)  
  }
}

getCategories=function(column,data,retain){
  base=data.table(category = data[[column]])
  classes=base[,.N,by=category][order(-N)][1:retain]
  classes
}

dummyfy=function(column,data,classes){
  base=data.table(feature = as.character(data[[column]]))
  classes=as.character(classes)
  classes[is.na(classes)]= "NA"
  base[is.na(feature)]="NA"
  for(category in classes){
    test=base$feature==category
    base[[paste((column),(category),sep="_")]]= test 
  }
  base[[paste((column),'other',sep="_")]]=sapply(base$feature, function(s) !any(grepl(s,classes)))
  base[,-"feature"]
}
