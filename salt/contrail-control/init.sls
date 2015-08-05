/etc/kubernetes/manifests/contrail-control.manifest:
  file.managed:
    - source: https://github.com/pedro-r-marques/contrail-kubernetes/blob/manifests/cluster/contrail-control.manifest
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
