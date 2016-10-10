cluster /cluster:NUSRVCLU resource "DTC IP Address" /create /group:"MS DTC" /type:"IP Address"
cluster /cluster:NUSRVCLU resource "DTC IP Address" /priv Address=172.22.10.154
cluster /cluster:NUSRVCLU resource "DTC IP Address" /priv SubnetMask=255.255.0.0
cluster /cluster:NUSRVCLU resource "DTC IP Address" /priv Network="Public Network"
cluster /cluster:NUSRVCLU resource "DTC IP Address" /online /wait
cluster /cluster:NUSRVCLU resource "DTC Network Name" /create /group:"MS DTC" /type:"Network Name"
cluster /cluster:NUSRVCLU resource "DTC Network Name" /priv Name=MSDTC
cluster /cluster:NUSRVCLU resource "DTC Network Name" /adddependency:"DTC IP Address"
cluster /cluster:NUSRVCLU resource "DTC Network Name" /online /wait
cluster /cluster:NUSRVCLU resource "DTC" /create /group:"MS DTC" /type:"Distributed Transaction Coordinator"
cluster /cluster:NUSRVCLU resource "DTC" /adddependency:"DTC Network Name"
cluster /cluster:NUSRVCLU resource "DTC" /adddependency:"Disk G:"
cluster /cluster:NUSRVCLU resource "DTC" /online /wait
