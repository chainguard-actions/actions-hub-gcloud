FROM google/cloud-sdk:593.0.0-alpine

COPY LICENSE README.md /

RUN command -v bash >/dev/null 2>&1 || apk add --no-cache bash

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["info"]
