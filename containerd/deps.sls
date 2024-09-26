{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import containerd with context -%}
{%- from "common/vars.jinja" import
    node_roles, node_osarch
-%}
{%- if 'kube-cluster-member' in node_roles %}
  {%- from "kubernetes/vars.jinja" import
      kubernetes_version
  -%}
{%- endif %}

{%- if 'kube-cluster-member' in node_roles %}
include:
  - crictl.install
  {%- if salt['pkg.version_cmp'](kubernetes_version, 'v1.24.0') >= 0 %}
  - cni
  {%- endif %}
{%- endif %}
