/etc/kubernetes/manifests/contrail-rabbitmq.manifest:
  file.managed:
    - source: https://github.com/pedro-r-marques/contrail-kubernetes/blob/manifests/cluster/rabbitmq.manifest
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755