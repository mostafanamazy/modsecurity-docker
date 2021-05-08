# modsecurity-docker
a docker file for build modsecurity with nginx.

## Build
$ make build

## Run
$ make run

## Verify
Verify that [this rule](conf/main.conf#L4) works correctly, by making a request that includes the string test in the value of the query string testparam parameter:  
$ curl -D - http://localhost/foo?testparam=thisisatestofmodsecurity  
The request returns status code 403, confirming that the WAF is enabled and executing the rule.  

