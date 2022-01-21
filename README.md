# Compressed or not

The Dockerfile in this repo contains two targets:

- uncompressed (contains a bunch of data in `/data`)
- compressed (contains the same data, but compressed in a tarball in `/data.tar.gz`)

The compressed target has a `CMD` that uncompresses the data.

We're trying to answer the question: which image is smaller?

## Size in the Docker Engine

```
docker build . --target compressed -t localhost:5000/test:compressed
docker build . --target uncompressed -t localhost:5000/test:uncompressed
docker images localhost:5000/test
```

The compressed image seems smaller:

```
REPOSITORY            TAG            IMAGE ID       CREATED          SIZE
localhost:5000/test   uncompressed   c03f3d5ecaf3   15 minutes ago   61.1MB
localhost:5000/test   compressed     48a0bbd4d87b   15 minutes ago   39.5MB
```

## Size of the running container

```
time docker run localhost:5000/test:compressed
docker ps -ls
time docker run localhost:5000/test:uncompressed
docker ps -ls
```

The compressed container takes longer to start, and it is bigger:

```
real  0m1.388s
CONTAINER ID   IMAGE                            ...   SIZE
45b9ab3eb5f7   localhost:5000/test:compressed   ...   55.5MB (virtual 95MB)

real  0m0.630s
CONTAINER ID   IMAGE                              ...   SIZE
cbc595966209   localhost:5000/test:uncompressed   ...   0B (virtual 61.1MB)
```

This makes sense, because it has to decompress the data, and it has to store
an extra copy of the uncompressed data now.

Keep in mind that each copy of the compressed container will use 60 MB of extra disk space
(vs zero for the uncompressed one).

## Size of the image in the registry

```
docker rm -f registry
docker run --name registry -d -p 5000:5000 registry
docker push localhost:5000/test:compressed
docker push localhost:5000/test:uncompressed
docker exec registry sh -c "cd /var/lib/registry/docker/registry/v2/blobs; find . -type f | xargs du"
```

In the registry we see the following layers:


```
4 ./sha256/48/48a0bbd4d87b565b24891c51c14dace956d18f00e2eeac05fcb92ca9d4ce31f6/data
4 ./sha256/ca/ca61b3e71f67e3b7f12e0f2e8c40949a17403e187bc093d4fc430a8464f3d35c/data
2756  ./sha256/59/59bf1c3509f33515622619af21ed55bbe26d24913cedbca106468a5fb37a50c3/data
4 ./sha256/c0/c03f3d5ecaf3b9e6f4dc66f66e09395e6b8ac6774a67b4d08cc96be7cec4f17d/data
33100 ./sha256/42/425988f260d7a0ee74b1fe1766115d352325737f0b7f4ede3b033c9c25422222/data
4 ./sha256/85/85b963be4804d4521cc3f35782abb70a569b3f7346468dacfa87ae68d9a23230/data
32960 ./sha256/c9/c985b5851e2af81f447046393d317634b28da616357c3470e1edc76978a9bfae/data
```

The 2.7 MB one is the base Alpine.

The two other layers have almost the same size. I'm not sure which is which,
but given how close they are it's not even worth figuring it out 🙃
