# A function that takes all of the same arguments as mlogit plus additional arguments
# for estimation by maximum likelihood of mixed logit models with markets

library(mlogit)
library(NLP)
library(data.table)
library(tidyverse)
library(AER)

# formula for package
mlogit_market <- function(data, # must have variables choice, id, product_ids, market_ids, product_ids in long format
                          random_coefs, # variables with random coefficients
                          rpar, # distribution assumption of the random coefficients
                          delta, # variables that vary at product-market level
                          demand_instruments, # if price is assumed exogenous, then put prices
                          demographic.vars = NULL, # demographic variables, default NULL
                          product.char.vars = NULL, # the ones without random coefficients, default NULL
                          R = 100,
                          reflevel = 'product1',
                          halton = NA,
                          seed = 1){

  # change column order
  setcolorder(data, c("id", "product_ids", "choice"))
  
  # create market 1 dummies
  num_products <- length(unique(data$product_ids))
  market1_ids <- 0
  iter <- 0
  num_mkt_dummies <- num_products - length(random_coefs)
  if(num_mkt_dummies > 1){
    for(i in 2:num_mkt_dummies){
      iter <- iter + 1
      new_col_name <- market1_ids[iter] <- paste0("market_idsmarket1_product", i)
      suppressWarnings({
        data[, (new_col_name) := ifelse(market_ids == 'market1' & product_ids == paste0("product", i), 1, 0)]
      })
    }
  } else {
    market1_ids <- NULL
  }
  
  # data for estimating
  data <- data.frame(data)
  data_dfidx <- dfidx(data, choice = "choice", shape = "long", chid.var = "id", alt.var = "product_ids")
  
  # mlogit formula
  formula <- as.formula(paste("choice~", paste(random_coefs, collapse = '+'), "+", paste(product.char.vars, collapse = '+'),
                              "+", paste(market1_ids, collapse = "+"),
                              "| 0 + market_ids", ifelse(is.null(demographic.vars), "", paste("+", paste(demographic.vars, collapse = "+")))))

  # mlogit model
  m <- mlogit(formula = formula,
              data = data_dfidx,
              reflevel = reflevel,
              rpar = rpar,
              R = R,
              halton = halton,
              seed = seed)

  # estimated coefficients
  est_coefs <- data.frame(t(coef(m))) %>% select(!(starts_with('X.Intercept') | starts_with('market')))

  # variables in the delta regressions that have random coefficients that need adjusting
  delta_rc <- random_coefs[random_coefs %in% delta]

  # estimated market fixed effects
  est_delta <- data.frame(t(data.frame(t(coef(m))) %>% select(starts_with('X.Intercept') | starts_with('market'))))
  colnames(est_delta) <- "est_delta"
  est_delta <- data.table(rownames_to_column(est_delta, var = "market_alt"))
  est_delta[, market_alt := sub("^X\\.Intercept\\.", "market1", market_alt)]
  est_delta[, product_ids := substring(market_alt, nchar(market_alt) - 7, nchar(market_alt))]
  est_delta[, market_ids := substring(market_alt, 11, nchar(market_alt) - nchar(product_ids) - 1)]
  est_delta[, market_alt := NULL]

  # get random coefficients, price, any variables that vary at the product-market level
  delta_vars <- data %>% select(all_of(delta), "product_ids", "market_ids", any_of(demand_instruments)) %>% distinct()

  # merge with estimates
  est_delta <- full_join(est_delta,
                         delta_vars,
                         by = c("market_ids", "product_ids"))
  est_delta[, est_delta := ifelse(is.na(est_delta), 0, est_delta)]

  # normalize the random coefficients
  norm_names <- 0
  iter <- 0
  for(var in delta_rc){
    iter <- iter + 1
    new_col_name <- paste0(var, "_norm")
    suppressWarnings({
      est_delta[, (new_col_name) := as.numeric(get(var) - get(var)[product_ids == 'product1']), by = market_ids]
    })
    norm_names[iter] <- new_col_name
    random_coefs_norm <- est_delta[, ..norm_names]
  }

  # adjust market FE for omitted dummy
  delta_adjustments <- as.numeric(est_coefs %>% select(all_of(delta_rc)))
  random_coefs_adjusted <- t(data.frame(t(random_coefs_norm) * delta_adjustments))
  rownames(random_coefs_adjusted) <- NULL
  colnames(random_coefs_adjusted) <- paste0(norm_names, "_adjusted")
  est_delta[, adjustment := rowSums(random_coefs_adjusted)]
  est_delta[, `:=`(est_delta_adjust = est_delta + adjustment), by = 'market_ids']

  # delta regressions
  delta_formula <- as.formula(paste("est_delta_adjust ~ 0 +", paste(delta, collapse = "+"), "+ market_ids | ",
                              paste(delta[!(delta == "prices")]), "+", paste(demand_instruments, collapse = "+"), "+ market_ids"))
  m_delta <- ivreg(delta_formula, data = est_delta)

  return(list(m, m_delta))
}

# Example 1 ----

data <- fread(input = "sample_data_1.csv")

results <- mlogit_market(data,
                         random_coefs = c("x_rc"),
                         delta = c("x_rc", "prices"),
                         demand_instruments = c("demand_instruments0", "demand_instruments1", "demand_instruments2"),
                         demographic.vars = c("z1", "z2", "z3"),
                         rpar = c(x_rc = 'n'))

results

# Example 2 ----

data <- fread(input = "sample_data_2.csv")
data$prices <- -data$prices
data$x_rc <- -data$x_rc

test <- mlogit_market(data, # must have variables choice, id, product_ids, market_ids
              random_coefs = c("x_rc", "prices"), # variables with random coefficients
              delta = c("x_rc", "prices"), # variables that vary at product-market level
              demand_instruments = c("demand_instruments0", "demand_instruments1", "demand_instruments2"), # if price is assumed exogenous, then put prices
              demographic.vars = c("z1", "z2", "z3"), # demographic variables, default NULL
              rpar = c(x_rc = 'n', prices = 'ln'))

summary(test[[1]])
summary(test[[2]])





