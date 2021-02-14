#' Checks which rows have col-wise duplicates
#'
#' @param x data.frame
#'
#' @return integer vector
#' @noRd

dupez_by_loopz2 <- function(x){
  
  # pre assign result vectors
  # prevents copies being made in  loop and prevents vector growing in loop
  row_has_duplicate <- logical(NROW(x))
  is_duplicate <- logical(NROW(x))
  
  n <- NCOL(x)
  
  # Loop over all columns except last
  for(i in 1:(n-1) ){
    
    # Index for comparison column
    # just compare columns to the right of i
    for(j in (i+1):n){
      
      # compare two columns elementwise for equality
      #[[ indexes into data.table and returns a vector
      # modify is_duplicate in place using `[<-`
      
      is_duplicate[] <- x[[i]] == x[[j]]
      
      # use logical indexing to update dupes
      # modify row_has_duplicate in place using `[<-`
      row_has_duplicate[is_duplicate] <-  TRUE
    }
  }
  #return indexes of TRUE
  which(row_has_duplicate)
}

#' Rolling Join
#'
#' This will left join df `x` to df `y` by (`by.x` = `pre.y`) and then will
#' take `post.y` and treat that as the new `by.x` until exhausted
#'
#' @param x object of class data.frame that acts as the starting data.frame (left-side)
#' @param y object of class data.frame that acts as a lookup table and is continually joined to the rolling table until exhausted
#' @param by.x character; column name in object `x` that is used to join to `y`
#' @param pre.y character; column name in object `y` that is used to join to `x` on the first iteration and to itself on future iterations.
#' @param post.y character; column name in object `y` that is used to join to itself on the 2nd iteration onwards.
#' @param id.name character; prefix of the column to be written in the returned data.frame. This prefix will be followed with "_i", where i is the iteration of the join.
#' @param j_max numeric; number of maximum joins to allow before exiting the loop (Inf by default)
#' @param remove_loops logical; whether to remove self-recursing loops whereby a row of the data.frame continually joins on itself and produces the same recurring process (TRUE by default).
#' @param quiet Supresses messages specifying iteration number (default is false)
#' @param return_dt return a data.table instead of data.frame
#'
#' @import data.table
#' @return data.frame; wide formatted
#' @note The join must be by a single column
#' @export
#'
#' @examples
#'
#' # Make mock data
#' predoc <- data.frame(ID = c(100:299,999, 888), Type = rep(c("Ins", "DA"), times = 101), Type2 = "Foo", Predoc_ID = c(0:99, sample(100:299, 100), 888, 999))
#' inc <- data.frame(ID = c(0:99, 888, 999))
#'
#' # Run Function
#' rolling_join(x = inc, y = predoc, by.x = "ID", pre.y = "Predoc_ID", post.y = "ID", j_max = Inf, remove_loops = T) %>% head(20)

rolling_join <- function(x, y, by.x, pre.y, post.y, id.name = "ID", j_max = Inf, remove_loops = TRUE, quiet = F, return_dt = FALSE) {
  
  '%ni%' <- Negate('%in%')
  
  #Initialise thw while loop with some parameters
  Joining <- T
  i<-0
  colnames(x)[which(colnames(x) == by.x)] <- paste(id.name, i, sep = "_")
  
  rolling.df <- data.table::as.data.table(x)
  rm(x)
  hard.y <- colnames(y)
  data.table::setDT(y)
  idz <- list()
  fun.rename <- function(n) {paste0(n, "_", i+1)}
  which.dup <- function(x) {duplicated(x, incomparables = NA, fromLast = FALSE)}
  #Run the loop so long as there are no empty joins
  while(Joining) {
    
    if(!quiet){
      message(paste("Joining on iteration", i))
    }
    
    if(i == 1) {
      fun.rename <- function(n) {paste0(sub("\\d+$", "", n), "", i+1)}
    }
    
    # Set up some variables
    rolling_id_add <- paste(id.name, i+1, sep = "_")
    rolling_id <- paste(id.name, i, sep = "_")
    idz[[i+1]] <- rolling_id_add
    
    # For the lookup add an integer to the IDs
    rolling_id_column <- names(y)[which(hard.y == pre.y)] %>% unique()
    rolling_id_add_column <- colnames(y)[which(hard.y == post.y)] %>% unique()
    other_cols <- colnames(y)[which(colnames(y) %ni% c(rolling_id_column, rolling_id_add_column))]
    
    data.table::setnames(y, other_cols, fun.rename)
    data.table::setnames(y, rolling_id_column, rolling_id)
    suppressWarnings(data.table::setnames(y, rolling_id_add_column, rolling_id_add))
    # y <- dplyr::rename_at(tibble::as_tibble(y), dplyr::vars(colnames(y)[which(colnames(y) %ni% c(rolling_id, rolling_id_add))]), fun.rename)
    
    colnames_x <- colnames(rolling.df)
    colnames_y <- colnames(y)[which(colnames(y) != rolling_id)]
    
    rolling.df[y, on = rolling_id, (colnames_y) := mget(paste0("i.", colnames_y))]
    
    #Check for loops
    if(remove_loops & i > 0){
      id.v <- unlist(idz)
      id_index <- which(colnames(rolling.df) == rolling_id)
      duplicates <- dupez_by_loopz2(rolling.df[,..id.v])
      if(!purrr::is_empty(duplicates)){
        mapply(function(x) {
          rolling.df[x,(c((ncol(rolling.df)-(ncol(y))):ncol(rolling.df),id_index)) := NA]
        }, x = unique(duplicates), SIMPLIFY = FALSE)
      } #Row and col are transformed from original DF
    }
    
    
    # Remove y and reset
    # rm(y)
    # y <- data.table::copy(hard.y)
    # data.table::setDT(y)
    
    # Add to loop
    i <- i +1
    Joining <- ifelse(sum(!is.na(rolling.df[[rolling_id_add]])) == 0 | i == j_max, FALSE, TRUE)
  }
  if(return_dt == FALSE | is.null(return_dt)) {
    data.table::setDF(rolling.df)
  }
  return(rolling.df[,1:(ncol(rolling.df)-(ncol(y)-1))])
}
