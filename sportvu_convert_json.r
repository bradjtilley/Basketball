###NBA_SportVU FUNCTIONS with original coding credit to Rajiv Shah https://github.com/rajshah4/NBA_SportVu

library(RCurl)
library(jsonlite)
library(dplyr)
library(sp)
library(plotly)

factorconvert <- function(f){as.numeric(levels(f))[f]}

sportvu_convert_json <- function (file.name)
{
  # Much of the process is from http://tcbanalytics.com/blog/nba-movement-data-R.html#.VnX8d4RiOCQ
  # Takes a json and converts it into a dataframe
  the.data.file<-fromJSON(file.name)
  ##Get the sports vu data
  moments <- the.data.file$events$moments
  
  ##Function for extracting infomration from JSON
  extractbb <- function (listbb)
  {#df <- unlist(listbb,recursive = FALSE)
    df <- listbb
    # str(df)
    quarters <- unlist(lapply(df, function(x) x[[1]]))
    game.clock <- unlist(lapply(df, function(x) x[[3]]))
    shot.clock <- unlist(lapply(df, function(x) ifelse(is.null(x[[4]]), 'NA', x[[4]])))
    moment.details <- (lapply(df, function(x) x[[6]]))
    x3 <-  mapply(cbind, moment.details, game.clock, shot.clock,quarters, SIMPLIFY=F)
    x4 <- do.call('rbind', x3)
    return (x4)
  }
  
  test2 <- lapply(moments, function (x) {extractbb(x)})
  lengthmm <- the.data.file$events$eventId
  test2 <- mapply(cbind, test2, "event.id"=lengthmm, SIMPLIFY=F)
  
  #Remove events that are NAs
  final <- (lapply(test2, function(x) {
    if ((length(unlist(x)))<=1) {x <- NA} 
    return(x)
  }))
  
  ###Merge the file
  test2 <- do.call('rbind', final)
  test2 <- as.data.frame(test2)
  test2[test2 == "NA" ] = NA
  all.movement <- test2
  #all.movement<-test2[order(test2$game.clock),]
  
  ##Lets join the movement to player id
  headers = c("team_id", "player_id", "x_loc", "y_loc", "radius", "game_clock", "shot_clock", "quarter","event.id")
  colnames(all.movement) <- headers
  all.movement<-data.frame(all.movement)
  all.movement<-all.movement[order(all.movement$game_clock),]
  
  home.players <- the.data.file$events$home$players[[1]]
  away.players <- the.data.file$events$visitor$players[[1]]
  colnames(home.players)[3] <- "player_id"
  colnames(away.players)[3] <- "player_id"
  
  ## Add the player name information to each movement moment
  home.movements<-merge(home.players, all.movement, by="player_id")
  away.movements<-merge(away.players, all.movement, by="player_id")
  ball.movement<-all.movement %>% filter(player_id == -1)
  ball.movement$jersey <- NA
  ball.movement$position <- NA
  ball.movement$team_id <- NA
  ball.movement$lastname <- "ball"
  ball.movement$firstname <- NA
  all.movements <- rbind(home.movements, away.movements,ball.movement)
  all.movements[, 6:13] <- lapply(all.movements[, 6:13], factorconvert)
  all.movements <- as.data.frame(all.movements) %>% dplyr::arrange(quarter,desc(game_clock),x_loc,y_loc)
  return(all.movements)
}