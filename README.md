# validatorbase
validatorbase provides a lightweight validation middleware for express.

## features
* the user simply provides a rudimentary schema defining which parameters are expected for each call as well as a map that defines which function shall be used to check a parameter with a given name
* all the validation is performed without your actual APIs noticing as long as you watch the naming of your parameters
* especially for simpler systems it thus provides a much more lightweight solution than more complex frameworks like express-validator
* hook your custom logging framework to keep track of incoming http requests and occuring validation errors
* validatorbase runs in a production environment and is thus constantly tested for stability

## get started

Have a look at the test case to understand how to use validatorbase.

## notes

Currently still under heavy development.
