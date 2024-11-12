VAData <- get_acs(geography = "tract", 
                        year = 2017,
                        variables = c(median.age       =  "B01002_001", #median age of people
                                      house.age        = "B25035_001",  #median house age
                                      month.expenses   = "B25105_001"), #median monthly house expenditures

                        state = c("VA"),
                        survey = "acs5",
                        geometry = TRUE,
                        output="wide")

#
# Choose all the places in Illinois
pl           <- places(state = "VA", cb = TRUE, year=2017)

# and find the ones called Chicago
Richmond.VA <- filter(pl, NAME == "Richmond")
library(rmapshaper)

Richmond_ACS <- ms_clip(target = VAData, 
                             clip = Richmond.VA, 
                             remove_slivers = TRUE)

Richmond_ACS$NAME <- str_replace_all(Richmond_ACS$NAME,"Census ","")
Richmond_ACS$NAME <- str_replace_all(Richmond_ACS$NAME,", Richmond city, Virginia","")

Richmond_ACS <- Richmond_ACS %>% 
  dplyr::select(
    GEOID, NAME, median.ageE, 
    house.ageE, month.expensesE) %>%
  dplyr::rename(
    med.age = median.ageE,
    month.expenses = month.expensesE,
    house.age = house.ageE)

empty_polygons <- st_is_empty(Richmond_ACS)
Richmond_ACS <- Richmond_ACS[which(empty_polygons==FALSE), ] 

tm_shape(Richmond_ACS) +                      
  tm_polygons(col="house.age",    
              style="pretty", legend.hist = TRUE,  
              palette="Reds")   +
  tm_layout(main.title = "Population per county PA",  
            main.title.size = 0.75, frame = FALSE) +
  tm_layout(legend.outside = TRUE) 

st_write(Richmond_ACS,"Richmond_ACS.gpkg")

Richmond_ACS <- st_read("Richmond_ACS.gpkg")

QueenNeighbours <- poly2nb(Richmond_ACS, queen=TRUE)
QueenWeights <- nb2listw(QueenNeighbours, 
                         style="W", zero.policy=TRUE)

QueenWeights

## and calculate the Moran's plot
moran.plot(Richmond_ACS$med.age, 
           listw= QueenWeights,
           zero.policy = T)


LISA_Output <- localmoran_perm(Richmond_ACS$med.age, QueenWeights, nsim = 999)
Richmond_ACS$LISA_pvalue <- as.data.frame(LISA_Output)$`Pr(folded) Sim`
