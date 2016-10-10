This folder contains batch files that show the power of scripting and using the command line cluster.exe.

createcluster.bat creates your Windows server cluster. It takes the following parameters:
%1 - this is the name of the cluster
%2 - this is the IP address for the cluster
%3 - this is the domain account used for the cluster service account
%4 - this is the password for the cluster service account
%5 - this is the name of the node you are adding as the first node

Here is an example execution:
createcluster.bat "MyNewCluster" "1.1.1.1" "DOMAIN\clusteracct" "password" "NodeName"

Once you create the cluster, you can add nodes to it with the addnode.bat script. It also takes parameters.
%1 - this is the name of the Windows server cluster you just created
%2 - this is the node or list of nodes (separated by commas) that you are adding to the server cluster
%3 - this is the password for the service account

Here is an example execution:
addnode.bat "MyNewCluster" "Node1,Node2" "password"

The script createclusterdtc.bat is an example of how to create a clustered MS DTC resource and not use Cluster Administrator.

converttomns.bat is a script that will convert your quorum from a standard disk-based server cluster to a Majority Node Set server cluster.