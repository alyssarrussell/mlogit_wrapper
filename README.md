# An mlogit wrapper function that allows for mixed logit estimation with market-level variation.

*Work in progress*. 

The function is contained in mlogit_wrapper_for_ml.R. Simply copy the code into your own script to use.

Description: 

When including constants and product characteristics with random coefficients that both vary at the product-market level in the model, the model cannot be estimated due to perfect collinearity. The solution is to drop a product-market constant for each additional product characteristic with a random coefficient that is added. Consequently, the constant that is dropped will not be estimated. This causes the means of the random coefficients to be estimated with bias. The correct estimates can be obtained by adjusting the estimated product-market constants using the observed values of the product characteristics and the (biased) estimated of the means of the random coefficients, and then running a second-stage linear regression with the adjusted product-market constants on the LHS and the observed product characteristics on the RHS. The coefficient estimates on the product characteristics of the second-stage are the bias-corrected estimates of the means of the random coefficients.

Arguments:

**Data** A data frame containing micro choice data in long format with the following variables: choice (boolean, indicates the choice), id (numeric/character, decision-maker identifier), product_ids (character, values should be "product1", "product2", etc), markets_ids (character, values should be "market1", market2", etc).

**random_coefs** A character vector with the variable names of the random coefficient variables. Must be at least one variable with a random coefficient.

**rpar** An mlogit input. A vector indicating the distribution assumption of each random variable. See mlogit documentation for more information.

**delta** A character vector with the variable names of the variables that vary at the product-market level, including any variables in random_coefs that vary at the product-market level.

**demand_instruments** A character vector with the names of the instruments for price. If price is assumed exogenous, use price as the instrument. 

**demographic.vars = NULL** A character vector with the names of the demographic (decision-maker) variables. These are variables that _do not_ vary across products.

**product.char.vars = NULL** A character vector with the names of the product characteristics _without_ random coefficients. These are variables that vary across products.

**R = 100** See mlogit documentation.

**reflevel = 'product1'** See mlogit documentation.

**halton = NA** See mlogit documentation.

**seed = 1** See mlogit documentation.

There are additional mlogit arguements that can be used, such as **heterosc** and **panel**, but I have not experimented with these.

Value:

mlogit_market() returns a list of length two. The first item is the mlogit model result with biased estimates of the means of the random coefficients, but correct estimates of the standard deviation of the random coefficients and any other coefficients on product characteristics or demographic variables, if included. The second item is the second-stage regression model result with the bias-corrected estimates of the means of the random coefficients and the coefficient estimates of any other variables that vary at the product-market level, such as price.

Example:

The sample data contains the following variables:

id: consumer ids 
market_ids: market ids
choice: indicates the product choice
product_ids: product ids
z1, z2, and z3: demographic variables
x_rc: product characteristic that varies at the product-market level that we assume has a random coefficient that follows a normal distribution
prices: endogenous price variable that varies at the product-market level that we assume doesn't have a random coefficient
shares: market shares
demand_instrument0, demand_instrument1, and demand_instrument2: instruments for price

The true values for the mean of the random coefficient, the standard deviation of the random coefficient, and the price coefficient are 1, 1, and -1 respectively. The estimates should be close to these true values.

R code:

# read in sample data
data <- fread(input = "sample_data_1.csv")

# compute results
results <- mlogit_market(data,
                         random_coefs = c("x_rc"),
                         delta = c("x_rc", "prices"),
                         demand_instruments = c("demand_instruments0", "demand_instruments1", "demand_instruments2"),
                         demographic.vars = c("z1", "z2", "z3"),
                         rpar = c(x_rc = 'n'))
