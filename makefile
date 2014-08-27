

uid=$(shell id -u)
gid=$(shell id -g)

zreprepro_1.0_amd64.deb:
	docker build -t zreprepro .
	docker run -v `pwd`:/mnt zreprepro /bin/sh -c "chown $(uid):$(gid) /tmp/zreprepro_1.0_amd64.deb && cp -p /tmp/zreprepro_1.0_amd64.deb /mnt/zreprepro_1.0_amd64.deb"

