

## Enabling privileged capabilities for our OpenVPN server

First, SSH into the CDK:

    vagrant ssh

Then, modify the security policies to allow creating privileged
containers for our user:

    oc login 10.1.2.2:8443 -u admin -p admin
    oadm policy add-scc-to-user privileged openshift-dev
    # TODO: Why is the serviceaccount required too?
    oadm policy add-scc-to-user privileged system:serviceaccount:helloworld-msa:default

Finally, log back out of the CDK:

    exit


Now create our OpenVPN server:

    # TODO: git repo or something
    cd ~/src/openshift-openvpn
    oc new-build --binary --name=openvpn-server
    oc start-build openvpn-server --from-dir=. --follow
    # TODO: We really just need a deploymentconfig, not a service here
    oc new-app openvpn-server
    # TODO: not needed if I provide a .yaml or .json to create this vs Dockerfile
    oc patch dc openvpn-server -p '{"spec":{"template":{"spec":{"containers":[{"name":"openvpn-server","securityContext":{"privileged": true}}]}}}}'


Connect your OpenVPN client to the OpenVPN server:

    oc port-forward `oc get ep/openvpn-server -o jsonpath='{.subsets[0].addresses[0].targetRef.name}'` 1194
    # Actually, use NetworkManager so DNS works
    sudo openvpn --client --remote localhost --dev tun --ca easy-rsa/keys/ca.crt --verb 3 --proto tcp-client --auth-user-pass


Redirect a service's traffic into our local proxy

    oc export svc/frontend -o json > frontend-backup.json
    oc patch svc/frontend -p '{"spec": {"selector": {"$patch": "replace", "app": "openvpn-server"}}}'


Switch from the proxy back to the real service

    oc replace --force -f svc_backup.json
