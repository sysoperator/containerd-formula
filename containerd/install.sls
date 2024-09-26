{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import containerd with context -%}
{%- from "common/vars.jinja" import
    node_roles, node_osarch
-%}
{%- if 'kube-cluster-member' in node_roles %}
  {%- from "kubernetes/vars.jinja" import
      kubernetes_version
  -%}
  {%- from "cni/vars.jinja" import
      cni_etc_dir
  -%}
{%- endif %}

include:
{%- if containerd.pkg_name == 'containerd.io' %}
  - docker.repository
{%- endif %}
  - .deps

containerd:
  pkg.installed:
    - name: {{ containerd.pkg_name }}
    - version: {{ containerd.version }}
{%- if containerd.pkg_name == 'containerd.io' %}
    - require:
      - pkgrepo: docker-repository
{%- endif %}

{%- if salt['grains.get']('os_family') == 'Debian' %}
containerd-apt-pinning:
  file.managed:
    - name: /etc/apt/preferences.d/containerd
    - contents: |
        Package: {{ containerd.pkg_name }}
        Pin: version {{ containerd.version }}
        Pin-Priority: 1001
    - require_in:
      - pkg: containerd
{%- endif %}

{%- if 'kube-cluster-member' in node_roles %}
  {%- if salt['pkg.version_cmp'](kubernetes_version, 'v1.24.0') >= 0 %}
containerd.service-restart:
  service.running:
    - name: containerd
    - require:
      - file: {{ cni_etc_dir }}/10-bridge.conf

clean-disabled_plugins:
  file.replace:
    - name: /etc/containerd/config.toml
    - pattern: '^(disabled_plugins) = \[".*"\]$'
    - repl: '\1 = []'
    - watch_in:
      - service: containerd.service-restart

/etc/containerd/config.toml:
  file.blockreplace:
    - marker_start: "# START managed section"
    - marker_end: "# END managed section"
    - append_if_not_found: True
    - show_changes: True
    - watch_in:
      - service: containerd.service-restart

/etc/containerd/config.toml-accumulated:
  file.accumulated:
    - filename: /etc/containerd/config.toml
    - name: config.toml-accumulator
    - text: |
        version = 2
        
        [plugins]
        
          [plugins."io.containerd.grpc.v1.cri"]
        
            [plugins."io.containerd.grpc.v1.cri".containerd]
        
              [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        
                [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
                  runtime_type = "io.containerd.runc.v2"
        
                  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
                    SystemdCgroup = true
    - require_in:
      - file: /etc/containerd/config.toml
  {%- endif %}
{%- endif %}
