CFLAGS := "-framework IOBluetooth -framework Foundation -framework CoreBluetooth"

run *ARGS:
    v -cflags "{{ CFLAGS }}" run . {{ ARGS }}

build:
    v -cflags "{{ CFLAGS }}" -prod -o vfetch .

help:
    @just --list
