# Build image
FROM swift:4.2 as builder
RUN apt-get -qq update && apt-get -q -y install \
  tzdata \
  libcurl4-openssl-dev \
  && rm -r /var/lib/apt/lists/*
WORKDIR /app
COPY . .
RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*.so /build/lib
RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin

# Production image
FROM ubuntu:16.04
RUN apt-get -qq update && apt-get install -y \
  libicu55 libxml2 libbsd0 libcurl3 libatomic1 \
  tzdata \
  libcurl4-openssl-dev \
  && rm -r /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /build/bin/Run .
COPY --from=builder /build/lib/* /usr/lib/
COPY --from=builder /app/Resources/Views/* /app/Resources/Views/
COPY --from=builder /app/Public/images/* /app/Public/images/
COPY --from=builder /app/Public/styles/* /app/Public/styles/
COPY --from=builder /app/Public/styles/icons* /app/Public/styles/icons
COPY --from=builder /app/Public/scripts/* /app/Public/scripts/
EXPOSE 80
ENTRYPOINT ./Run serve -e prod -b 0.0.0.0:80