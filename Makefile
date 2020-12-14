linux:
	cd registry; flutter run -d linux

macos:
	cd registry; flutter run -d macos

web:
	cd registry; flutter run -d chrome --web-hostname localhost --web-port 8888

protos:
	cd third_party; ./SETUP.sh
	./tools/COMPILE-PROTOS.sh

create:
	flutter create --no-overwrite registry
	# we're not using this (yet)
	rm -rf registry/test

clean:
	cd registry; flutter clean
	rm -rf registry/lib/generated

clobber: clean
	rm -rf registry/ios registry/android registry/ios registry/linux 
	rm -rf registry/registry.iml
	rm -rf third_party/api-common-protos third_party/gnostic third_party/registry
	rm -rf site/public

staging:
	cd registry; flutter build web
	rm -rf site/public
	cp -r registry/build/web site/public

build:  staging
ifndef REGISTRY_PROJECT_IDENTIFIER
	@echo "Error! REGISTRY_PROJECT_IDENTIFIER must be set."; exit 1
endif
	cd site; gcloud builds submit --tag gcr.io/${REGISTRY_PROJECT_IDENTIFIER}/registry-app

deploy:
ifndef REGISTRY_PROJECT_IDENTIFIER
	@echo "Error! REGISTRY_PROJECT_IDENTIFIER must be set."; exit 1
endif
	gcloud run deploy registry-app --image gcr.io/${REGISTRY_PROJECT_IDENTIFIER}/registry-app --platform managed

