#!/bin/bash

cat $1  | sed 's^CONFIG_^^' | sed 's^=y^ = lib.mkForce yes;^' | sed 's^is not set^= lib.mkForce no;^' | sed 's^=m^= lib.mkForce no;^' | sed 's^# ^^' | sed '/mkForce/!d'

