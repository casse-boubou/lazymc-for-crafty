####################
# BUILD LAZYMC
####################
FROM alpine:3.23 as builder
# Update index, install app
RUN echo "Installing base packages" \
    && apk --update --no-cache add \
    cargo \
    git
ARG LAZYMC_VERSION
RUN wget --no-verbose https://github.com/timvisee/lazymc/archive/refs/tags/v${LAZYMC_VERSION}.zip && \
    unzip v${LAZYMC_VERSION}.zip && \
    mv lazymc-${LAZYMC_VERSION} lazymc && \
    cd lazymc && \
    cargo build --release


##################################
## LAZYMC x CRAFTY4
##################################
FROM alpine:3.23
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