cluster restype "Majority Node Set" /create /dll:nodequorum.dll /type:"Majority Node Set"
cluster resource "MNS Quorum" /create /group:"Cluster Group" /type:"Majority Node Set"
cluster resource "MNS Quorum" /online /wait
cluster /quorum:"MNS Quorum" /path:"MSCS\"