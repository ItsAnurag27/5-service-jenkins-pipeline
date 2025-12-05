FROM quay.io/coreos/etcd:v3.5.10
EXPOSE 2379 2380
CMD ["etcd", "--listen-client-urls=http://0.0.0.0:2379", "--advertise-client-urls=http://127.0.0.1:2379"]
