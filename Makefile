
.PHONY: build-img
build-img:
	docker build . -f deployment/Dockerfile -t frontend --load

.PHONY: upload-img
upload-img:
	docker tag frontend:latest cr.yandex/crpkimlhn85fg9vjfj7l/frontend:latest
	docker image push cr.yandex/crpkimlhn85fg9vjfj7l/frontend:latest
