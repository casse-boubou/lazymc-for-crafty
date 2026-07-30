ARG ALPINE_BASE_IMAGE_VERSION="3.23"
####################
# BUILD LAZYMC
####################
FROM alpine:${ALPINE_BASE_IMAGE_VERSION} AS builder
# Update index, install app
ARG LAZYMC_VERSION="v0.2.10"
RUN echo "Installing base packages" \
    && apk --update --no-cache add \
    cargo=1.91.1-r0 \
    git=2.54.0-r0
RUN wget -q --no-verbose https://github.com/timvisee/lazymc/archive/refs/tags/${LAZYMC_VERSION}.zip && \
    unzip ${LAZYMC_VERSION}.zip -q -d lazymc-${LAZYMC_VERSION} && \
    mv lazymc-${LAZYMC_VERSION}/lazymc-* lazymc
WORKDIR /lazymc
RUN cargo build --release


##################################
## LAZYMC x CRAFTY4
##################################
FROM alpine:${ALPINE_BASE_IMAGE_VERSION} AS runner
# Copy exec and dependencies
COPY --from=builder /usr/lib/libgcc_s.so.1 /usr/lib/libgcc_s.so.1
COPY --from=builder /lazymc/target/release/lazymc /usr/local/bin/lazymc
RUN mkdir -p /lazymc
COPY ./buildFiles/lazymc-template.toml ./buildFiles/start.sh /lazymc/

# Set workdir
WORKDIR /lazymc

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh


##################################
## PRODUCTION MODE
##################################
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD pgrep -f "lazymc --config" > /dev/null || exit 1
ENTRYPOINT ["sh", "/entrypoint.sh"]