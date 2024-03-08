# An mlogit wrapper function that allows for mixed logit estimation with market-level variation.

*Work in progress*. 

Description: When including constants and product characteristics with random coefficients that both vary at the product-market level in the model, the model cannot be estimated due to perfect collinearity. The solution is to drop a product-market constant for each additional product characteristic with a random coefficient that is added. Consequently, the constant that is dropped will not be estimated. This causes the means of the random coefficients to be estimated with bias. The correct estimates can be obtained by adjusting the estimated product-market constants using the observed values of the product characteristics and the (biased) estimated of the means of the random coefficients, and then running a second-stage linear regression with the adjusted product-market constants on the LHS and the observed product characteristics on the RHS. The coefficient estimates on the product characteristics of the second-stage are the bias-corrected estimates of the means of the random coefficients.

Arguments:

**Data** A data frame containing micro choice data in long format with the following variables: choice (boolean, indicates the choice), id (numeric/character, decision-maker identifier), product_ids (character, values should be "product1", "product2", etc), markets_ids (character, values should be "market1", market2", etc).

**random_coefs** A character vector with the variable names of the random coefficient variables. Must be at least one variable with a random coefficient.

**rpar** An mlogit input. A vector indicating the distribution assumption of each random variable. See mlogit documentation for more information.

**delta** A character vector with the variable names of the variables that vary at the product-market level, including any variables in random_coefs that vary at the product-market level.

**demand_instruments** A character vector with the names of the instruments for price. If price is assumed exogenous, use price as the instrument. 

**demographic.vars = NULL** A character vector with the names of the demographic (decision-maker) variables. These are variables that _do not_ vary across products.

**product.char.vars = NULL** A character vector with the names of the product characteristics _without_ random coefficients. These are variables that vary across products. **Can price ever be included here?**

Value:

mlogit_market() returns a list of length two. The first item is the mlogit model result with biased estimates of the means of the random coefficients, but correct estimates of the standard deviation of the random coefficients and any other coefficients on product characteristics or demographic variables, if included. The second item is the second-stage regression model result with the bias-corrected estimates of the means of the random coefficients and the coefficient estimates of any other variables that vary at the product-market level, such as price.

Examples:

upload my simulated data to github and use that as an example. make some data with different numbers of random coef vars, different distributions, demographics, number of products/markets, etc.
