
app:
	cd ..; flutter build web
	rm -rf public
	cp -r ../build/web public

build:  app
ifndef REGISTRY_PROJECT_IDENTIFIER
	@echo "Error! REGISTRY_PROJECT_IDENTIFIER must be set."; exit 1
endif
	gcloud builds submit --tag gcr.io/${REGISTRY_PROJECT_IDENTIFIER}/registry-app

deploy:
ifndef REGISTRY_PROJECT_IDENTIFIER
	@echo "Error! REGISTRY_PROJECT_IDENTIFIER must be set."; exit 1
endif
	gcloud run deploy registry-app --image gcr.io/${REGISTRY_PROJECT_IDENTIFIER}/registry-app --platform managed

