ARG ALPINE_VERSION=3.18

FROM python:3.11-alpine${ALPINE_VERSION} as awsclibuilder
ARG AWS_CLI_VERSION=2.12.7
RUN apk add --no-cache git unzip groff build-base libffi-dev cmake
RUN git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git

WORKDIR aws-cli
RUN ./configure --with-install-type=portable-exe --with-download-deps
RUN make
RUN make install

# reduce image size: remove autocomplete and examples
RUN rm -rf \
    /usr/local/lib/aws-cli/aws_completer \
    /usr/local/lib/aws-cli/awscli/data/ac.index
RUN find /usr/local/lib/aws-cli/awscli/data -name completions-1*.json -delete
RUN find /usr/local/lib/aws-cli/awscli/botocore/data -name examples-1.json -delete
RUN (cd /usr/local/lib/aws-cli; for a in *.so*; do test -f /lib/$a && rm $a; done)


FROM alpine:${ALPINE_VERSION}
COPY --from=awsclibuilder /usr/local/lib/aws-cli/ /usr/local/lib/aws-cli/
RUN ln -s /usr/local/lib/aws-cli/aws /usr/local/bin/aws

RUN apk --no-cache add jq uuidgen

ADD bin /opt/resource
