FROM alpine AS data
RUN apk add git
WORKDIR /data
RUN git clone https://github.com/containers/skopeo/
RUN tar c -z -f /data.tar.gz /data

FROM alpine AS compressed
COPY --from=data /data.tar.gz .
CMD tar x -z -f data.tar.gz

FROM alpine AS uncompressed
COPY --from=data /data /data
