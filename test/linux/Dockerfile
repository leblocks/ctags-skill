FROM alpine:3.21

RUN apk add --no-cache bash ripgrep jq bats dos2unix

WORKDIR /app
COPY scripts/ scripts/
COPY test/dotnet-reference-source-tags test/dotnet-reference-source-tags
COPY test/linux/lookup.bats test/linux/lookup.bats

RUN dos2unix scripts/lookup.sh scripts/parse-ctags.jq && chmod +x scripts/lookup.sh

ENTRYPOINT ["bats", "test/linux/lookup.bats"]
