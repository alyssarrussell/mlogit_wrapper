# An mlogit wrapper function that allows for mixed logit estimation with market-level variation.

Description:

Explain the issue that occurs with mlogit and how I fix it.

Arguments:

**Data** A data frame containing micro choice data in long format with the following variables: choice (boolean, indicates the choice), id (numeric/character, decision-maker identifier), product_ids (character, values should be "product1", "product2", etc), markets_ids (character, values should be "market1", market2", etc).

**random_coefs** A character vector with the variable names of the random coefficient variables. Must be at least one variable with a random coefficient.

**rpar** An mlogit input. A vector indicating the distribution assumption of each random variable. See mlogit documentation for more information.

**delta** A character vector with the variable names of the variables that vary at the product-market level, including any variables in random_coefs that vary at the product-market level.

**demand_instruments** A character vector with the names of the instruments for price. If price is assumed exogenous, use price as the instrument. 

**demographic.vars = NULL** A character vector with the names of the demographic (decision-maker) variables. These are variables that _do not_ vary across products.

**product.char.vars = NULL** A character vector with the names of the product characteristics _without_ random coefficients. These are variables that vary across products. **Can price ever be included here?**

Value:

mlogit_market() returns a list of length two. The first item is the mlogit model result with biased estimates of the means of the random coefficients. The second item is the second-stage delta regression model result with the bias-corrected estimates of the means of the random coefficients and the coefficient estimates of any other variables contained in **delta**, such as price.

Examples:

upload my simulated data to github and use that as an example. make some data with different numbers of random coef vars, different distributions, demographics, number of products/markets, etc.
