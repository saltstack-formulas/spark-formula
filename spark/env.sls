{% from "spark/map.jinja" import spark with context %}
{% set curtime = salt['cmd.run']("date +%s") %}
{% with archive_name = "%s.%s"|format(spark.archive_name, spark.archive_type) %}
{% set artifact = '/tmp/%s'|format(archive_name) %}
{% set pub_key = '/tmp/spark-pub-keys.asc' %}

{% set pkg_deps = spark.get('package_deps', [])  %}
{% set java_deps = spark.get('java_deps', [])  %}

bootstrap-spark:
  group.present:
    - name: {{ spark.user }}
  user.present:
    - name: {{ spark.user }}
    - system: true
    - fullname: "Apache Spark user"
    - gid: {{ spark.user }}
    - system: True
  pkg.installed:
    - pkgs: {{ pkg_deps | json }}
    - require:
        - pkg: check-for-java

{{ pub_key }}:
  file.managed:
    - source:
      - salt://spark/files/spark-pub-keys.asc
      - https://www.apache.org/dist/spark/KEYS
    - skip_verify: true
    - user: root
    - mode: 0400
    - template: jinja
    - require_in:
        - module: import-apache-keys
    - require:
        - user: bootstrap-spark

check-for-java:
  pkg.installed:
    - pkgs: {{ java_deps | json }}
    - unless:
        - which java
    
import-apache-keys:
  module.run:
    - name: gpg.import_key
    - kwargs:
        user: salt
        filename: {{ pub_key }}

{{ '%s.asc'|format(artifact) }}:
  file.managed:
    - source:
        - salt://spark/files/{{ archive_name }}.asc
        - {{ spark.archive_hash_url }}
    - template: jinja
    - skip_verify: true

spark-cache-archive:
  file.managed:
    - name: {{ artifact }}
    - source:
        - salt://spark/files/{{ archive_name }}
        - {{ spark.archive_url }}
    - skip_verify: true
    - require:
      - file: {{ '%s.asc'|format(artifact) }}      
    - unless:
        - test -f {{ artifact }}

check-spark-signatures:
  file.directory:
    - name: /etc/salt/pki
    - mode: '0700'
    - user: root
  cmd.run:
    - name: |
        gpg --homedir=/etc/salt/pki --import {{ pub_key }}
        gpg --homedir=/etc/salt/pki --verify {{ '%s.asc'|format(artifact) }} {{ artifact }}
    - runas: root
    - require:
        - file: check-spark-signatures
        - file: spark-cache-archive
          
spark-extract-archive:
  file.directory:
    - names:
        - {{ spark.log_dir }}
        - {{ spark.work_dir }}
        - {{ spark.pid_dir }}
    - user: {{ spark.user }}
    - group: {{ spark.user }}
    - mode: 755
    - makedirs: true
      
  archive.extracted:
    - name: {{ spark.prefix }}
    - source:
        - file://{{ artifact }}
        - salt://{{ archive_name }}
        - {{ spark.archive_url }}
    - trim_output: true
    - if_missing: {{ spark.real_root }}
    - archive_format: tar
    - require:
        - cmd: check-spark-signatures

spark-setup-config:
  file.directory:
    - name: {{ spark.config_dir }}
    - user: {{ spark.user }}
    - group: {{ spark.user }}
    - mode: 775
    - onlyif:
        - ! test -d {{ spark.config_dir }}
    - require:
        - archive: spark-extract-archive
        - alternatives: spark-update-path

spark-update-path:
  alternatives.install:
    - name: spark-home-link
    - link: {{ spark.alt_root }}
    - path: {{ spark.real_root }}
    - priority: {{ curtime }}
    - require:
        - archive: spark-extract-archive

spark-setup-profile:
  file.managed:
    - name: /etc/profile.d/spark.sh
    - source: salt://spark/files/profile.sh
    - template: jinja
    - user: root
    - group: root
    - mode: 644

spark-env:
  file.managed:
    - name: {{ spark.config_dir }}/spark-env.sh
    - source:
        - salt://spark/files/spark-env_sh.jinja
        # fallback to the default (empty) from the distribution
        - file://{{ spark.real_root }}/conf/spark-env.sh.template
    - template: jinja
    - user: {{ spark.user }}
    - group: {{ spark.user }}
    - mode: 755
    - require:
        - file: spark-setup-config
    - context:
        is_worker: true

spark-logging:
  file.managed:
    - name: {{ spark.config_dir }}/log4j.properties
    - source:
        - salt://spark/files/log4j-properties.jinja
        - file://{{ spark.real_root }}/conf/log4j.properties.template
    - template: jinja
    - user: {{ spark.user }}
    - group: {{ spark.user }}
    - mode: 644
    - require:
        - file: spark-setup-config

spark-defaults:
  file.managed:
    - name: {{ "%s/spark-defaults.conf"|format(spark.config_dir) }}
    - template: jinja
    - user: {{ spark.user }}
    - group: {{ spark.user }}
    - mode: 644
    - force: true
    - replace: true
    - require:
        - file: spark-setup-config
          
    - source:
        - salt://spark/files/spark-defaults.conf.jinja
        - salt://spark/files/spark-defaults.conf.template
        - {{ spark.real_root }}/conf/spark-defaults.conf.template

{% endwith %}
