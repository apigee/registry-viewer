
linux:
	cd registry; flutter run -d linux

web:
	cd registry; flutter run -d web --web-hostname localhost --web-port 8888

protos:
	./tools/COMPILE-PROTOS.sh

create:
	flutter create registry

clean:
	cd registry; flutter clean
	rm -rf registry/lib/generated

clobber: clean
	rm -rf registry/ios registry/android registry/ios registry/linux registry/web 
	rm -rf registry/registry.iml
	rm -rf third_party/api-common-protos third_party/gnostic third_party/registry

	
