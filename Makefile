linux-run:	buildstamp
		cd viewer; flutter run -d linux

linux: 		buildstamp
	     	cd viewer; flutter build linux

macos-run:	buildstamp
		cd viewer; flutter run -d macos

macos:		buildstamp
		cd viewer; flutter build macos

web-run:	buildstamp
		cd viewer; flutter run -d chrome --web-hostname localhost --web-port 8888

web:		buildstamp
		cd viewer; flutter build web

buildstamp:
	tools/BUILDSTAMP.sh

protos:
	cd third_party; ./SETUP.sh
	flutter pub global activate protoc_plugin 
	./tools/COMPILE-PROTOS.sh

create:
	flutter create --no-overwrite viewer
	# we're not using these (yet)
	rm -rf viewer/test viewer/integration_test

clean:
	cd viewer; flutter clean
	rm -rf registry/lib/src/generated

clobber:	clean
	rm -rf viewer/ios viewer/android viewer/ios viewer/linux 
	rm -rf viewer/viewer.iml
	rm -rf third_party/api-common-protos third_party/gnostic third_party/registry
	rm -rf site/public

staging:	buildstamp
	cd viewer; flutter build web
	rm -rf site/public
	cp -r viewer/build/web site/public

build: 	staging
ifndef REGISTRY_PROJECT_IDENTIFIER
	@echo "Error! REGISTRY_PROJECT_IDENTIFIER must be set."; exit 1
endif
	gcloud builds submit --tag gcr.io/${REGISTRY_PROJECT_IDENTIFIER}/registry-app

deploy:
ifndef REGISTRY_PROJECT_IDENTIFIER
	@echo "Error! REGISTRY_PROJECT_IDENTIFIER must be set."; exit 1
endif
	gcloud run deploy registry-app --image gcr.io/${REGISTRY_PROJECT_IDENTIFIER}/registry-app --platform managed

