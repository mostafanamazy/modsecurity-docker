.PHONY: build run stop
build:
	docker build -t modsec .
run:
	docker run --rm --name modsec -p 80:80 -p 8085:8085 -d modsec
stop:
	docker stop modsec
