FROM google/cloud-sdk:594.0.0-alpine@sha256:045a1cc1f530e36899ef7530d50aab46159d7602ba2b405a76e38ec9f9acda48

COPY LICENSE README.md /

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["info"]
